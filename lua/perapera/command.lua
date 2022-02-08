local perapera = require("perapera")

local command = {
  subcommands = {
    "translate",
    "languages"
  }
}

--local function visual_selection_range()
--  local _, srow, scol = unpack(vim.fn.getpos("'<"))
--  local _, erow, ecol = unpack(vim.fn.getpos("'>"))
--
--  --if erow < srow or (erow == srow and ecol <= scol) then
--  --  srow, scol, erow, ecol = erow, ecol, srow, scol
--  --end
--  print(srow, scol, erow, ecol)
--
--  local lines = vim.fn.getline(srow, erow)
--
--  lines[1] = lines[1]:sub(scol)
--  lines[#lines] = lines[#lines]:sub(1, ecol - (vim.o.selection == "inclusive" and 0 or 1))
--
--  return table.concat(lines, "\n")
--end

function command.translate(srow, erow, opts)
  perapera.async.run(function()
    local text = table.concat(vim.fn.getline(srow, erow), "\n")
    local engine = perapera.engines[opts.engine or "default"]
    local translation = engine:translate(text, opts.source, opts.target, opts)

    vim.fn.append(erow, vim.split(translation, "\n"))
    vim.fn.deletebufline('.', srow, erow)
  end)
end

function command.languages(opts)
  perapera.async.run(function()
    print(opts)
  end)
end

function command.parse(srow, erow, ...)
  local opts, subcmd = {}, command.subcommands[1]

  for idx, arg in ipairs{...} do
    if idx == 1 and vim.tbl_contains(command.subcommands, arg) then
      subcmd = arg
    else
      local key, value = arg:match("(.-)=(.*)")
      opts[key] = value
    end
  end

  command[subcmd](srow, erow, opts)
end

return command
