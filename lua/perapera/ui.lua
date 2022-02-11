local ui = {
  default = {
    width_percentage = 0.8,
    height_percentage = 0.4,
    min_height = 10,
    min_width = 40,
    config = {
      --style = 'minimal',
      relative = "editor",
      border = "single"
    },
    options = {
      number = false,
      relativenumber = false,
      cursorline = false,
      cursorcolumn = false,
      foldcolumn = "0",
      signcolumn = "auto",
      colorcolumn = "",
      fillchars = "eob: ",
      winhighlight = "Normal:Normal,FloatBorder:Normal"
    }
  }
}

function ui.create_window(config, options)
  config = vim.tbl_extend("force", ui.default.config, config or {})
  options = vim.tbl_extend("force", ui.default.options, options or {})

  local bufnr = vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(bufnr, true, config)
  vim.api.nvim_win_set_buf(win_id, bufnr)

  for option, value in pairs(options) do
    vim.api.nvim_win_set_option(win_id, option, value)
  end

  return {
    bufnr = bufnr,
    win_id = win_id
  }
end

-- Create ui that takes up certain percentage of the current screen.
function ui.new(width_percentage, height_percentage)
  local height = math.ceil(vim.o.lines * (height_percentage or ui.default.height_percentage))
  local width = math.floor(vim.o.columns * (width_percentage or ui.default.width_percentage))
  height, width = math.max(ui.default.min_height, height), math.max(ui.default.min_width, width)
  local row = math.floor(((vim.o.lines - height) / 2) - 1)
  local col = math.floor((vim.o.columns - width) / 2)

  if height < vim.o.lines or width < vim.o.columns then
    local status = {
      row       = row,
      col       = col,
      width     = width,
      height    = 1,
      focusable = false
    }
    local translation = {
      row       = row + 3,
      col       = col + math.ceil(width / 2) + 1,
      width     = math.floor(width / 2) - 1,
      height    = height - 3,
      focusable = false
    }
    local text = {
      row    = row + 3,
      col    = col,
      width  = math.ceil(width / 2) - 1,
      height = height - 3
    }

    return {
      status = ui.create_window(status),
      translation = ui.create_window(translation),
      text = ui.create_window(text)
    }
  else
    vim.notify("Editor grid too small to launch UI!", vim.log.levels.ERROR)
  end
end

return ui
