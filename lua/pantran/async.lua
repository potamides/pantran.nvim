--[[
Turn callback pattern to coroutine pattern, based on
https://luyuhuang.tech/2020/09/13/callback-to-coroutine.html
--]]

local utable = require("pantran.utils.table")

local async = {
  -- to signal interruption of a coroutine we need a unique
  -- identifier, which in this case is a table.
  INTERRUPT = {},
  -- Mutexes for synchronization between async calls. We need this, as
  -- callbacks could continue coroutines in any order.
  mutex = {
    _owned = utable.defaulttable({}, true)
  }
}

-- Suspend a callback-style function (i.e. yield a coroutine and resume it in
-- its callback). Useful to use callback pattern instead of coroutine pattern.
function async.suspend(func, ...)
  local args = utable.pack(...)
  return coroutine.yield(function(callback)
    func(utable.unpack(utable.append(args, callback)))
  end)
end

-- Run an async function (i.e. a function which contains a wrapped
-- callback-style function somewhere in its call stack).
function async.run(f, ...)
  local co, exec = coroutine.create(f)
  exec = vim.schedule_wrap(function(...)
    local ok, data = coroutine.resume(co, ...)
    if not ok then
      async.mutex.unlock_all(co)
      error(debug.traceback(co, data))
    elseif data == async.INTERRUPT then
      async.mutex.unlock_all(co)
    elseif type(data) == "table" then -- the data is a mutex
      data:push(exec)
    elseif coroutine.status(co) ~= "dead" then
      data(exec)
    end
  end)
  exec(...)
  return co
end

function async.wrap(f, ...)
  local args = {...}
  return function(...)
    return async.run(f, unpack(vim.list_extend(vim.list_slice(args), {...})))
  end
end

-- Interrupt a running coroutine mid-execution.
function async.interrupt(msg, level)
  if msg then
    vim.notify(msg, level or vim.log.levels.ERROR)
  end
  coroutine.yield(async.INTERRUPT)
end

-- wait on the main thread for coroutines to complete (only useful for scripts)
function async.join(...)
  local function still_running(...)
    local are_dead = vim.tbl_map(function(co) return coroutine.status(co) == "dead" end, {...})
    return vim.tbl_contains(are_dead, false)
  end
  while still_running(...) do
    vim.wait(250)
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
