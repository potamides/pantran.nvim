local config = require("perapera.config")
local utable = require("perapera.utils.table")
local async = require("perapera.async")

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
  setmetatable(engines, utable.pop(engines, "_mt"))
)

-- do error handling here
local function error_wrap(engine)
  return setmetatable({}, {__index = function(_, key)
    local val = engine[key]
    if type(val) == "function" then
      return function(...)
        local res = {pcall(val, ...)}
        if res[1] then -- ok
          return select(2, unpack(res))
        end
        vim.notify(res[2], vim.log.levels.ERROR)
        -- break coroutine when an error occurs
        async.interrupt()
      end
    else
      return val
    end
  end})
end

getmetatable(engines).__index.default = error_wrap(engines[engines.config.default_engine])
for name, engine in pairs(engines) do
  if not pcall(engine.setup) then
    -- when engine isn't properly configured (e.g. no mandatory API key set)
    -- remove it from the list
    engines[name] = nil
  else
    engines[name] = error_wrap(engine)
  end
end

return engines
