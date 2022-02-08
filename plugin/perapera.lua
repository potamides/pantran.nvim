vim.cmd([[command! -range -nargs=* Perapera lua require("perapera.command").parse(<line1>, <line2>, unpack{<f-args>})]])
