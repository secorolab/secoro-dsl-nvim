" Vim regex fallback for .fsm files; tree-sitter highlighting supersedes it.
" The groups link to the same captures queries/fsm/highlights.scm uses, so both
" paths render identically. See that file for the role scheme.
if exists('b:current_syntax')
  finish
endif

setlocal iskeyword+=-

" Top-level introducers
syntax keyword fsmKeyword import ns fsm loop

" Slot names: sub-block openers and field keys
syntax keyword fsmSlot description states start end transitions reactions
syntax keyword fsmSlot from to when do fires

" The kind of thing being declared
syntax keyword fsmType evt

" <path> cross-references
syntax region fsmRef start=/</ end=/>/ oneline contains=fsmRefPath,fsmRefDot
syntax match fsmRefPath /[A-Za-z_][A-Za-z0-9_-]*/ contained
syntax match fsmRefDot /\./ contained

" Declared names: the identifier introduced by its kind, or the one opening a
" transition or reaction block.
syntax match fsmDeclName /\<evt\s\+\zs[A-Za-z_][A-Za-z0-9_-]*/
syntax match fsmDeclName /^\s*\zs[A-Za-z_][A-Za-z0-9_-]*\ze\s*\({\|,\|$\)/
syntax match fsmDeclName /)\s*\zs[A-Za-z_][A-Za-z0-9_-]*\ze\s*{/
syntax match fsmDeclName /\<ns\s\+\zs[A-Za-z_][A-Za-z0-9_-]*\ze\s*=/

syntax region fsmString start=/"/ skip=/\\./ end=/"/ oneline
syntax region fsmString start=/'/ skip=/\\./ end=/'/ oneline
syntax match fsmComment /\/\/.*/ contains=@Spell

highlight default link fsmKeyword  @keyword
highlight default link fsmSlot     @label
highlight default link fsmType     @type
highlight default link fsmDeclName @variable
highlight default link fsmRef      @punctuation.special
highlight default link fsmRefPath  @variable.member
highlight default link fsmRefDot   @punctuation.delimiter
highlight default link fsmString   @string
highlight default link fsmComment  @comment

let b:current_syntax = 'fsm'
