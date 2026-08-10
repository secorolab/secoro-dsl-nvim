; A template and a story are each a scope; every named entity inside one is a
; definition, and every <path> is a reference to one.
(scenario_template) @local.scope
(user_story) @local.scope
(scenario_variant) @local.scope
(forall_expr) @local.scope
(exists_expr) @local.scope

(namespace_decl name: (name) @local.definition.namespace)
(event name: (name) @local.definition.type)
(task name: (name) @local.definition.type)
(behaviour name: (name) @local.definition.type)
(explicit_set name: (name) @local.definition.type)
(scenario_template name: (name) @local.definition.type)
(user_story name: (name) @local.definition.type)

(scenario_variant name: (name) @local.definition.field)
(scenario_variable name: (name) @local.definition.var)
(scenario_set_variable name: (name) @local.definition.var)
(holds_expr name: (name) @local.definition.field)
(arg_var_map arg: (name) @local.definition.parameter)

(ref path: (fqn) @local.reference)


; .bddx: how a variant is executed.
(observation_policy) @local.scope

(behaviour_implementation name: (name) @local.definition.type)
(observation_provider name: (name) @local.definition.type)
(observation_policy name: (name) @local.definition.type)
(scenario_execution name: (name) @local.definition.type)
(observation name: (name) @local.definition.field)

(ref path: (fqn) @local.reference)
