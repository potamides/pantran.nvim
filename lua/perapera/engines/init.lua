local config = require("perapera.config")
local utable = require("perapera.utils.table")

local engines = {
  argos = require("perapera.engines.argos"),
  deepl = require("perapera.engines.deepl"),
  _mt = {
  __index = {
    -- set config in metatable to hide it when iterating engines in main table
    config = {
      default_engine = "deepl"
    }
  }
}
}

config.apply(
  config.user.engines,
  setmetatable(engines, utable.pop(engines, "_mt"))
)
getmetatable(engines).__index.default = engines[engines.config.default_engine]

for _, engine in pairs(engines) do
  engine.setup()
end

return engines
