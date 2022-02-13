local utils = {
  group = "perapera",
  callbacks = {}
}

--function utils.buf_autocmd(group, events, pat, once, nested, cmd)
function utils.buf_autocmd(buffer, args)
  local events = type(args.events) == "table" and table.concat(args.events, ",") or args.events
  local pattern = ("<buffer=%d>"):format(buffer)
  local once = args.once and "++once" or ""
  local nested = args.nested and "++nested" or ""

  vim.cmd(("augroup %s"):format(utils.group))
  if not utils.callbacks[buffer] then
    utils.callbacks[buffer] = {}
    vim.cmd(([[autocmd BufWipeout %s ++once :lua require("perapera.utils").callbacks[%d] = nil]]):format(
      pattern, buffer))
  end

  local id = #utils.callbacks[buffer] + 1

  utils.callbacks[buffer][id] = function()
    args.callback()
    if args.once and utils.callbacks[buffer] then
      utils.callbacks[buffer][id] = nil
    end
  end

  vim.cmd(([[autocmd %s %s %s %s :lua require("perapera.utils").callbacks[%d][%d]()]]):format(
    events, pattern, once, nested, buffer, id))

  vim.cmd("augroup END")
end

return utils
