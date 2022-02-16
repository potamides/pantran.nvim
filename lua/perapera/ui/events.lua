local utils = require("perapera.utils")
local async = require("perapera.async")
local actions = require("perapera.ui.actions")

local events = {
  timeout = 500
}

local function timeout_translate(self, window)
  self.timer:start(events.timeout, 0, async.wrap(function()
    local input = window:get_input()
    if input ~= self.previous_input then
      actions.translate(window)
      self.previous_input = input
    end
  end))
end

events.events = {
  CursorMoved = timeout_translate,
  CursorMovedI = timeout_translate,
}

function events.setup(window)
  local self = {
    timer = vim.loop.new_timer(),
    previous_input = window:get_input()
  }
  -- BufEnter
  actions.translate(window)

  for event, handler in pairs(events.events) do
    utils.buf_autocmd(window.input.bufnr, {
      events = event,
      nested = true,
      callback = function() handler(self, window) end
    })
  end
end

return events
