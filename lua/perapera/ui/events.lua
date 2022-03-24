local utils = require("perapera.utils")
local actions = require("perapera.ui.actions")

local events = {
  timeout = 300
}

local function timeout_translate(window, state)
  state.timer:start(events.timeout, 0, vim.schedule_wrap(function()
    if window.input ~= state.previous_input then
      state.previous_input = window.input
      actions.translate(window)
    end
  end))
end

events.events = {
  CursorMoved = timeout_translate,
  CursorMovedI = timeout_translate,
  VimResized = actions.resize,
  WinLeave = {actions.close, once = true}
}

function events.setup(window, bufnr)
  local state = {
    timer = vim.loop.new_timer(),
    previous_input = window.input
  }
  -- BufEnter
  actions.translate(window)

  for event, handler in pairs(events.events) do
    local action, args = handler, {}
    if type(handler) == "table" then
      handler = vim.deepcopy(handler)
      action = table.remove(handler)
      args = handler
    end
    utils.buf_autocmd(bufnr, vim.tbl_extend("keep", args, {
      events = event,
      nested = true,
      callback = function() action(window, state) end
    }))
  end
end

return events
