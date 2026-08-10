/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

// Mirrors the textX grammars in scene_dsl/grammars/*.tx (base, scene, scenex,
// ktree, geom, distrib, sensors). One grammar covers all three file kinds:
// `.scene` holds the abstract sets, `.scenex` the instances, `.ktree` a device
// tree, and their top-level constructs are disjoint, so a union grammar parses
// each one without ever accepting the other's constructs mid-block. Which
// metamodel a file is checked against stays the language server's job.
//
// Deliberately looser than textX where being strict would only cost error
// recovery while editing: trailing commas everywhere, optional joints, and
// unordered pose/joint sub-blocks.

const commaSep1 = (rule) => seq(rule, repeat(seq(",", rule)), optional(","))
const commaSep = (rule) => optional(commaSep1(rule))

module.exports = grammar({
  name: "scenex",

  word: ($) => $.name,

  extras: ($) => [/\s+/, $.comment],

  rules: {
    source_file: ($) =>
      repeat(choice($.import, $.namespace_decl, $._declaration)),

    comment: (_) => token(seq("//", /.*/)),

    _declaration: ($) =>
      choice(
        // scene.tx
        $.object_set,
        $.similar_object_set,
        $.workspace_set,
        $.agent_set,
        $.similar_agent_set,
        $.workspace_composition,
        $.scene_model,
        // scenex.tx
        $.distribution,
        $.ktree_template,
        $.ktree_instance,
        $.ktree_model,
        $.scene_instance,
      ),

    import: ($) => seq("import", field("uri", $.string)),

    namespace_decl: ($) =>
      seq("ns", field("name", $.name), "=", field("uri", $.string)),

    // Every cross-reference in the DSL is written <dotted.path>.
    ref: ($) => seq("<", field("path", $.fqn), ">"),

    fqn: ($) => seq($.name, repeat(seq(".", $.name))),

    _ns_header: ($) => seq("(", "ns", "=", field("namespace", $.fqn), ")"),

    vector: ($) => seq("(", commaSep($.number), ")"),

    matrix: ($) => seq("(", commaSep1($.vector), ")"),

    // --------------------------------------------------------------- scene.tx

    object_set: ($) =>
      seq("obj", "set", $._ns_header, field("name", $.name), "{", commaSep($.object), "}"),

    workspace_set: ($) =>
      seq("ws", "set", $._ns_header, field("name", $.name), "{", commaSep($.workspace), "}"),

    agent_set: ($) =>
      seq("agn", "set", $._ns_header, field("name", $.name), "{", commaSep($.agent), "}"),

    object: ($) => seq("object", field("name", $.name)),
    workspace: ($) => seq("workspace", field("name", $.name)),
    agent: ($) => seq("agent", field("name", $.name)),

    similar_object_set: ($) =>
      seq("similar", "obj", "set", $._ns_header, field("name", $.name), $._similar_body),

    similar_agent_set: ($) =>
      seq("similar", "agn", "set", $._ns_header, field("name", $.name), $._similar_body),

    _similar_body: ($) =>
      seq(
        "{",
        "base", "name", ":", field("base_name", $.name), optional(","),
        "count", ":", field("count", $.number), optional(","),
        "}",
      ),

    workspace_composition: ($) =>
      seq(
        "comp",
        $._ns_header,
        field("name", $.name),
        "of", "ws", field("workspace", $.ref),
        "{",
        repeat(choice($.object_member, $.workspace_member, $.ws_comp_member)),
        "}",
      ),

    object_member: ($) => seq("obj", field("target", $.ref)),
    workspace_member: ($) => seq("ws", field("target", $.ref)),
    ws_comp_member: ($) => seq("ws", "comp", field("target", $.ref)),

    scene_model: ($) =>
      seq(
        "scene",
        $._ns_header,
        field("name", $.name),
        "{",
        repeat(
          choice(
            $.obj_set_member,
            $.ws_set_member,
            $.ws_comp_member,
            $.agn_set_member,
          ),
        ),
        "}",
      ),

    obj_set_member: ($) => seq("obj", "set", field("target", $.ref)),
    ws_set_member: ($) => seq("ws", "set", field("target", $.ref)),
    agn_set_member: ($) => seq("agn", "set", field("target", $.ref)),

    // ------------------------------------------------------------- distrib.tx

    distribution: ($) =>
      seq(
        "distrib",
        $._ns_header,
        field("name", $.name),
        "{",
        field("spec", $._distribution_spec),
        "}",
      ),

    _distribution_spec: ($) =>
      choice($.uniform_distribution, $.normal_distribution, $.uniform_rotation),

    uniform_distribution: ($) =>
      seq(
        "uniform",
        "{",
        "dimension", ":", field("dimension", $.number),
        "lower", ":", field("lower", $.vector),
        "upper", ":", field("upper", $.vector),
        "}",
      ),

    normal_distribution: ($) =>
      seq(
        "normal",
        "{",
        "dimension", ":", field("dimension", $.number),
        "mean", ":", field("mean", choice($.number, $.vector)),
        choice(
          seq("std-dev", ":", field("std_dev", $.number)),
          seq("covariance", ":", field("covariance", $.matrix)),
        ),
        "}",
      ),

    uniform_rotation: (_) => "uniform-rotation",

    distribution_ref: ($) => seq("sample", field("distribution", $.ref)),

    // ---------------------------------------------------------------- geom.tx

    frame: ($) => seq("frame", field("name", $.name), "{", repeat($.pose_spec), "}"),

    frame_axis: ($) => seq(field("frame", $.ref), ".", field("axis", $.axis)),

    axis: (_) => choice("x", "y", "z"),

    pose_spec: ($) =>
      seq(
        "pose",
        field("name", $.name),
        "{",
        optional(seq("wrt", ":", field("wrt", $.ref))),
        "xyz", ":", field("position", choice($.vector, $.distribution_ref)),
        field("length_unit", $.length_unit),
        "orientation", ":", field("orientation", $.orientation_coord),
        "}",
      ),

    orientation_coord: ($) =>
      seq(
        field("coord_type", $.orientation_coord_type),
        "{",
        field("spec", $._orientation_spec),
        "}",
      ),

    orientation_coord_type: (_) => choice("quat", "euler", "direction-cosine"),

    _orientation_spec: ($) =>
      choice(
        $.quaternion_orientation,
        $.euler_orientation,
        $.direction_cosine_orientation,
        $.distribution_ref,
      ),

    quaternion_orientation: ($) => seq("xyzw", ":", field("xyzw", $.vector)),

    euler_orientation: ($) =>
      seq(
        optional(seq("axes", ":", field("axes", $.euler_axes))),
        optional("extrinsic"),
        "angles", ":", field("angles", $.vector),
        optional(seq("unit", ":", field("unit", $.angle_unit))),
      ),

    euler_axes: (_) => choice("xyz", "xzy", "yxz", "yzx", "zxy", "zyx"),

    direction_cosine_orientation: ($) =>
      seq(
        "x", ":", field("x_axis", $.vector),
        "y", ":", field("y_axis", $.vector),
        "z", ":", field("z_axis", $.vector),
      ),

    // --------------------------------------------------------------- ktree.tx

    kgraph: ($) =>
      seq(
        "kgraph",
        $._ns_header,
        field("name", $.name),
        "{",
        repeat($.tree_member),
        repeat($.rigid_body),
        optional($.joints_spec),
        "}",
      ),

    // A tree with no namespace is a template: it describes a device without
    // being any particular one.
    ktree_template: ($) =>
      seq(
        "ktree",
        field("name", $.name),
        "{",
        repeat($.rigid_body),
        optional($.joints_spec),
        "}",
      ),

    ktree_instance: ($) =>
      seq(
        "ktree", "inst",
        $._ns_header,
        field("name", $.name),
        "of", field("template", $.ref),
      ),

    ktree_model: ($) =>
      seq(
        "ktree",
        $._ns_header,
        field("name", $.name),
        "{",
        repeat($.tree_member),
        repeat($.rigid_body),
        optional($.joints_spec),
        "}",
      ),

    tree_member: ($) => seq("tree", field("target", $.ref)),

    rigid_body: ($) =>
      seq(
        "body",
        field("name", $.name),
        "{",
        repeat($.frame),
        optional($.inertia),
        "}",
      ),

    inertia: ($) =>
      seq(
        "inertia",
        "{",
        "frame", ":", field("frame", $.ref),
        optional(seq("mass", ":", field("mass", $.number), field("mass_unit", $.mass_unit))),
        optional(
          seq(
            "inertia-matrix", ":",
            field("inertia_matrix", $.matrix),
            field("inertia_unit", $.inertia_unit),
          ),
        ),
        "}",
      ),

    joints_spec: ($) =>
      seq(
        "joints",
        "{",
        repeat(choice($.fixed_joint, $.revolute_joint)),
        optional(choice($.serial_joints, $.parallel_joints)),
        "}",
      ),

    fixed_joint: ($) =>
      seq(
        "fixed",
        field("name", $.name),
        "{",
        "parent", ":", field("parent", $.ref),
        "child", ":", field("child", $.ref),
        "}",
      ),

    revolute_joint: ($) =>
      seq(
        "revolute",
        field("name", $.name),
        "{",
        "parent", ":", field("parent", $.frame_axis),
        "child", ":", field("child", $.frame_axis),
        // textX fixes this order; keeping it loose only costs error recovery.
        repeat(
          choice(
            $.actuation,
            $.joint_offset,
            $.joint_limits,
            $.joint_mimic,
            seq("polarity", ":", field("polarity", $.polarity)),
          ),
        ),
        "}",
      ),

    polarity: (_) => choice("PositivePolarity", "NegativePolarity"),

    joint_offset: ($) =>
      seq(
        "offset",
        "{",
        "xyz", ":", field("xyz", $.vector), field("length_unit", $.length_unit),
        "}",
      ),

    joint_limits: ($) =>
      seq(
        "limits",
        "{",
        repeat(
          choice(
            seq("position", ":", field("position", $.vector), field("position_unit", $.angle_unit)),
            seq("velocity", ":", field("velocity", $.vector), field("velocity_unit", $.angular_velocity_unit)),
            seq("acceleration", ":", field("acceleration", $.vector), field("acceleration_unit", $.angular_acceleration_unit)),
            seq("effort", ":", field("effort", $.vector), field("effort_unit", $.effort_unit)),
          ),
        ),
        "}",
      ),

    joint_mimic: ($) =>
      seq(
        "mimic",
        "{",
        "joint", ":", field("joint", $.ref),
        "multiplier", ":", field("multiplier", $.number),
        "offset", ":", field("offset", $.number),
        "}",
      ),

    actuation: ($) =>
      seq(
        "actuation",
        "{",
        "gear", "ratio", ":", field("gear_ratio", $.number),
        "command-interface", ":", repeat1(field("command_interface", $.interface)),
        "state-interface", ":", repeat1(field("state_interface", $.interface)),
        "}",
      ),

    interface: (_) => choice("position", "velocity", "torque", "current"),

    serial_joints: ($) =>
      seq(
        "serial",
        "{",
        "root", ":", field("root", $.ref),
        "tip", ":", field("tip", $.ref),
        "}",
      ),

    parallel_joints: (_) => seq("parallel", "{", "}"),

    // ------------------------------------------------------------- sensors.tx

    _sensor: ($) => choice($.camera_sensor, $.force_torque_sensor, $.imu_sensor),

    camera_sensor: ($) =>
      seq(
        "camera",
        field("name", $.name),
        "{",
        "frame", ":", field("frame", $.ref),
        "type", ":", field("camera_type", $.camera_type),
        "resolution", ":", field("resolution", $.vector),
        "fov", ":", field("fov", $.number), field("fov_unit", $.angle_unit),
        $._update_rate,
        "}",
      ),

    camera_type: (_) => choice("rgb", "depth", "rgbd"),

    force_torque_sensor: ($) =>
      seq(
        "force-torque",
        field("name", $.name),
        "{",
        "frame", ":", field("frame", $.ref),
        "observes", ":", repeat1(field("observes", $.force_torque_measure)),
        $._update_rate,
        "}",
      ),

    force_torque_measure: (_) => choice("force", "torque"),

    imu_sensor: ($) =>
      seq(
        "imu",
        field("name", $.name),
        "{",
        "frame", ":", field("frame", $.ref),
        "observes", ":", repeat1(field("observes", $.imu_measure)),
        $._update_rate,
        "}",
      ),

    imu_measure: (_) => choice("angular-velocity", "linear-acceleration", "orientation"),

    _update_rate: ($) =>
      seq("update-rate", ":", field("update_rate", $.number), field("rate_unit", $.rate_unit)),

    // -------------------------------------------------------------- scenex.tx

    scene_instance: ($) =>
      seq(
        "scene", "inst",
        $._ns_header,
        field("name", $.name),
        "{",
        $.scene_ref,
        optional($.kgraph),
        repeat($.element_model),
        repeat(
          choice(
            $.modelled_object,
            $.modelled_object_set,
            $.modelled_agent,
            $.modelled_agent_set,
          ),
        ),
        "}",
      ),

    // The abstract scene this instance realizes. Its own rule, so the key reads
    // as a slot and the introducer above stays a keyword.
    scene_ref: ($) => seq("scene", ":", field("scene", $.ref)),

    element_model: ($) =>
      seq(
        "model",
        field("name", $.name),
        optional(seq("as", field("kind", $.model_kind))),
        "{",
        field("spec", $._model_spec),
        repeat(choice($.tree_mapping, $.body_mapping)),
        "}",
      ),

    model_kind: (_) => choice("urdf", "mjcf", "usd"),

    _model_spec: ($) => choice($.sys_path, $.ros_path, $.py_module_attr),

    sys_path: ($) => seq("sys", "path", "=", field("path", $.string)),

    ros_path: ($) =>
      seq("ros", "pkg", "=", field("pkg", $.string), ",", "path", "=", field("path", $.string)),

    py_module_attr: ($) =>
      seq(
        "py",
        "{",
        "module", ":", field("module", $.fqn), ",",
        "attr", ":", field("attr", $.name),
        "}",
      ),

    tree_mapping: ($) =>
      seq("map", "tree", field("tree", $.ref), optional(seq("to", field("entity", $.string)))),

    body_mapping: ($) =>
      seq("map", "body", field("body", $.ref), optional(seq("to", field("entity", $.string)))),

    modelled_object: ($) =>
      seq("obj", field("target", $.ref), "{", repeat1($.element_model), "}"),

    modelled_object_set: ($) =>
      seq("obj", "set", field("target", $.ref), "{", repeat1($.element_model), "}"),

    modelled_agent: ($) =>
      seq(
        "agn",
        field("target", $.ref),
        "{",
        repeat($.element_model),
        repeat($._sensor),
        "}",
      ),

    modelled_agent_set: ($) =>
      seq("agn", "set", field("target", $.ref), "{", repeat1($.modelled_agent), "}"),

    // --------------------------------------------------------------- terminals

    length_unit: (_) => choice("mm", "cm", "m"),
    angle_unit: (_) => choice("rad", "deg"),
    angular_velocity_unit: (_) => choice("rad/s", "deg/s"),
    angular_acceleration_unit: (_) => choice("rad/s^2", "deg/s^2"),
    mass_unit: (_) => choice("kg", "g"),
    inertia_unit: (_) => "kg*m^2",
    effort_unit: (_) => "N*m",
    rate_unit: (_) => "Hz",

    // textX IRI_TRUNK: a word that does not start with a digit, hyphens allowed.
    name: (_) => /[A-Za-z_][A-Za-z0-9_-]*/,

    number: (_) => token(seq(optional(/[-+]/), choice(/\d+(\.\d*)?([eE][-+]?\d+)?/, /\.\d+([eE][-+]?\d+)?/))),

    // Either quote style, with backslash escapes.
    string: (_) =>
      token(
        choice(
          seq('"', /[^"\\]*(\\.[^"\\]*)*/, '"'),
          seq("'", /[^'\\]*(\\.[^'\\]*)*/, "'"),
        ),
      ),
  },
})
