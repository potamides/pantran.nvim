local utils = require("perapera.utils")
local async = require("perapera.async")

local events = {
  timeout = 500,
}

function events:on_cursor_hold()
  self.timer:start(self.timeout, 0, async.closure(function()
    local text, source, target = self.window:get_input(), self.window.source, self.window.target
    if #text > 0 and text ~= self.previous_text then
      local translation = self.window.engine:translate(text, source, target)
      self.window:set_translation(translation)
      self.previous_text = text
    end
  end))
end

function events.new(window)

  local self = setmetatable({
      window = window,
      timer = vim.loop.new_timer(),
    }, {__index = events})

  utils.buf_autocmd(window.input.bufnr, {
    events = {"CursorMoved", "CursorMovedI"},
    nested = true,
    callback = function() self:on_cursor_hold() end
  })

  return self
end

return events
