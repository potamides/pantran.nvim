if !has('nvim-0.6.0')
  echoerr "Pantran.nvim requires at least nvim-0.6.0."
  finish
end

if exists('g:loaded_pantran')
  finish
endif
let g:loaded_pantran = 1

"" Command definition
" -----------------------------------------------------------------------------
function s:pantran_complete(...)
  let comp = luaeval("require('pantran.command').complete(unpack(_A))", a:000)
  return join(comp, "\n")
endfunction

command -range -nargs=* -complete=custom,s:pantran_complete Pantran
  \ lua require("pantran.command").parse(unpack{<f-args>})

"" Highlights
" -----------------------------------------------------------------------------
highlight default link PantranTitle Constant
highlight default link PantranNormal Normal
highlight default link PantranBorder PantranNormal

" language bar
highlight default link PantranLanguagebar Identifier
highlight default link PantranPromptPrefix Identifier
highlight default link PantranPromptCounter NonText

" select ui
highlight default link PantranSelection Visual
highlight default link PantranSelectionCaret PantranSelection

" help popup
highlight default link PantranKeymap Special
highlight default link PantranSeparator SpecialKey
highlight default link PantranMode Constant
highlight default link PantranFunction Function
