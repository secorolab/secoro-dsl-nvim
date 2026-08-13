; Highlights for the scenex (scene-dsl) tree-sitter grammar.
;
; One role per capture, so a token's colour says what it does, not where it sits:
;
;   @keyword           the top-level introducers, plus import/ns
;   @label             slot names: every sub-block opener and every field key
;                      (`joints`, `inertia`, `wrt`, `xyz`, `parent`, `fov`)
;   @keyword.operator  words that relate two things (`of`, `to`, `as`, `map`,
;                      `sample`, `tree`)
;   @type              the kind of thing being declared (`body`, `frame`, `pose`,
;                      `revolute`, `camera`, `mjcf`)
;   @constant          literal values: numbers, units, and closed-vocabulary
;                      words (`PositivePolarity`, `rgbd`, `xyz` axes)
;   @variable          every name this file declares
;   @variable.member   every reference to one, inside <>
;   @variable.parameter the axis slicing a frame reference (`.z`)
;   @module            namespace prefixes
;
; Later patterns win in Neovim, so generic captures come first and the scoped
; overrides that must beat them come last.

; ------------------------------------------------------- top-level introducers

"import" @keyword
"ns" @keyword
"distrib" @keyword
"ktree" @keyword
"kgraph" @keyword
"scene" @keyword
"inst" @keyword
"comp" @keyword
"similar" @keyword
"obj" @keyword
"ws" @keyword
"agn" @keyword
"set" @keyword

"extrinsic" @keyword.modifier

; ----------------------------------------------------------------- slot names

"base" @label
"count" @label
"joints" @label
"inertia" @label
"actuation" @label
"limits" @label
"mimic" @label
"offset" @label
"polarity" @label
"parent" @label
"child" @label
"root" @label
"anchor" @label
"tip" @label
"joint" @label
"multiplier" @label
"gear" @label
"ratio" @label
"command-interface" @label
"state-interface" @label
"mass" @label
"inertia-matrix" @label
"wrt" @label
"xyz" @label
"xyzw" @label
"angles" @label
"axes" @label
"unit" @label
"dimension" @label
"lower" @label
"upper" @label
"mean" @label
"std-dev" @label
"covariance" @label
"resolution" @label
"fov" @label
"update-rate" @label
"observes" @label
"type" @label
"module" @label
"attr" @label
"pkg" @label
"path" @label
"sys" @label
"py" @label

; `frame` opens a declaration, but `frame:` inside an inertia or a sensor is the
; key of a reference; both are the same token, so the block opener wins below.
"frame" @label
"orientation" @label
"position" @label
"velocity" @label
"acceleration" @label
"effort" @label
"name" @label

; ------------------------------------------------------------------ operators

"of" @keyword.operator
"to" @keyword.operator
"as" @keyword.operator
"map" @keyword.operator
"sample" @keyword.operator
"tree" @keyword.operator
"body" @keyword.operator

"=" @operator

; ---------------------------------------------------------------------- types

"object" @type
"workspace" @type
"agent" @type
"model" @type
"camera" @type
"force-torque" @type
"imu" @type
"fixed" @type
"revolute" @type
"serial" @type
"parallel" @type
"uniform" @type
"normal" @type
(uniform_rotation) @type
(orientation_coord_type) @type
(model_kind) @type

(rigid_body "body" @type)
(frame "frame" @type)
(pose_spec "pose" @type)

; ------------------------------------------------------- vocabulary constants

(polarity) @constant
(interface) @constant
(camera_type) @constant
(force_torque_measure) @constant
(imu_measure) @constant
(euler_axes) @constant
(axis) @constant

(length_unit) @constant
(angle_unit) @constant
(angular_velocity_unit) @constant
(angular_acceleration_unit) @constant
(mass_unit) @constant
(inertia_unit) @constant
(effort_unit) @constant
(rate_unit) @constant

; ------------------------------------------------------------- declared names

(namespace_decl name: (name) @module)
(object_set namespace: (fqn) @module)
(similar_object_set namespace: (fqn) @module)
(workspace_set namespace: (fqn) @module)
(agent_set namespace: (fqn) @module)
(similar_agent_set namespace: (fqn) @module)
(workspace_composition namespace: (fqn) @module)
(scene_model namespace: (fqn) @module)
(distribution namespace: (fqn) @module)
(ktree_instance namespace: (fqn) @module)
(ktree_model namespace: (fqn) @module)
(kgraph namespace: (fqn) @module)
(scene_instance namespace: (fqn) @module)

(object_set name: (name) @variable)
(similar_object_set name: (name) @variable)
(workspace_set name: (name) @variable)
(agent_set name: (name) @variable)
(similar_agent_set name: (name) @variable)
(workspace_composition name: (name) @variable)
(scene_model name: (name) @variable)
(distribution name: (name) @variable)
(ktree_template name: (name) @variable)
(ktree_instance name: (name) @variable)
(ktree_model name: (name) @variable)
(kgraph name: (name) @variable)
(scene_instance name: (name) @variable)
(object name: (name) @variable)
(workspace name: (name) @variable)
(agent name: (name) @variable)
(rigid_body name: (name) @variable)
(frame name: (name) @variable)
(pose_spec name: (name) @variable)
(fixed_joint name: (name) @variable)
(revolute_joint name: (name) @variable)
(element_model name: (name) @variable)
(camera_sensor name: (name) @variable)
(force_torque_sensor name: (name) @variable)
(imu_sensor name: (name) @variable)
(similar_object_set base_name: (name) @variable)
(similar_agent_set base_name: (name) @variable)
(py_module_attr attr: (name) @variable)

; ----------------------------------------------------------------- references

"<" @punctuation.special
">" @punctuation.special
(ref path: (fqn) @variable.member)
(py_module_attr module: (fqn) @module)
; The axis on a frame reference is its own role: <f> is the frame, .z is the
; axis of it the joint rotates about.
(frame_axis (axis) @variable.parameter)

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

; The direction-cosine axis keys are field labels, not the axis vocabulary.
(direction_cosine_orientation "x" @label "y" @label "z" @label)

; `scene:` names the abstract scene an instance realizes; the introducer of the
; instance itself is the keyword above.
(scene_ref "scene" @label)
