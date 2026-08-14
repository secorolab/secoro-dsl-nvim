; Each top-level specification is a scope; every named entity inside it is a
; definition, and every <path> is a reference to one.
(context_spec) @local.scope
(exec_context) @local.scope
(guarded_motion) @local.scope
(constraint_handler) @local.scope
(ros) @local.scope

(namespace_decl name: (name) @local.definition.namespace)
(context_spec name: (name) @local.definition.type)
(exec_context name: (name) @local.definition.type)
(guarded_motion name: (name) @local.definition.function)
(constraint_handler name: (name) @local.definition.function)

(world_quantity name: (name) @local.definition.field)
(context_quantity name: (name) @local.definition.field)
(context_path name: (name) @local.definition.field)
(quantity_alias name: (name) @local.definition.field)

(constraint_specification name: (name) @local.definition.field)
(constraint_group name: (name) @local.definition.field)
(goal_status_constraint name: (name) @local.definition.field)
(detect_decl name: (name) @local.definition.field)

(monitor_entry name: (name) @local.definition.field)
(controller_entry name: (name) @local.definition.field)
(controller_alias name: (name) @local.definition.field)
(solver_alias name: (name) @local.definition.field)
(serial_chain_solver name: (name) @local.definition.field)
(mobile_platform_solver name: (name) @local.definition.field)
(command_forwarding_solver name: (name) @local.definition.field)

(ros_topic_decl name: (name) @local.definition.field)
(ros_subscription_decl name: (name) @local.definition.field)
(ros_action_decl name: (name) @local.definition.field)
(ros_action_server_decl name: (name) @local.definition.field)

(ref path: (fqn) @local.reference)
