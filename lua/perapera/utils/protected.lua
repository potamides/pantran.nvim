local async = require("perapera.async")

local protected = {}

-- Call functions of an object in protected mode and handle error-reporting. If
-- the function call succeeds, all results of the function are returned.
-- Otherwise, an error message is printed and nothing is returned. When the
-- error happens in a coroutine, the coroutine is interrupted.
function protected.wrap(object)
  return setmetatable({}, {__index = function(_, key)
    local val = object[key]
    if type(val) == "function" then
      return function(...) return protected.call(val, ...) end
    else
      return val
    end
  end})
end

function protected.call(func, ...)
  local res = {pcall(func, ...)}
  if res[1] then -- ok
    return select(2, unpack(res))
  end
  vim.notify(res[2], vim.log.levels.ERROR)
  -- break a running coroutine when an error occurs
  if coroutine.running() then
    async.interrupt()
  end
end

return protected
