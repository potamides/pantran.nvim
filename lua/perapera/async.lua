--[[
Turn callback pattern to coroutine pattern, based on
https://luyuhuang.tech/2020/09/13/callback-to-coroutine.html
--]]

local async = {_fifo = {}}

-- Suspend a callback-style function (i.e. yield a coroutine and resume it in
-- its callback). Useful to use callback pattern instead of coroutine pattern.
function async.suspend(func, ...)
  local args = {...}
  return coroutine.yield(function(callback)
    func(unpack(vim.list_extend(args, {callback})))
  end)
end

local function callback_create(f)
  local co, exec = coroutine.create(f)

  exec = vim.schedule_wrap(function(...)
    local ok, data = coroutine.resume(co, ...)
    if not ok then
      error(debug.traceback(co, data))
    end
    if coroutine.status(co) ~= "dead" then
        data(exec)
    elseif async._fifo[f] then
      if #async._fifo[f] > 0 then
        table.remove(async._fifo[f], 1)()
      else
        async._fifo[f] = nil
      end
    end
  end)

  return exec
end

-- Run an async function (i.e. a function which contains a wrapped
-- callback-style function somewhere in its call stack).
function async.run(f, ...)
  callback_create(f)(...)
end

function async.serial_run(f, ...)
  local exec, args = callback_create(f), {...}
  if async._fifo[f] then
    table.insert(async._fifo[f], function() exec(unpack(args)) end)
  else
    async._fifo[f] = {}
    exec(...)
  end
end

function async.wrap(f, ...)
  local args = {...}
  return function(...)
    async.run(f, unpack(vim.list_extend(vim.list_slice(args), {...})))
  end
end

function async.serial_wrap(f, ...)
  local args = {...}
  return function(...)
    async.serial_run(f, unpack(vim.list_extend(vim.list_slice(args), {...})))
  end
end

return async
