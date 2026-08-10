" Vim regex fallback for .bdd files; tree-sitter highlighting supersedes it.
" The groups link to the same captures queries/bdd/highlights.scm uses, so both
" paths render identically. See that file for the role scheme.
if exists('b:current_syntax')
  finish
endif

setlocal iskeyword+=-

" Top-level introducers
syntax keyword bddKeyword import ns User Story Scenario Template Scenarios const
syntax keyword bddKeyword Exec bhv impl obs policy

" Slot names
syntax keyword bddSlot As A I Want So That duration task template scene variation
syntax keyword bddSlot Given When Then
syntax keyword bddSlot variant inst policies action topic type update-rate
syntax keyword bddSlot horizon provider observes module attr
syntax keyword bddSlot less-than greater-than equals tolerance

" The kind of thing being declared
syntax keyword bddType Event Task Behaviour var observation

" The words a clause is written in
syntax keyword bddOperator holds pred event occurs for all in exists such that
syntax keyword bddOperator and or not before after from until picks places at
syntax keyword bddOperator is located held by can reach does drop collide has
syntax keyword bddOperator config are sorted into select combinations
syntax keyword bddOperator permutations repeated obj ws agn set
syntax keyword bddOperator linear distance between ros simulation entity state
syntax keyword bddOperator trinary py

" Closed-vocabulary values
syntax keyword bddConstant mm cm m Hz seconds

" <path> cross-references
syntax region bddRef start=/</ end=/>/ oneline contains=bddRefPath,bddRefDot
syntax match bddRefPath /[A-Za-z_][A-Za-z0-9_-]*/ contained
syntax match bddRefDot /\./ contained

" Declared names: the identifier introduced by its kind, or naming a fluent
syntax match bddDeclName /\<\(Event\|Task\|Behaviour\|var\|Scenario\)\s\+\zs[A-Za-z_][A-Za-z0-9_-]*/
syntax match bddDeclName /)\s*\zs[A-Za-z_][A-Za-z0-9_-]*\ze\s*{/
syntax match bddDeclName /^\s*\zs[A-Za-z_][A-Za-z0-9_-]*\ze\s*:\s*holds\>/
syntax match bddDeclName /\<ns\s\+\zs[A-Za-z_][A-Za-z0-9_-]*\ze\s*=/

" The variation table draws its own frame
syntax match bddTable /|\|---/

syntax match bddNumber /\<[-+]\?\(\d\+\(\.\d*\)\?\|\.\d\+\)\([eE][-+]\?\d\+\)\?/
syntax region bddString start=/"/ skip=/\\./ end=/"/ oneline
syntax region bddString start=/'/ skip=/\\./ end=/'/ oneline
syntax match bddComment /\/\/.*/ contains=@Spell

highlight default link bddKeyword  @keyword
highlight default link bddSlot     @label
highlight default link bddOperator @keyword.operator
highlight default link bddType     @type
highlight default link bddDeclName @variable
highlight default link bddRef      @punctuation.special
highlight default link bddRefPath  @variable.member
highlight default link bddRefDot   @punctuation.delimiter
highlight default link bddTable    @punctuation.special
highlight default link bddNumber   @number
highlight default link bddString   @string
highlight default link bddConstant @constant
highlight default link bddComment  @comment

let b:current_syntax = 'bdd'
