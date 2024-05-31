local config = require("pantran.config")

local window = {
  config = {
    title_border = {"┤ ", " ├"},
    window_config = {
      relative = "editor",
      border   = "single"
    },
    options = {
      number         = false,
      relativenumber = false,
      cursorline     = false,
      cursorcolumn   = false,
      linebreak      = true,
      breakindent    = true,
      wrap           = true,
      showbreak      = "NONE",
      foldcolumn     = "0",
      signcolumn     = "auto",
      colorcolumn    = "",
      fillchars      = "eob: ",
      winhighlight   = "Normal:PantranNormal,SignColumn:PantranNormal,FloatBorder:PantranBorder",
      textwidth      = 0,
    }
  }
}

function window._buf_get_text(buf)
  return table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, true), "\n")
end

function window:get_text()
  return window._buf_get_text(self.bufnr)
end

function window._buf_set_text(buf, text)
  -- Clear undo history when changing text programmatically
  local old_undolevels = vim.api.nvim_buf_get_option(buf, "undolevels")
  vim.api.nvim_buf_set_option(buf, "undolevels", -1)
  vim.api.nvim_buf_set_lines(buf, 0, -1, true, vim.split(text or "", "\n", {plain = true}))
  vim.api.nvim_buf_set_option(buf, "undolevels", old_undolevels)
end

function window:_set_buf(buf)
  if vim.api.nvim_win_get_buf(self.win_id) ~= buf then
    vim.api.nvim_win_set_buf(self.win_id, buf)
  end
end

function window:set_text(text)
  self._buf_set_text(self.bufnr, text)
  self:_set_buf(self.bufnr)
end

function window:get_virtual()
  return vim.trim(window._buf_get_text(self.virtnr))
end

function window:set_virtual(args)
  args = args or {}
  -- Create enough lines to be able to create one extmark on each line for each
  -- virt_text tuple. Using builtin virt_lines feature would be nicer but they
  -- have some issues right now, e.g. they don't scroll, hl_eol doesn't work,
  -- etc (see https://github.com/neovim/neovim/issues/16166).
  if not args.nomodify then
    self._buf_set_text(
      self.virtnr,
      ("\n"):rep(math.max(
        args.left and #args.left or math.max(#self._extmarks.left, #self._signs),
        #(args.right or self._extmarks.right)) - 1)
    )
  end

  -- abuse signcolumn to get primitive anti-conceal (see https://github.com/neovim/neovim/issues/16466)
  if args.left and args.displace then
    for idx, sign in ipairs(args.left) do
      local name = ("Pantran-%p-%d"):format(self, idx)
      vim.fn.sign_define{{name = name, text = sign[1][1], texthl = sign[1][2]}}
      self._signs[idx] = {
        name = name,
        id = vim.fn.sign_place(
          self._signs[idx] and self._signs[idx].id or 0,
          "pantran",
          name,
          self.virtnr,
          {lnum = idx}
      )}
    end
    self:_clear_extmarks(nil, "left")
    self:_clear_signs(#args.left + 1)
  elseif args.left then
    self:_clear_signs()
  end

  for pos, lines in pairs{left = not args.displace and args.left or nil, right = args.right} do
    self:_clear_extmarks(#lines + 1, pos)
    for idx, line in ipairs(lines) do

      if args.separator then
        local sep = {args.separator, "PantranNormal"}
        for i = #line - 1, 1, -1 do
          table.insert(line, i + 1, sep)
        end
      end

      if args.margin then
        local margin = {args.margin, "PantranNormal"}
        table.insert(line, pos == "right" and #line + 1 or 1, margin)
      end

      self._extmarks[pos][idx] = vim.api.nvim_buf_set_extmark(self.virtnr, self._namespace, idx - 1, 0, {
        id = self._extmarks[pos][idx],
        virt_text_pos = pos == "right" and "right_align" or "overlay",
        hl_group = line[#line][2],
        hl_eol = args.hl_eol,
        right_gravity = false,
        virt_text = line
      })
    end
  end
  self:_set_buf(self.virtnr)
end

function window:_clear_extmarks(start, pos)
  local to_delete = pos and {[pos] = self._extmarks[pos]} or self._extmarks

  for _, extmarks in pairs(to_delete) do
    for idx = #extmarks, start or 1, -1 do
      vim.api.nvim_buf_del_extmark(self.virtnr, self._namespace, table.remove(extmarks, idx))
    end
  end
end

function window:_clear_signs(start)
  for idx = #self._signs, start or 1, -1 do
    local sign = table.remove(self._signs, idx)
    vim.fn.sign_unplace("pantran", {buffer = self.virtnr, id = sign.id})
    vim.fn.sign_undefine(sign.name)
  end
end

function window:clear_virtual()
  self:_clear_extmarks()
  self:_clear_signs()
  self._buf_set_text(self.virtnr, nil)
  self:_set_buf(self.bufnr)
end

function window:set_title(title)
  local conf = self:get_config()
  local title_len = vim.fn.strdisplaywidth(title .. table.concat(self.config.title_border))
  local title_conf = {
    border = "none",
    zindex =  conf.zindex + 1,
    row    = conf.row,
    col    = conf.col + math.ceil((conf.width - title_len) / 2) + 1,
    width  = title_len,
    height = 1,
  }

  if not self.title then
    self.title = window.new(title_conf)
  else
    self.title:set_config(title_conf)
    -- FIXME: without this the title isn't properly redrawn, might be related
    -- to https://github.com/neovim/neovim/issues/11597. Need investigate this
    -- further.
    vim.cmd[[mode]]
  end

  self._title = title
  self.title:set_virtual{left = {{
    {self.config.title_border[1], "PantranBorder"},
    {title, "PantranTitle"},
    {self.config.title_border[2], "PantranBorder"}
  }}}
end

function window:set_config(conf)
  vim.api.nvim_win_set_config(self.win_id, vim.tbl_extend("force", window.config.window_config, conf))
  if self.title then
    self:set_title(self._title)
  end
end

function window:get_config()
  local conf = vim.api.nvim_win_get_config(self.win_id)
  -- https://github.com/neovim/neovim/issues/27277
  conf.row = type(conf.row) =="number" and conf.row or conf.row[false]
  conf.col = type(conf.col) =="number" and conf.col or conf.col[false]
  return conf
end

function window:set_option(option, value)
  local scope = vim.api.nvim_get_option_info(option).scope
  if scope == "buf" then
    vim.api.nvim_buf_set_option(self.bufnr, option, value)
    vim.api.nvim_buf_set_option(self.virtnr, option, value)
  elseif scope == "win" then
    vim.api.nvim_win_set_option(self.win_id, option, value)
  end
end

function window:set_keymap(mode, lhs, rhs, opts)
  vim.api.nvim_buf_set_keymap(self.bufnr, mode, lhs, rhs, opts)
  vim.api.nvim_buf_set_keymap(self.virtnr, mode, lhs, rhs, opts)
end

function window:close()
  pcall(vim.api.nvim_buf_delete, self.bufnr, {})
  pcall(vim.api.nvim_buf_delete, self.virtnr, {})
  if self.title then
    self.title:close()
  end
  self.closed = true
end

function window:scroll_to(line)
  vim.api.nvim_win_set_cursor(self.win_id, {line, vim.api.nvim_win_get_cursor(self.win_id)[2]})
end

function window._enter_win(win_id, noautocmd)
  local old_ignore = vim.o.eventignore
  if noautocmd then
    vim.o.eventignore = "all"
  end
  vim.api.nvim_set_current_win(win_id)
  if noautocmd then
    vim.o.eventignore = old_ignore
  end
end

function window:enter(noautocmd, startinsert)
  self._enter_win(self.win_id, noautocmd)
  if startinsert then
    vim.cmd[[startinsert]]
  else
    vim.cmd[[stopinsert]]
  end
end

function window:exit(noautocmd)
  self._enter_win(vim.fn.win_getid(vim.fn.winnr("#")), noautocmd)
end

function window._create(conf)
  conf = vim.tbl_extend("force", window.config.window_config, conf)

  -- use own buffer for virtual text, as due to some current issues mentioned
  -- above the actual text needs to be modified which would affect undo
  -- history, autocmds, etc when we would do it in the same buffer
  local virtnr = vim.api.nvim_create_buf(false, true)
  local bufnr = vim.api.nvim_create_buf(false, true)
  local win_id = vim.api.nvim_open_win(bufnr, false, conf)

  return {
    bufnr = bufnr,
    virtnr = virtnr,
    win_id = win_id
  }
end

function window._safe_call(self, key)
  if type(window[key]) == "function" then
    if self.closed then
      return function() return "" end -- FIXME: return function-specific default value
    end
  end
  return window[key]
end

-- must set width and height
function window.new(conf)
  local self = setmetatable(window._create(conf), {__index = window._safe_call})
  self._namespace = vim.api.nvim_create_namespace("pantran")
  self._signs, self._extmarks = {}, {
    right = {},
    left = {}
  }

  -- FIXME: window-local options are sometimes reset when switching buffers
  -- (seems to happen only with 'fillchars'). Find out why, it might be a bug
  -- in Neovim. This quickfix sets window-local options for each buffer.
  for _, buf in ipairs{self.virtnr, self.bufnr} do
    self:_set_buf(buf)
    for option, value in pairs(self.config.options) do
      self:set_option(option, value)
    end
  end

  return self
end

return config.apply(config.user.window, window)
