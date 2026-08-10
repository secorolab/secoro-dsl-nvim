; Highlights for the fsm (coord-dsl) tree-sitter grammar.
;
; One role per capture, so a token's colour says what it does, not where it sits:
;
;   @keyword           the top-level introducers, plus import/ns
;   @label             slot names: every sub-block opener and every field key
;                      (`states`, `transitions`, `from`, `when`, `do`)
;   @type              the kind of thing being declared (`evt`)
;   @variable          every name this file declares
;   @variable.member   every reference to one, inside <>
;   @module            namespace prefixes
;
; Later patterns win in Neovim, so generic captures come first and the scoped
; overrides that must beat them come last.

; ------------------------------------------------------- top-level introducers

"import" @keyword
"ns" @keyword
"fsm" @keyword
"evt" @keyword
"loop" @keyword

; ----------------------------------------------------------------- slot names

"description" @label
"states" @label
"start" @label
"end" @label
"transitions" @label
"reactions" @label
"from" @label
"to" @label
"when" @label
"do" @label
"fires" @label

; ---------------------------------------------------------------------- types

(event "evt" @type)

; ------------------------------------------------------------- declared names

(namespace_decl name: (name) @module)
(event_loop namespace: (fqn) @module)
(fsm namespace: (fqn) @module)

(event_loop name: (name) @variable)
(fsm name: (name) @variable)
(event name: (name) @variable)
(state name: (name) @variable)
(transition name: (name) @variable)
(reaction name: (name) @variable)

; ----------------------------------------------------------------- references

"<" @punctuation.special
">" @punctuation.special
(ref path: (fqn) @variable.member)

; ------------------------------------------------------------------- literals

(comment) @comment @spell
(string) @string

; ---------------------------------------------------------------- punctuation

"{" @punctuation.bracket
"}" @punctuation.bracket
"(" @punctuation.bracket
")" @punctuation.bracket
"," @punctuation.delimiter
":" @punctuation.delimiter
"." @punctuation.delimiter
"=" @operator

; `evt loop:` names the loop the FSM listens to; the introducer of a loop is the
; keyword above.
(event_loop_ref "evt" @label "loop" @label)
