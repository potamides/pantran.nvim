local config = require("perapera.config")
local utils = require("perapera.utils")

local engines = {
  argos = require("perapera.engines.argos"),
  deepl = require("perapera.engines.deepl"),
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
  setmetatable(engines, utils.pop(engines, "_mt"))
)
getmetatable(engines).__index.default = engines[engines.config.default_engine]

for _, engine in pairs(engines) do
  engine.setup()
end

return engines
