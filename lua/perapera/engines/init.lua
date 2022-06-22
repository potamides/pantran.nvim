local config = require("perapera.config")
local utable = require("perapera.utils.table")

local engines = {
  apertium = require("perapera.engines.apertium"),
  argos  = require("perapera.engines.argos"),
  deepl  = require("perapera.engines.deepl"),
  yandex = require("perapera.engines.yandex"),
  _mt = {
    __index = {
      -- set config in metatable to hide it when iterating engines in main table
      config = {
        default_engine = "argos"
      }
    }
  }
}

config.apply(
  config.user.engines,
  setmetatable(engines, utable.pop(engines, "_mt"))
)

getmetatable(engines).__index.default = engines[engines.config.default_engine]
for name, engine in pairs(engines) do
  if not pcall(engine.setup) then
    -- when engine isn't properly configured (e.g. no mandatory API key set)
    -- remove it from the list
    engines[name] = nil
  end
end

return engines
