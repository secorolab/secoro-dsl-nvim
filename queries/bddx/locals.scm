; A policy is a scope: its observations are named there and referenced by the
; distance constraint below them.
(observation_policy) @local.scope

(namespace_decl name: (name) @local.definition.namespace)
(behaviour_implementation name: (name) @local.definition.type)
(observation_provider name: (name) @local.definition.type)
(observation_policy name: (name) @local.definition.type)
(scenario_execution name: (name) @local.definition.type)
(observation name: (name) @local.definition.field)

(ref path: (fqn) @local.reference)
