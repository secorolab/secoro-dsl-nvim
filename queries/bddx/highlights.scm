; Highlights for the bddx (robbdd execution) tree-sitter grammar. Same role
; scheme as queries/bdd/highlights.scm.

; ------------------------------------------------------- top-level introducers

"import" @keyword
"ns" @keyword
"Scenario" @keyword
"Exec" @keyword
"bhv" @keyword
"impl" @keyword
"obs" @keyword
"policy" @keyword

; ----------------------------------------------------------------- slot names

"variant" @label
"scene" @label
"inst" @label
"policies" @label
"action" @label
"topic" @label
"type" @label
"update-rate" @label
"horizon" @label
"provider" @label
"observes" @label
"less-than" @label
"greater-than" @label
"equals" @label
"tolerance" @label
"module" @label
"attr" @label

; ------------------------------------------------------------------ operators

"for" @keyword.operator
"linear" @keyword.operator
"distance" @keyword.operator
"between" @keyword.operator
"and" @keyword.operator
"ros" @keyword.operator
"simulation" @keyword.operator
"entity" @keyword.operator
"state" @keyword.operator
"trinary" @keyword.operator
"py" @keyword.operator

; ---------------------------------------------------------------------- types

"observation" @type

; ------------------------------------------------------- vocabulary constants

(length_unit) @constant
"Hz" @constant
"seconds" @constant

; ------------------------------------------------------------- declared names

(namespace_decl name: (name) @module)
(behaviour_implementation namespace: (fqn) @module)
(observation_provider namespace: (fqn) @module)
(observation_policy namespace: (fqn) @module)
(scenario_execution namespace: (fqn) @module)

(behaviour_implementation name: (name) @variable)
(observation_provider name: (name) @variable)
(observation_policy name: (name) @variable)
(scenario_execution name: (name) @variable)
(observation name: (name) @variable)
(py_module_attr attr: (name) @variable)
(py_module_attr module: (fqn) @module)

; ----------------------------------------------------------------- references

"<" @punctuation.special
">" @punctuation.special
(ref path: (fqn) @variable.member)

; ------------------------------------------------------------------- literals

(comment) @comment @spell
(string) @string
(number) @number

; ---------------------------------------------------------------- punctuation

"{" @punctuation.bracket
"}" @punctuation.bracket
"(" @punctuation.bracket
")" @punctuation.bracket
"," @punctuation.delimiter
":" @punctuation.delimiter
"." @punctuation.delimiter

; `obs provider` declares one; `provider:` inside an observation names it.
(observation_provider "provider" @keyword)
