local config = require("pantran.config")

local engines = setmetatable({
  apertium = require("pantran.engines.apertium"),
  argos  = require("pantran.engines.argos"),
  deepl  = require("pantran.engines.deepl"),
  google  = require("pantran.engines.google"),
  yandex = require("pantran.engines.yandex"),
}, {
  __index = {
    -- set config in metatable to hide it when iterating engines in main table
    config = {
      default_engine = rawget(config.user, "default_engine") or "argos"
    }
  }
})

getmetatable(engines).__index.default = engines[engines.config.default_engine]
for name, engine in pairs(engines) do
  if not pcall(engine.setup) then
    -- when engine isn't properly configured (e.g. no mandatory API key set)
    -- remove it from the list
    engines[name] = nil
  end
end

return engines
