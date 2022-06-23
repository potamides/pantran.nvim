if !has('nvim-0.6.0')
  echoerr "Glotta.nvim requires at least nvim-0.6.0."
  finish
end

if exists('g:loaded_glotta')
  finish
endif
let g:loaded_glotta = 1

"" Command definition
" -----------------------------------------------------------------------------
function s:glotta_complete(...)
  let comp = luaeval("require('glotta.command').complete(unpack(_A))", a:000)
  return join(comp, "\n")
endfunction

command -range -nargs=* -complete=custom,s:glotta_complete Glotta
  \ lua require("glotta.command").parse(unpack{<f-args>})

"" Highlights
" -----------------------------------------------------------------------------
highlight default link GlottaTitle Constant
highlight default link GlottaNormal Normal
highlight default link GlottaBorder GlottaNormal

" language bar
highlight default link GlottaLanguagebar Identifier
highlight default link GlottaPromptPrefix Identifier
highlight default link GlottaPromptCounter NonText

" select ui
highlight default link GlottaSelection Visual
highlight default link GlottaSelectionCaret GlottaSelection

" help popup
highlight default link GlottaKeymap Special
highlight default link GlottaSeparator SpecialKey
highlight default link GlottaMode Constant
highlight default link GlottaFunction Function
