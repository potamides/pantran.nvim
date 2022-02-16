--[[
Turn callback pattern to coroutine pattern, based on
https://luyuhuang.tech/2020/09/13/callback-to-coroutine.html
--]]

local async = {}

-- Suspend a callback-style function (i.e. yield a coroutine and resume it in
-- its callback). Useful to use callback pattern instead of coroutine pattern.
function async.suspend(func, ...)
  local args = {...}
  return coroutine.yield(function(callback)
    func(unpack(vim.list_extend(args, {callback})))
  end)
end

-- Run an async function (i.e. a function which contains a wrapped
-- callback-style function somewhere in its call stack).
function async.run(f, ...)
  local co, exec = coroutine.create(f)
  exec = vim.schedule_wrap(function(...)
    local ok, data = coroutine.resume(co, ...)
    if not ok then
      error(debug.traceback(co, data))
    end
    if coroutine.status(co) ~= "dead" then
      data(exec)
    end
  end)
  exec(...)
end

function async.wrap(f, ...)
  local args = {...}
  return function(...)
    async.run(f, unpack(vim.list_extend(vim.list_slice(args), {...})))
  end
end

return async
