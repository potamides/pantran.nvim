if !has('nvim-0.6.0')
  echoerr "Perapera.nvim requires at least nvim-0.6.0."
  finish
end

if exists('g:loaded_perapera')
  finish
endif
let g:loaded_perapera = 1

command -range -nargs=* Perapera lua require("perapera.command").parse(<line1>, <line2>, unpack{<f-args>})

highlight default link PeraperaTitle Constant
highlight default link PeraperaLanguagebar Identifier

highlight default link PeraperaNormal Normal
highlight default link PeraperaBorder PeraperaNormal

highlight default link PeraperaSelection Visual
highlight default link PeraperaSelectionCaret PeraperaSelection

highlight default link PeraperaPromptPrefix Identifier
highlight default link PeraperaPromptCounter NonText
