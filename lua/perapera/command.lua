local engines = require("perapera.engines")
local ui = require("perapera.ui")
local handlers = require("perapera.handlers")
local async = require("perapera.async")
local config = require("perapera.config")
local uapi = require("perapera.utils.api")

local command = {
  namespace = vim.api.nvim_create_namespace("perapera"),
  config = {
    default_mode = "interactive"
  },
  flags = {
    mode = {
      "append",
      "interactive",
      "hover",
      "replace",
      "yank"
    },
    engine = vim.fn.sort(vim.tbl_keys(engines)),
    source = {},
    target = {}
  }
}

function command.complete(arglead)
  if arglead:find("=") then
    local key = arglead:match("(.-)=.*")
    return vim.tbl_map(function(v) return key .. "=" .. v end, command.flags[key] or {})
  else
    return vim.tbl_map(function(v) return v .. "=" end, vim.tbl_keys(command.flags))
  end
end

-- we need to create marks for coords, since coords could change during
-- non-interactive translations with a large delay
function command._coords2marks(coords)
  return {
    start = vim.api.nvim_buf_set_extmark(0, command.namespace, coords.srow, coords.scol, {}),
    stop  = vim.api.nvim_buf_set_extmark(0, command.namespace, coords.erow, coords.ecol, {})
  }
end

function command._marks2coords(marks, delete)
  local start = vim.api.nvim_buf_get_extmark_by_id(0, command.namespace, marks.start, {})
  local stop = vim.api.nvim_buf_get_extmark_by_id(0, command.namespace, marks.stop, {})

  if delete then
    for _, mark in pairs(marks) do
      vim.api.nvim_buf_del_extmark(0, command.namespace, mark)
    end
  end

  if not vim.tbl_isempty(start) and not vim.tbl_isempty(stop) then
    return {srow = start[1], scol = start[2], erow = stop[1], ecol = stop[2]}
  end
end

function command._translate(input, initialize, marks, opts)
  opts = opts or {}
  opts.mode = opts.mode or command.config.default_mode
  opts.engine = opts.engine or "default"
  opts.source = opts.source or engines[opts.engine].config.default_source
  opts.target = opts.target or engines[opts.engine].config.default_target
  local engine = engines[opts.engine]

  if opts.mode == "interactive" then
    ui.new(engine, opts.source, opts.target, command._marks2coords(marks, true), initialize and input)
  elseif handlers[opts.mode] then
    async.run(function()
      local translation = engine.translate(input, opts.source, opts.target).text
      handlers[opts.mode](translation, command._marks2coords(marks, true))
    end)
  end
end

function command.translate(opts)
  local srow, erow, scol, ecol
  srow, scol = vim.api.nvim_win_get_cursor(0)[1] - 1, 0
  erow = srow + math.max(0, vim.v.count - 1)
  ecol = #vim.api.nvim_buf_get_lines(0, erow, erow + 1, true)[1] - 1

  local marks = command._coords2marks{srow = srow, scol = scol, erow = erow, ecol = ecol}
  local input = table.concat(uapi.nvim_buf_get_text(0, srow, scol, erow + 1, ecol + 1), "\n")
  command._translate(input, vim.v.count > 0, marks, opts)
end

local _opts, _old_opfunc
function command.operator(arg)
  if not arg or type(arg) == "table" then -- see :h :map-operator
    _opts, _old_opfunc =  arg, vim.opt.operatorfunc
    vim.opt.operatorfunc = "v:lua.require'perapera.command'.operator"
    return 'g@'
  end

  vim.opt.operatorfunc = _old_opfunc
  local srow, erow, scol, ecol

  if arg == "char" then
    srow, scol = unpack(vim.api.nvim_buf_get_mark(0, "["))
    erow, ecol = unpack(vim.api.nvim_buf_get_mark(0, "]"))
    srow, erow = srow - 1, erow - 1
  else -- linewise
    srow, erow = vim.api.nvim_buf_get_mark(0, "[")[1] - 1, vim.api.nvim_buf_get_mark(0, "]")[1] - 1
    scol, ecol = 0, #vim.api.nvim_buf_get_lines(0, erow, erow + 1, true)[1] - 1
  end

  local marks = command._coords2marks{srow = srow, scol = scol, erow = erow, ecol = ecol}
  local input = table.concat(uapi.nvim_buf_get_text(0, srow, scol, erow + 1, ecol + 1), "\n")
  command._translate(input, true, marks, _opts)
end

function command.parse(...)
  local opts = {}

  for _, arg in ipairs{...} do
    local key, value = arg:match("(.-)=(.+)")
    if key and value then
      opts[key] = value
    end
  end

  command.translate(opts)
end

return config.apply(config.user.command, command)
