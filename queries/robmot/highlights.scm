; Highlights for the robmot (motion-spec-dsl) tree-sitter grammar.
;
; One role per capture, so a token's colour says what it does, not where it sits:
;
;   @keyword           the top-level introducers, plus import/ns
;   @label             slot names: every sub-block opener and every field key
;                      (`world`, `while`, `monitors`, `runs-scene`, `of`, `Kp`)
;   @keyword.operator  relation, view and action words (`equal to`, `snapshot`, `publish`)
;   @type              the kind of thing being declared (`pose`, `pid`, `serial-chain`)
;   @constant         literal values: numbers, units, and closed-vocabulary
;                      words (`achd`, `succeeded`, `KinovaGen3`)
;   @variable          every name this file declares
;   @variable.member   every reference to one, inside <> or []
;   @variable.parameter the selector slicing a reference (`.linvel.z`)
;   @string            strings
;
; Later patterns win in Neovim, so generic captures come first and the scoped
; overrides that must beat them come last.

; ------------------------------------------------------- top-level introducers

"import" @keyword
"ns" @keyword
"exec-context" @keyword
"tolerances" @keyword
"ros" @keyword
"guarded-motion" @keyword
"constraint-handler" @keyword

"@disable" @keyword.modifier
"extrinsic" @keyword.modifier
(section_logic) @keyword.modifier

; ----------------------------------------------------------------- slot names

"context" @label
"description" @label
"world" @label
"pre" @label
"spec" @label
"post" @label
"when" @label
"while" @label
"until" @label
"handles" @label
"runs-in" @label
"monitors" @label
"controllers" @label
"solvers" @label
"publishers" @label
"subscribers" @label
"action-clients" @label
"action-servers" @label

"type" @label
"name" @label
"platform" @label
"config" @label
"timestep" @label
"runs-scene" @label
"agent" @label
"algorithm" @label
"configuration" @label
"quantity" @label
"gravity" @label
"constraint" @label
"profile" @label
"measured-derivative" @label
"measured-velocity" @label
"output-saturation" @label
"integral-saturation" @label
"max" @label
"lower" @label
"upper" @label
"mass" @label
"damping" @label
"stiffness" @label
"max-velocity" @label
"max-acceleration" @label
"max-jerk" @label
"shape" @label
"start" @label
"end" @label
"goal" @label
"center" @label
"axes" @label
"angles" @label
"xyzw" @label
"pitch" @label
"revolutions" @label
"amplitude" @label
"anchor" @label
"radius" @label
"plane-normal" @label
"form" @label
"on-goal" @label
"on-end" @label

(geo_prop_key) @label
(gain_name) @label
(monitor_state) @label

; Keys whose spelling is also a quantity type or a subspace selector: only the
; ones inside a coordinate literal are field labels.
(pose_value "position" @label "orientation" @label)
(wrench_value "torque" @label "force" @label)
(admittance_spec "force" @label)
(velocity_twist_value "angular-velocity" @label "linear-velocity" @label)
(acceleration_twist_value "angular-acceleration" @label "linear-acceleration" @label)
(helix_spec "axis" @label)

; ------------------------------------------------------------------ operators

"keeping" @keyword.operator
"equal" @keyword.operator
"to" @keyword.operator
"greater" @keyword.operator
"more" @keyword.operator
"less" @keyword.operator
"than" @keyword.operator
"is" @keyword.operator
"larger" @keyword.operator
"smaller" @keyword.operator
"up" @keyword.operator
"away" @keyword.operator
"from" @keyword.operator
"between" @keyword.operator
"outside" @keyword.operator
"and" @keyword.operator
"within" @keyword.operator
"distance" @keyword.operator
(elapsed_view) @keyword.operator
"progress" @keyword.operator
"moving" @keyword.operator
"along" @keyword.operator
"at" @keyword.operator
"on" @keyword.operator
"in" @keyword.operator
"by" @keyword.operator
"snapshot" @keyword.operator
"rotated" @keyword.operator
"using" @keyword.operator
"as" @keyword.operator
"via" @keyword.operator
"apply" @keyword.operator
"for" @keyword.operator
"realized" @keyword.operator
"produce" @keyword.operator
"detect" @keyword.operator
"monitor" @keyword.operator
"trigger" @keyword.operator
"hold" @keyword.operator
"flag" @keyword.operator
"publish" @keyword.operator
"event" @keyword.operator
"topic" @keyword.operator
"message" @keyword.operator
"action" @keyword.operator
"observes" @keyword.operator
"from" @keyword.operator
"saturation" @keyword.operator
"limits" @keyword.operator

; `of` is a geometric property key everywhere except these two views.
(snapshot_value "of" @keyword.operator)
(progress_view "of" @keyword.operator)

"=" @operator
"+" @operator

; ---------------------------------------------------------------------- types

(world_quantity_type) @type
(geometry_quantity_type) @type
(scalar_quantity_type) @type
(controller_type) @type
"velocity-profile" @type
"admittance" @type
"path" @type
"serial-chain" @type
"mobile-platform" @type
"command-forwarding" @type
"real-world" @type
"simulation" @type
"lerp" @type
"circle" @type
"arc" @type
"helix" @type
"figure8" @type
"euler" @type
"quat" @type
"direction-cosine" @type
(profile_spec "profile" @type)

; ------------------------------------------------------- vocabulary constants

(device_kind) @constant
(serial_chain_algorithm) @constant
(mobile_platform_algorithm) @constant
(profile_shape) @constant
(figure8_form) @constant
(euler_axes) @constant
(goal_status) @constant
(context_scope) @constant
(ros_field_assign value: (name) @constant)
(publish_action value: (name) @constant)

; ------------------------------------------------------------- declared names

(namespace_decl name: (name) @module)
(exec_context namespace: (fqn) @module)
(context_spec namespace: (fqn) @module)
(ros namespace: (fqn) @module)
(guarded_motion namespace: (fqn) @module)
(constraint_handler namespace: (fqn) @module)

(exec_context name: (name) @variable)
(context_spec name: (name) @variable)
(guarded_motion name: (name) @variable)
(constraint_handler name: (name) @variable)
(world_quantity name: (name) @variable)
(context_quantity name: (name) @variable)
(context_path name: (name) @variable)
(quantity_alias name: (name) @variable)
(constraint_specification name: (name) @variable)
(constraint_group name: (name) @variable)
(goal_status_constraint name: (name) @variable)
(detect_decl name: (name) @variable)
(monitor_entry name: (name) @variable)
(controller_entry name: (name) @variable)
(controller_alias name: (name) @variable)
(solver_alias name: (name) @variable)
(serial_chain_solver name: (name) @variable)
(mobile_platform_solver name: (name) @variable)
(command_forwarding_solver name: (name) @variable)
(ros_topic_decl name: (name) @variable)
(ros_action_decl name: (name) @variable)
(ros_action_server_decl name: (name) @variable)
(flag_action flag: (name) @variable)
(ros_action_decl pose_field: (name) @variable pose_container: (name) @variable)
(ros_subscription_decl name: (name) @variable)
(ros_subscription_decl pose_field: (name) @variable pose_container: (name) @variable)

; ----------------------------------------------------------------- references

"<" @punctuation.special
">" @punctuation.special
(ref path: (fqn) @variable.member)
(bracket_ref path: (fqn) @variable.member)
(ros_field_assign path: (fqn) @variable.member)
; The selector on a reference is its own role: <q> is the thing, .linvel.z is
; the slice of it being constrained.
(selector_tail (subspace) @variable.parameter)
(selector_tail (axis) @variable.parameter)

; ------------------------------------------------------------------- literals

(comment) @comment @spell
(string) @string
(number) @number
(unit) @constant

; ---------------------------------------------------------------- punctuation

"{" @punctuation.bracket
"}" @punctuation.bracket
"[" @punctuation.bracket
"]" @punctuation.bracket
"(" @punctuation.bracket
")" @punctuation.bracket
"," @punctuation.delimiter
":" @punctuation.delimiter
"." @punctuation.delimiter

; `context` opens a slot inside a motion or handler, but introduces a spec of
; its own at the top level.
(context_spec "context" @keyword)
