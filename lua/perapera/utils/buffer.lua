local buffer = {
  group = "perapera",
  callbacks = {}
}

local function get_next_id(buf)
  if not buffer.callbacks[buf] then
    buffer.callbacks[buf] = {}
    vim.cmd(([[
      augroup %s
        autocmd BufWipeout <buffer=%d> ++once :lua require("perapera.utils.buffer").callbacks[%d] = nil
      augroup END
    ]]):format(buffer.group, buf, buf))
  end

  return #buffer.callbacks[buf] + 1
end

function buffer.autocmd(buf, args)
  local events = type(args.events) == "table" and table.concat(args.events, ",") or args.events
  local pattern = ("<buffer=%d>"):format(buf)
  local once = args.once and "++once" or ""
  local nested = args.nested and "++nested" or ""
  local id = get_next_id(buf)

  buffer.callbacks[buf][id] = function()
    args.callback()
    if args.once and buffer.callbacks[buf] then
      buffer.callbacks[buf][id] = nil
    end
  end

  vim.cmd(([[
    augroup %s
      autocmd %s %s %s %s :lua require("perapera.utils.buffer").callbacks[%d][%d]()
    augroup END
  ]]):format(buffer.group, events, pattern, once, nested, buf, id))
end

function buffer.keymap(buf, args)
  local id = get_next_id(buf)
  local rhs = ([[<cmd>lua require("perapera.utils.buffer").callbacks[%d][%d]()<cr>]]):format(buf, id)

  buffer.callbacks[buf][id] = args.rhs
  vim.api.nvim_buf_set_keymap(buf, args.mode, args.lhs, rhs, args.opts)
end

return buffer
