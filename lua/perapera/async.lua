--[[
Turn callback pattern to coroutine pattern, based on
https://luyuhuang.tech/2020/09/13/callback-to-coroutine.html
--]]

local async = {}

-- wrap a callback-style function for use with coroutines
function async.wrap(func, ...)
  local args = {...}
  return coroutine.yield(function(callback)
    func(unpack(vim.list_extend(args, {callback})))
  end)
end

-- run an async function (i.e. a function which contains a wrapped
-- callback-style function somewhere in its call stack)
function async.run(f, ...)
  local co = coroutine.create(f)
  local function exec(...)
    local ok, data = coroutine.resume(co, ...)
    if not ok then
      error(debug.traceback(co, data))
    end
    if coroutine.status(co) ~= "dead" then
      data(vim.schedule_wrap(exec))
    end
  end
  exec(...)
end

return async
