local utils = {
  group = "perapera",
  callbacks = {}
}

local function get_next_id(buffer)
  if not utils.callbacks[buffer] then
    utils.callbacks[buffer] = {}
    vim.cmd(([[
      augroup %s
        autocmd BufWipeout <buffer=%d> ++once :lua require("perapera.utils").callbacks[%d] = nil
      augroup END
    ]]):format(utils.group, buffer, buffer))
  end

  return #utils.callbacks[buffer] + 1
end

function utils.buf_autocmd(buffer, args)
  local events = type(args.events) == "table" and table.concat(args.events, ",") or args.events
  local pattern = ("<buffer=%d>"):format(buffer)
  local once = args.once and "++once" or ""
  local nested = args.nested and "++nested" or ""
  local id = get_next_id(buffer)

  utils.callbacks[buffer][id] = function()
    args.callback()
    if args.once and utils.callbacks[buffer] then
      utils.callbacks[buffer][id] = nil
    end
  end

  vim.cmd(([[
    augroup %s
      autocmd %s %s %s %s :lua require("perapera.utils").callbacks[%d][%d]()
    augroup END
  ]]):format(utils.group, events, pattern, once, nested, buffer, id))
end

function utils.buf_keymap(buffer, args)
  local id = get_next_id(buffer)
  local rhs = ([[<cmd>lua require("perapera.utils").callbacks[%d][%d]()<cr>]]):format(buffer, id)

  utils.callbacks[buffer][id] = args.rhs
  vim.api.nvim_buf_set_keymap(buffer, args.mode, args.lhs, rhs, args.opts)
end

function utils.pop(tbl, key)
  if type(key) == "number" then
    return table.remove(tbl, key)
  else
    local value = tbl[key]
    tbl[key] = nil
    return value
  end
end

return utils
