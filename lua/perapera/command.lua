local engines = require("perapera.engines")
local ui = require("perapera.ui")
local handlers = require("perapera.handlers")
local async = require("perapera.async")
local config = require("perapera.config")

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

-- recompute coords, since coords of marks could have changed during translation
function command._marks2coords(marks, delete)
  local start = vim.api.nvim_buf_get_extmark_by_id(0, command.namespace, marks[1], {})
  local stop = vim.api.nvim_buf_get_extmark_by_id(0, command.namespace, marks[2], {})

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
  opts = opts or {}
  opts.mode = opts.mode or command.config.default_mode
  opts.engine = opts.engine or "default"
  opts.source = opts.source or engines[opts.engine].config.default_source
  opts.target = opts.target or engines[opts.engine].config.default_target

  local srow = vim.api.nvim_win_get_cursor(0)[1] - 1
  local scol, erow, ecol = 0, srow + vim.v.count, -1
  local input = table.concat(vim.api.nvim_buf_get_lines(0, srow, erow + 1, true), "\n"):sub(scol + 1, ecol)
  local marks = {
    vim.api.nvim_buf_set_extmark(0, command.namespace, srow, scol, {}),
    vim.api.nvim_buf_set_extmark(0, command.namespace, erow, ecol, {})
  }

  command._translate(input, vim.v.count > 0, marks, opts)
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
