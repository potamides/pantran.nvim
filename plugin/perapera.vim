if !has('nvim-0.6.0')
  echoerr "Perapera.nvim requires at least nvim-0.6.0."
  finish
end

if exists('g:loaded_perapera')
  finish
endif
let g:loaded_perapera = 1

"" Command definition
" -----------------------------------------------------------------------------
function s:perapera_complete(...)
  let comp = luaeval("require('perapera.command').complete(unpack(_A))", a:000)
  return join(comp, "\n")
endfunction

command -range -nargs=* -complete=custom,s:perapera_complete Perapera
  \ lua require("perapera.command").parse(unpack{<f-args>})

"" Highlights
" -----------------------------------------------------------------------------
highlight default link PeraperaTitle Constant
highlight default link PeraperaNormal Normal
highlight default link PeraperaBorder PeraperaNormal

" language bar
highlight default link PeraperaLanguagebar Identifier
highlight default link PeraperaPromptPrefix Identifier
highlight default link PeraperaPromptCounter NonText

" select ui
highlight default link PeraperaSelection Visual
highlight default link PeraperaSelectionCaret PeraperaSelection

" help popup
highlight default link PeraperaKeymap Special
highlight default link PeraperaSeparator SpecialKey
highlight default link PeraperaMode Constant
highlight default link PeraperaFunction Function
