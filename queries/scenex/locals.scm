; Each top-level declaration is a scope; every named entity inside it is a
; definition, and every <path> is a reference to one.
(object_set) @local.scope
(similar_object_set) @local.scope
(workspace_set) @local.scope
(agent_set) @local.scope
(similar_agent_set) @local.scope
(workspace_composition) @local.scope
(scene_model) @local.scope
(distribution) @local.scope
(ktree_template) @local.scope
(ktree_model) @local.scope
(scene_instance) @local.scope
(kgraph) @local.scope
(rigid_body) @local.scope

(namespace_decl name: (name) @local.definition.namespace)

(object_set name: (name) @local.definition.type)
(similar_object_set name: (name) @local.definition.type)
(workspace_set name: (name) @local.definition.type)
(agent_set name: (name) @local.definition.type)
(similar_agent_set name: (name) @local.definition.type)
(workspace_composition name: (name) @local.definition.type)
(scene_model name: (name) @local.definition.type)
(distribution name: (name) @local.definition.type)
(ktree_template name: (name) @local.definition.type)
(ktree_instance name: (name) @local.definition.type)
(ktree_model name: (name) @local.definition.type)
(kgraph name: (name) @local.definition.type)
(scene_instance name: (name) @local.definition.type)

(object name: (name) @local.definition.field)
(workspace name: (name) @local.definition.field)
(agent name: (name) @local.definition.field)
(rigid_body name: (name) @local.definition.field)
(frame name: (name) @local.definition.field)
(pose_spec name: (name) @local.definition.field)
(fixed_joint name: (name) @local.definition.field)
(revolute_joint name: (name) @local.definition.field)
(element_model name: (name) @local.definition.field)
(camera_sensor name: (name) @local.definition.field)
(force_torque_sensor name: (name) @local.definition.field)
(imu_sensor name: (name) @local.definition.field)

(ref path: (fqn) @local.reference)
