local utils = require("perapera.utils")
local async = require("perapera.async")
local actions = require("perapera.ui.actions")

local events = {
  timeout = 500
}

local function timeout_translate(window, state)
  state.timer:start(events.timeout, 0, async.wrap(function()
    local input = window:get_input()
    if input ~= state.previous_input then
      actions.translate(window)
      state.previous_input = input
    end
  end))
end

events.events = {
  CursorMoved = timeout_translate,
  CursorMovedI = timeout_translate,
}

function events.setup(window)
  local state = {
    timer = vim.loop.new_timer(),
    previous_input = window:get_input()
  }
  -- BufEnter
  actions.translate(window)

  for event, handler in pairs(events.events) do
    utils.buf_autocmd(window.input.bufnr, {
      events = event,
      nested = true,
      callback = function() handler(window, state) end
    })
  end
end

return events
