local bufutils = require("pantran.utils.buffer")
local config = require("pantran.config")

local selector = {
  config = {
    prompt_prefix = "> ",
    selection_caret = "► "
  }
}

function selector:get_matches()
  local query, format = self._edit_win:get_virtual():lower(), self._opts.format_item
  local matches = vim.tbl_filter(function(item) return format(item):lower():find(query) end, self._items)
  table.sort(matches, function(a, b) return format(a) < format(b) end)

  return matches
end

function selector:update()
  local virtual, format = {}, self._opts.format_item

  for idx, item in pairs(self:get_matches()) do
    local highlight = idx == self._selected and "PantranSelection" or "PantranNormal"
    local caret_len = vim.api.nvim_strwidth(self.config.selection_caret)
    local prefix = idx == self._selected and self.config.selection_caret or (" "):rep(caret_len)
    table.insert(virtual, {{prefix, highlight}, {format(item), highlight}})
  end

  self._edit_win:scroll_to(1)
  self._item_win:scroll_to(self._selected)
  self._item_win:set_virtual{left = virtual, hl_eol = true}
  self._edit_win:set_virtual{
    left = {{{self.config.prompt_prefix, "PantranPromptPrefix"}}},
    right = {{{("%d / %d"):format(#virtual, #self._items), "PantranPromptCounter"}}},
    displace = true, nomodify = true
  }
end

function selector:set_index(index)
  if self._items and self._opts then
    if index > 0 and index <= #self:get_matches() then
      self._selected = index
    end
    self:update()
  end
end

function selector:next()
  self:set_index(self._selected + 1)
end

function selector:prev()
  self:set_index(self._selected - 1)
end

function selector:first()
  self:set_index(1)
end

function selector:last()
  self:set_index(#self:get_matches())
end

function selector:choose()
  if self._on_choice then
    self._on_choice(self:get_matches()[self._selected])
  end
  self._items, self._opts, self._on_choice = nil, nil, nil
end

function selector:abort()
  if self._on_choice then
    self._on_choice()
  end
  self._items, self._opts, self._on_choice = nil, nil, nil
end

function selector:select(items, opts, on_choice)
  opts = opts or {}
  opts.format_item = opts.format_item or tostring
  self._items = items
  self._opts = opts
  self._on_choice = on_choice

  self:first()
  self._edit_win:enter(true, true)
end

function selector:set_item_win(win)
  self._item_win = win
end

function selector.new(edit_win, item_win)
  local self = {
    _edit_win = edit_win,
    _item_win = item_win
  }

  bufutils.autocmd(self._edit_win.virtnr, {
    events = {"TextChanged", "TextChangedI", "TextChangedP"},
    nested = true,
    callback = function() self:first() end
  })

  return setmetatable(self, {
    __index = selector,
    __call = function(_, ...) self:select(...) end
  })
end

return config.apply(config.user.select, selector)
