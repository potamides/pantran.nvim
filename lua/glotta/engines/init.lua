local config = require("glotta.config")
local utable = require("glotta.utils.table")

local engines = {
  apertium = require("glotta.engines.apertium"),
  argos  = require("glotta.engines.argos"),
  deepl  = require("glotta.engines.deepl"),
  yandex = require("glotta.engines.yandex"),
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
