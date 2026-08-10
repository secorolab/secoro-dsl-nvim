" Vim regex fallback for .bddx files; tree-sitter highlighting supersedes it.
" The groups link to the same captures queries/bddx/highlights.scm uses.
if exists('b:current_syntax')
  finish
endif

setlocal iskeyword+=-

" Top-level introducers
syntax keyword bddxKeyword import ns Scenario Exec bhv impl obs policy

" Slot names
syntax keyword bddxSlot variant scene inst policies action topic type
syntax keyword bddxSlot update-rate horizon provider observes module attr
syntax keyword bddxSlot less-than greater-than equals tolerance

" The kind of thing being declared
syntax keyword bddxType observation

" Words relating two things
syntax keyword bddxOperator for linear distance between and ros simulation
syntax keyword bddxOperator entity state trinary py

" Closed-vocabulary values
syntax keyword bddxConstant mm cm m Hz seconds

" <path> cross-references
syntax region bddxRef start=/</ end=/>/ oneline contains=bddxRefPath,bddxRefDot
syntax match bddxRefPath /[A-Za-z_][A-Za-z0-9_-]*/ contained
syntax match bddxRefDot /\./ contained

" Declared names
syntax match bddxDeclName /)\s*\zs[A-Za-z_][A-Za-z0-9_-]*/
syntax match bddxDeclName /\<observation\s\+\zs[A-Za-z_][A-Za-z0-9_-]*/
syntax match bddxDeclName /\<ns\s\+\zs[A-Za-z_][A-Za-z0-9_-]*\ze\s*=/

syntax match bddxNumber /\<[-+]\?\(\d\+\(\.\d*\)\?\|\.\d\+\)\([eE][-+]\?\d\+\)\?/
syntax region bddxString start=/"/ skip=/\\./ end=/"/ oneline
syntax region bddxString start=/'/ skip=/\\./ end=/'/ oneline
syntax match bddxComment /\/\/.*/ contains=@Spell

highlight default link bddxKeyword  @keyword
highlight default link bddxSlot     @label
highlight default link bddxOperator @keyword.operator
highlight default link bddxType     @type
highlight default link bddxConstant @constant
highlight default link bddxDeclName @variable
highlight default link bddxRef      @punctuation.special
highlight default link bddxRefPath  @variable.member
highlight default link bddxRefDot   @punctuation.delimiter
highlight default link bddxNumber   @number
highlight default link bddxString   @string
highlight default link bddxComment  @comment

let b:current_syntax = 'bddx'
