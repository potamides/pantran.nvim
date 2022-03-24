local config = require("perapera.config")

local window = {
  config = {
    title_border = {"┤ ", " ├"}, -- TODO: make the default without bars
    window_config = {
      relative = "editor",
      border   = "single"
    },
    options = {
      number         = false,
      relativenumber = false,
      cursorline     = false,
      cursorcolumn   = false,
      foldcolumn     = "0",
      signcolumn     = "auto",
      colorcolumn    = "",
      fillchars      = "eob: ",
      winhighlight   = "Normal:PeraperaNormal,FloatBorder:PeraperaBorder",
      textwidth      = 0,
    }
  }
}

function window:set_text(text)
  -- check if window was closed already
  vim.api.nvim_buf_set_lines(self.bufnr, 0, -1, true, vim.split(text or "", "\n", {plain = true}))
end

function window:get_text()
  return table.concat(vim.api.nvim_buf_get_lines(self.bufnr, 0, -1, true), "\n")
end

-- TODO: make right_align string argument and allow setting coordinates in parameters (or virt_lines)
-- TODO: look virt_text_win_col
function window:set_virtual(args)
  local virt_text = vim.list_slice(args.virt_text or {})
  if args.separator then
    local sep = {args.separator, "PeraperaNormal"}
    for idx = #virt_text,0,-1 do
      if idx == #virt_text and args.right_align then
        table.insert(virt_text, idx + 1, sep)
      elseif idx == 0 and not args.right_align then
        table.insert(virt_text, idx + 1, sep)
      elseif idx >= 1 and idx < #virt_text then
        table.insert(virt_text, idx + 1, sep)
      end
    end
  end

  return vim.api.nvim_buf_set_extmark(self.bufnr, self._namespace, 0, 0, {
    id = args.id,
    virt_text_pos = args.right_align and "right_align" or "overlay",
    virt_text = virt_text
  })
end

function window:set_title(title)
  local conf = self:get_config()
  local title_len = vim.fn.strdisplaywidth(title .. table.concat(self.config.title_border))
  local title_conf = {
    border = "none",
    zindex =  conf.zindex + 1,
    row    = conf.row[false], -- FIXME: find out why this is a table
    col    = conf.col[false] + math.ceil((conf.width - title_len) / 2) + 1,
    width  = title_len,
    height = 1,
  }

  if not self.title then
    self.title = window.new(title_conf)
  else
    self.title:set_config(title_conf)
    -- without this the title isn't properly redrawn, might be related to https://github.com/neovim/neovim/issues/11597
    -- TODO: investigate this further
    vim.cmd[[mode]]
  end

  self._title = title
  self._title_id = self.title:set_virtual{
    id = self._title_id,
    virt_text = {
      {self.config.title_border[1], "PeraperaBorder"},
      {title, "PeraperaTitle"},
      {self.config.title_border[2], "PeraperaBorder"}
  }}
end

function window:set_config(conf)
  vim.api.nvim_win_set_config(self.win_id, vim.tbl_extend("force", window.config.window_config, conf))
  if self.title then
    self:set_title(self._title)
  end
end

function window:get_config()
  return vim.api.nvim_win_get_config(self.win_id)
end

function window:set_option(option, value)
  local scope = vim.api.nvim_get_option_info(option).scope
  if  scope == "buf" then
    vim.api.nvim_buf_set_option(self.bufnr, option, value)
  elseif scope == "win" then
    vim.api.nvim_win_set_option(self.win_id, option, value)
  end
end

function window:close()
  vim.api.nvim_buf_delete(self.bufnr, {})
  if self.title then
    self.title:close()
  end
end

function window:enter()
  vim.api.nvim_set_current_win(self.win_id)
end

function window._create(conf)
  conf = vim.tbl_extend("force", window.config.window_config, conf)

  local bufnr = vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(bufnr, false, conf)
  vim.api.nvim_win_set_buf(win_id, bufnr)

  return {
    bufnr = bufnr,
    win_id = win_id
  }
end

function window._safe_call(self, key)
  if type(window[key]) == "function" then
    if not vim.api.nvim_win_is_valid(self.win_id) or not vim.api.nvim_buf_is_valid(self.bufnr) then
      return function() end
    end
  end
  return window[key]
end

-- must set width and height
function window.new(conf)
  local self = setmetatable(window._create(conf), {__index = window._safe_call})
  self._namespace = vim.api.nvim_create_namespace("perapera")

  for option, value in pairs(self.config.options) do
    self:set_option(option, value)
  end

  return self
end

return config.apply(config.user.window, window)
