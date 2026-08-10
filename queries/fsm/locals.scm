; The event loop and the FSM are each a scope; every named entity inside one is
; a definition, and every <path> is a reference to one.
(event_loop) @local.scope
(fsm) @local.scope

(namespace_decl name: (name) @local.definition.namespace)
(event_loop name: (name) @local.definition.type)
(fsm name: (name) @local.definition.type)

(event name: (name) @local.definition.field)
(state name: (name) @local.definition.field)
(transition name: (name) @local.definition.field)
(reaction name: (name) @local.definition.field)

(ref path: (fqn) @local.reference)
