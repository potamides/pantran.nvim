--[[
Turn callback pattern to coroutine pattern, based on
https://luyuhuang.tech/2020/09/13/callback-to-coroutine.html
--]]

local utable = require("perapera.utils.table")

local async = {
  mutex = {
    _owned = utable.defaulttable({}, true)
  }
}

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
  exec = vim.schedule_wrap(function(continue, ...)
    if continue then
      local ok, data = coroutine.resume(co, ...)
      if not ok then
        error(debug.traceback(co, data))
      end
      if type(data) == "table" then -- the data is a mutex
        data:push(function() exec(true) end)
      elseif coroutine.status(co) ~= "dead" then
        data(exec)
      end
    else
      vim.notify(..., vim.log.levels.ERROR)
      async.mutex.unlock_all(co)
    end
  end)
  exec(true, ...)
end

function async.wrap(f, ...)
  local args = {...}
  return function(...)
    async.run(f, unpack(vim.list_extend(vim.list_slice(args), {...})))
  end
end

function async.mutex:push(func)
  table.insert(self._resume, func)
end

function async.mutex:lock()
  if self.active then
    coroutine.yield(self)
  else
    self.active = true
  end
  self._owner = coroutine.running()
  table.insert(async.mutex._owned[self._owner], 1, self)
end

-- mutexes must be released in reverse order they were acquired
function async.mutex:unlock()
  table.remove(async.mutex._owned[self._owner], 1)
  self._owner = nil

  if #self._resume > 0 then
    table.remove(self._resume, 1)()
  else
    self.active = false
  end
end

function async.mutex.unlock_all(co)
  for _, mutex in ipairs(vim.list_slice(async.mutex._owned[co])) do
    mutex:unlock()
  end
end

function async.mutex.new()
  return setmetatable({
      active = false,
      _resume = {}
    }, {__index = async.mutex})
end

return async
