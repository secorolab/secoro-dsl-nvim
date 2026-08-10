; Highlights for the bdd (robbdd) tree-sitter grammar.
;
; One role per capture, so a token's colour says what it does, not where it sits:
;
;   @keyword           the top-level introducers, plus import/ns
;   @label             slot names: sub-block openers and field keys (`duration`,
;                      `task`, `template`, `variation`)
;   @keyword.operator  the words a clause is written in (`holds`, `is located
;                      at`, `picks`, `before`, `for all`)
;   @type              the kind of thing being declared (`Event`, `Task`, `var`)
;   @variable          every name this file declares
;   @variable.member   every reference to one, inside <>
;   @module            namespace prefixes
;
; Later patterns win in Neovim, so generic captures come first and the scoped
; overrides that must beat them come last.

; ------------------------------------------------------- top-level introducers

"import" @keyword
"ns" @keyword
"User" @keyword
"Story" @keyword
"Scenario" @keyword
"Template" @keyword
"Scenarios" @keyword
"const" @keyword

; ----------------------------------------------------------------- slot names

"As" @label
"A" @label
"I" @label
"Want" @label
"So" @label
"That" @label
"duration" @label
"task" @label
"template" @label
"scene" @label
"variation" @label
"Given" @label
"When" @label
"Then" @label

; ------------------------------------------------------------------ operators

"holds" @keyword.operator
"pred" @keyword.operator
"event" @keyword.operator
"occurs" @keyword.operator
"for" @keyword.operator
"all" @keyword.operator
"in" @keyword.operator
"exists" @keyword.operator
"such" @keyword.operator
"that" @keyword.operator
"and" @keyword.operator
"or" @keyword.operator
"not" @keyword.operator
"before" @keyword.operator
"after" @keyword.operator
"from" @keyword.operator
"until" @keyword.operator
"picks" @keyword.operator
"places" @keyword.operator
"at" @keyword.operator
"is" @keyword.operator
"located" @keyword.operator
"held" @keyword.operator
"by" @keyword.operator
"can" @keyword.operator
"reach" @keyword.operator
"does" @keyword.operator
"drop" @keyword.operator
"collide" @keyword.operator
"has" @keyword.operator
"config" @keyword.operator
"are" @keyword.operator
"sorted" @keyword.operator
"into" @keyword.operator
"select" @keyword.operator
"combinations" @keyword.operator
"permutations" @keyword.operator
"repeated" @keyword.operator
"obj" @keyword.operator
"ws" @keyword.operator
"agn" @keyword.operator
"set" @keyword.operator

"=" @operator

; ---------------------------------------------------------------------- types

"Event" @type
"Task" @type
"Behaviour" @type
(scenario_variable "var" @type)
(scenario_set_variable "set" @type "var" @type)

; ------------------------------------------------------------- declared names

(namespace_decl name: (name) @module)
(event namespace: (fqn) @module)
(task namespace: (fqn) @module)
(behaviour namespace: (fqn) @module)
(explicit_set namespace: (fqn) @module)
(user_story namespace: (fqn) @module)
(scenario_template namespace: (fqn) @module)

(event name: (name) @variable)
(task name: (name) @variable)
(behaviour name: (name) @variable)
(explicit_set name: (name) @variable)
(user_story name: (name) @variable)
(scenario_template name: (name) @variable)
(scenario_variant name: (name) @variable)
(scenario_variable name: (name) @variable)
(scenario_set_variable name: (name) @variable)
(holds_expr name: (name) @variable)
(arg_var_map arg: (name) @variable.parameter)

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

; The variation table draws its own frame.
(variable_header "|" @punctuation.special)
(value_row "|" @punctuation.special)
"---" @punctuation.special

; `var`/`set var` name a variable where they declare it, and point at one where
; the variation assigns it.
(variable_variation_set "var" @label)
(set_variable_variation_set "set" @label "var" @label)


; ============================================== .bddx: how a variant is executed

; ------------------------------------------------------- top-level introducers

"Exec" @keyword
"bhv" @keyword
"impl" @keyword
"obs" @keyword
"policy" @keyword

; ----------------------------------------------------------------- slot names

"variant" @label
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

"linear" @keyword.operator
"distance" @keyword.operator
"between" @keyword.operator
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

; `obs provider` declares one; `provider:` inside an observation names it.
(observation_provider "provider" @keyword)
