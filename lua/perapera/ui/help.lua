--[[
Pop-up help window for keybindings.
--]]
local buffer = require("perapera.utils.buffer")
local window = require("perapera.ui.window")
local config = require("perapera.config")

local help = {
  title = "Keymap Help",
  config = {
    separator = " ► "
  }
}

function help._compute_win_coords(displayheight, displaywidth)
  local width = math.max(#help.title, displaywidth)
  local col = math.floor((vim.o.columns - width) / 2)

  return {
    row = 1,
    col = col,
    width = width,
    height = displayheight,
    zindex = 52 -- put help over translation window
  }
end

function help._open_win(displaywidth, lines)
  help._win = window.new(help._compute_win_coords(#lines, displaywidth))
  help._win:set_virtual{left = lines, margin = " "}
  help._win:set_title(help.title)
end

function help._register_events()
  local ns_id
  local function close()
    -- The on_key callback is called before mappings are evaluated. As we want
    -- to be able to toggle the help window we need to close the window after
    -- mappings are evaluated. Here, this is achieved with a little delay.
    -- FIXME: Find a solution which doesn't require a delay
    vim.defer_fn(function() help._win:close() end, 20)
    vim.on_key(nil, ns_id)
  end

  ns_id = vim.on_key(close)
  buffer.autocmd(0, {
    events = "VimResized",
    callback = close
  })
end

function help._virt2text(virt_text)
  return table.concat(vim.tbl_map(function(v) return v[1] end, virt_text))
end

function help.toggle()
  if not help._win or help._win.closed then
    local mode, buf = vim.api.nvim_get_mode().mode, vim.api.nvim_get_current_buf()
    local mappings, lines = vim.tbl_map(tostring, buffer.get_mappings(buf, mode)), {}
    local max_map_len, max_width = math.max(unpack(vim.tbl_map(vim.api.nvim_strwidth, vim.tbl_keys(mappings)))), 0

    for lhs, rhs in pairs(mappings) do
      local line = {
        {mode, "Constant"},
        {help.config.separator, "PeraperaSeparator"},
        {lhs, "PeraperaKeymap"},
        {(" "):rep(max_map_len - #lhs) .. help.config.separator, "PeraperaSeparator"},
        {rhs, "PeraperaFunction"}
      }
      table.insert(lines, line)
      local width = vim.api.nvim_strwidth(help._virt2text(line)) + 2 -- acount for margin
      if width > max_width then
        max_width = width
      end
    end

    table.sort(lines, function(a, b) return help._virt2text(a) < help._virt2text(b) end)
    help._open_win(max_width, lines)
    help._register_events()
  elseif help._win then
    help._win:close()
  end
end

return config.apply(config.user.help, help)
