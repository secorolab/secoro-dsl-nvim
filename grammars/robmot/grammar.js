/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

// Mirrors the textX grammars in motion_spec_dsl/grammars/*.tx (base, model,
// motion_spec, context, path, constraint_handler). Deliberately more permissive
// than textX where being strict would only cost error recovery while editing:
// trailing commas are always allowed and controller parameters are an unordered
// list. Semantic checking is the language server's job.

const list = (rule) => seq(rule, repeat(seq(",", rule)), optional(","))
const optList = (rule) => optional(list(rule))

module.exports = grammar({
  name: "robmot",

  word: ($) => $.name,

  extras: ($) => [/\s+/, $.comment],

  // `snapshot of <q> on event <e>` vs `<q> on <path>`: both continue with `on`,
  // so the choice needs the token after it.
  conflicts: ($) => [[$.quantity_view]],

  rules: {
    source_file: ($) =>
      repeat(choice($.import, $.namespace_decl, $._specification)),

    comment: (_) => token(seq("//", /.*/)),

    _specification: ($) =>
      choice(
        $.context_spec,
        $.exec_context,
        $.tolerances,
        $.ros,
        $.guarded_motion,
        $.constraint_handler,
      ),

    import: ($) => seq("import", field("uri", $.string)),

    namespace_decl: ($) =>
      seq("ns", field("name", $.name), "=", field("uri", $.string)),

    // Every cross-reference in the DSL is written <dotted.path>.
    ref: ($) => seq("<", field("path", $.fqn), ">"),

    fqn: ($) => seq($.name, repeat(seq(".", $.name))),

    _ns_header: ($) => seq("(", "ns", "=", field("namespace", $.fqn), ")"),

    // ---------------------------------------------------------------- model.tx

    // textX fixes the order of these four sections and allows each at most once.
    // Here they are a plain repetition: one state per section instead of one per
    // combination of the ones before it, which the table has no room for.
    ros: ($) => seq("ros", $._ns_header, "{", repeat($._ros_section), "}"),

    _ros_section: ($) =>
      choice(
        $.publishers,
        $.subscribers,
        $.action_clients,
        $.action_servers,
        $.standing_publishers,
      ),

    publishers: ($) =>
      seq("publishers", "{", optList($.ros_topic_decl), "}", optional(",")),

    subscribers: ($) =>
      seq("subscribers", "{", optList($.ros_subscription_decl), "}", optional(",")),

    action_clients: ($) =>
      seq("action-clients", "{", optList($.ros_action_decl), "}", optional(",")),

    action_servers: ($) =>
      seq("action-servers", "{", optList($.ros_action_server_decl), "}", optional(",")),

    standing_publishers: ($) =>
      seq("always", "{", optList($.ros_standing_pub), "}", optional(",")),

    // A publisher that runs for the whole run: an already-declared topic, the
    // quantity its message reports, and any field mapped somewhere else.
    ros_standing_pub: ($) =>
      seq(
        "publish", "at", field("rate", $.measure),
        "to", field("topic", $.ref),
        "with", choice(
          field("quantity", $.ref),
          seq("{", optList($.ros_standing_entry), "}"),
        ),
        optional(seq("{", optList($.ros_measurement_assign), "}")),
      ),

    // One row of a standing message: the scene entity it reports of and the
    // quantity it carries; the subject falls away when the message reports one.
    ros_standing_entry: ($) =>
      seq(optional(seq(field("subject", $.ref), ":")), field("quantity", $.ref)),

    ros_measurement_assign: ($) =>
      seq(
        field("path", $.fqn), ":",
        field("quantity", $.ref), field("selector", $.selector_tail),
      ),

    ros_topic_decl: ($) =>
      seq(
        field("name", $.name), ":", "topic",
        field("channel", $.string), "message", field("type", $.string),
      ),

    ros_subscription_decl: ($) =>
      seq(
        field("name", $.name), ":", "topic",
        field("channel", $.string), "message", field("type", $.string),
        "{",
        "observes", "{", list(field("target", $.ref)), "}",
        field("pose_field", $.name), "from", field("pose_container", $.name),
        optional(","),
        "}",
      ),

    ros_action_decl: ($) =>
      seq(
        field("name", $.name), ":", "action",
        field("channel", $.string), "type", field("type", $.string),
        optional(seq(
          "{",
          field("pose_field", $.name), "from", field("pose_container", $.name),
          optional(","),
          "}",
        )),
      ),

    ros_action_server_decl: ($) =>
      seq(
        field("name", $.name), ":", "action",
        field("channel", $.string), "type", field("type", $.string),
        "{",
        "on-goal", ":", "produce", "event", field("goal_event", $.ref), optional(","),
        "}",
      ),

    ros_field_assign: ($) =>
      seq(field("path", $.fqn), ":", field("value", $._ros_field_value)),

    _ros_field_value: ($) => choice($.number, $.string, $.name),

    tolerances: ($) => seq("tolerances", "{", optList($.tolerance_default), "}"),

    tolerance_default: ($) =>
      seq(field("kind", $._quantity_type), ":", field("band", $._context_ref)),

    exec_context: ($) =>
      seq(
        "exec-context",
        $._ns_header,
        field("name", $.name),
        "{",
        "runs-scene", ":", field("scene", $.ref),
        "platform", ":", field("platform", choice($.real_world_platform, $.simulation_platform)),
        optional(seq("config", ":", field("config", $.string))),
        "timestep", ":", field("timestep", $.measure),
        "}",
      ),

    real_world_platform: ($) =>
      seq("real-world", optional(seq("{", optList($.device_binding), "}"))),

    simulation_platform: ($) => seq("simulation", "{", "name", ":", field("name", $.string), "}"),

    device_binding: ($) =>
      seq(field("target", $.ref), "realized", "by", field("device", $.device_kind)),

    device_kind: (_) =>
      choice("KinovaGen3-2F85", "KinovaGen3", "Robotiq2F85", "RobotiqFT300s"),

    // ---------------------------------------------------------- motion_spec.tx

    context_spec: ($) =>
      seq(
        "context",
        $._ns_header,
        field("name", $.name),
        "{",
        optList($._quantity_context_decl),
        "}",
      ),

    guarded_motion: ($) =>
      seq(
        "guarded-motion",
        $._ns_header,
        field("name", $.name),
        "{",
        optional(seq("description", ":", field("description", $.string))),
        // textX requires the context block and both handler lists below; they are
        // optional here so a half-written buffer keeps highlighting.
        optional(seq("context", "{", optList($._motion_context_item), "}")),
        repeat($.detect_decl),
        repeat($._constraint_section),
        "}",
      ),

    detect_decl: ($) =>
      seq(
        field("name", $.name), ":", "detect",
        choice(seq("{", list(field("target", $.ref)), "}"), field("target", $.ref)),
        "using", field("action", $.ref),
      ),

    _constraint_section: ($) => choice($.when_section, $.while_section, $.until_section),

    when_section: ($) =>
      seq("when", optional(field("logic", $.section_logic)), "{", optList($._constraint_item), "}"),

    while_section: ($) => seq("while", "{", optList($._constraint_item), "}"),

    until_section: ($) =>
      seq("until", optional(field("logic", $.section_logic)), "{", optList($._until_item), "}"),

    section_logic: (_) => choice("any", "all"),

    _until_item: ($) => choice($.constraint_group, $.goal_status_constraint, $._constraint_item),

    constraint_group: ($) =>
      seq(
        field("name", $.name),
        field("logic", $.section_logic),
        "{",
        optList($._until_item),
        "}",
      ),

    goal_status_constraint: ($) =>
      seq(
        field("name", $.name), ":",
        field("act", $.ref), ".", "status",
        "equal", "to", field("status", $.goal_status),
      ),

    goal_status: (_) => choice("succeeded", "aborted", "canceled"),

    // A named item whose view is a bare reference is textX's ConstraintAlias; it
    // is written exactly like a view-only specification, so one rule covers both.
    _constraint_item: ($) => choice($.constraint_specification, $.constraint_alias),

    constraint_alias: ($) => field("reference", $.ref),

    constraint_specification: ($) =>
      seq(
        optional(field("disabled", "@disable")),
        field("name", $.name), ":",
        optional("keeping"),
        field("view", $._view),
        optional(field("expr", $._constraint_relation)),
        optional(seq("within", field("tolerance", $._context_ref))),
      ),

    _motion_context_item: ($) => choice($._quantity_context_decl, $.context_decl_reference),

    context_decl_reference: ($) => $.ref,

    _quantity_context_decl: ($) =>
      choice($.world_context, $.pre_context, $.spec_context, $.post_context),

    world_context: ($) => seq("world", "{", optList($._world_quantity_item), "}"),
    pre_context: ($) => seq("pre", "{", optList($._context_quantity_item), "}"),
    spec_context: ($) => seq("spec", "{", optList($._context_quantity_item), "}"),
    post_context: ($) => seq("post", "{", optList($._context_quantity_item), "}"),

    _world_quantity_item: ($) => choice($.world_quantity, $.quantity_alias),
    _context_quantity_item: ($) =>
      choice($.context_path, $.context_quantity, $.quantity_alias),

    quantity_alias: ($) =>
      seq(optional(seq(field("name", $.name), ":")), field("reference", $.ref)),

    // ------------------------------------------------------------- context.tx

    world_quantity: ($) =>
      seq(
        field("type", $.world_quantity_type),
        field("name", $.name),
        optional(seq("{", $.geometric_props, "}")),
      ),

    world_quantity_type: (_) =>
      choice("velocity-twist", "wrench", "pose", "joint-position"),

    geometric_props: ($) => list($.geo_prop_pair),

    geo_prop_pair: ($) =>
      seq(field("key", $.geo_prop_key), ":", field("value", choice($.ref, $.angle_range))),

    geo_prop_key: (_) =>
      choice("of", "wrt", "ref-point", "as-seen-by", "joint", "ft-sensor", "normalization"),

    // The interval an angle is read or wrapped into. A bound is a number or a
    // multiple of pi, so a turn is written as what it is.
    angle_range: ($) =>
      seq(
        "(", field("lower", $._angle_bound), ",", field("upper", $._angle_bound), ")",
        field("unit", $.unit),
      ),

    _angle_bound: ($) => choice($.pi_term, $.number),

    pi_term: ($) => seq(optional("-"), optional(seq($.number, "*")), "pi"),

    context_path: ($) =>
      seq("path", field("name", $.name), "=", field("value", $._path_spec)),

    context_quantity: ($) =>
      choice(
        seq("velocity-profile", field("name", $.name), "=", field("value", $.profile_spec)),
        seq("admittance", field("name", $.name), "=", field("value", $.admittance_spec)),
        seq(
          field("type", $.geometry_quantity_type),
          field("name", $.name),
          optional(seq("{", $.geometric_props, "}")),
          optional(field("value", $._quantity_assignment)),
        ),
        seq(
          field("type", $.scalar_quantity_type),
          field("name", $.name),
          optional(field("value", $._quantity_assignment)),
        ),
      ),

    geometry_quantity_type: (_) =>
      choice(
        "pose",
        "position",
        "orientation",
        "velocity-twist",
        "acceleration-twist",
        "wrench",
        "angular-velocity",
        "linear-velocity",
        "linear-acceleration",
        "angular-acceleration",
        "linear-jerk",
        "force",
        "torque",
        "direction",
        "free-vector",
      ),

    scalar_quantity_type: (_) =>
      choice(
        "length",
        "distance",
        "angle",
        "dimensionless",
        "duration",
        "path-parameter",
      ),

    _quantity_type: ($) => choice($.geometry_quantity_type, $.scalar_quantity_type),

    _quantity_assignment: ($) =>
      choice(
        $.scalar_value,
        $.vector_value,
        $.snapshot_value,
        $.pose_value,
        $.velocity_twist_value,
        $.acceleration_twist_value,
        $.wrench_value,
        $.config_value,
        $.reference_value,
      ),

    scalar_value: ($) => seq("=", $.measure),

    // A pose the deployment states: `[config.<key>]` is a lookup into robot.toml, kept out of
    // `<>` because that names something declared in the model.
    config_value: ($) =>
      seq(
        "=", "[", "config", ".", field("key", $.fqn), "]",
        "for", field("source", $._view),
      ),

    vector_value: ($) => seq("=", $.coordinates, optional(field("unit", $.unit))),

    reference_value: ($) =>
      seq(
        "=",
        field("source", $.qualified_ref),
        optional(seq(field("sign", choice("+", "-")), field("offset", $._context_ref))),
      ),

    snapshot_value: ($) =>
      seq(
        "=", "snapshot", "of", field("source", $._view),
        optional(seq(field("sign", choice("+", "-")), field("offset", $._context_ref))),
        optional(seq("on", "event", field("trigger", $.ref))),
      ),

    pose_value: ($) =>
      seq(
        "=", "{",
        "position", ":", field("position", $._position_coordinate), ",",
        "orientation", ":", field("orientation", $._orientation_coordinate),
        "}",
      ),

    velocity_twist_value: ($) =>
      seq(
        "=", "{",
        "angular-velocity", ":", field("angular", $.coordinates), field("angular_unit", $.unit), ",",
        "linear-velocity", ":", field("linear", $.coordinates), field("linear_unit", $.unit),
        "}",
      ),

    acceleration_twist_value: ($) =>
      seq(
        "=", "{",
        "angular-acceleration", ":", field("angular", $.coordinates), field("angular_unit", $.unit), ",",
        "linear-acceleration", ":", field("linear", $.coordinates), field("linear_unit", $.unit),
        "}",
      ),

    wrench_value: ($) =>
      seq(
        "=", "{",
        "torque", ":", field("torque", $.coordinates), field("torque_unit", $.unit), ",",
        "force", ":", field("force", $.coordinates), field("force_unit", $.unit),
        "}",
      ),

    _position_coordinate: ($) =>
      choice($._context_ref, seq($.coordinates, field("unit", $.unit))),

    _orientation_coordinate: ($) =>
      choice(
        $.euler_angles,
        $.quaternion,
        $.direction_cosine,
        seq(
          $._context_ref,
          optional(seq(
            "rotated",
            optional(seq("in", field("frame", $.ref))),
            "by",
            choice($.euler_angles, $.quaternion, $.direction_cosine),
          )),
        ),
      ),

    euler_angles: ($) =>
      seq(
        "euler", "{",
        "axes", ":", field("axes", $.euler_axes), optional(field("extrinsic", "extrinsic")), ",",
        "angles", ":", field("angles", $.coordinates), optional(field("unit", $.unit)),
        "}",
      ),

    euler_axes: (_) => choice("xyz", "xzy", "yxz", "yzx", "zxy", "zyx"),

    quaternion: ($) => seq("quat", "{", "xyzw", ":", field("xyzw", $.coordinates), "}"),

    direction_cosine: ($) =>
      seq(
        "direction-cosine", "{",
        "x", ":", field("x", $.coordinates), ",",
        "y", ":", field("y", $.coordinates), ",",
        "z", ":", field("z", $.coordinates),
        "}",
      ),

    coordinates: ($) => seq("(", list($._coordinate_element), ")"),

    _coordinate_element: ($) => choice($.number, $._context_ref),

    admittance_spec: ($) =>
      seq(
        "{",
        "force", ":", field("force", $._view), ",",
        "mass", ":", field("mass", $.number), ",",
        "damping", ":", field("damping", $.number), ",",
        "stiffness", ":", field("stiffness", $.number), ",",
        "max-velocity", ":", field("max_velocity", $.number), optional(field("unit", $.unit)),
        "}",
      ),

    profile_spec: ($) =>
      seq(
        "profile", "{",
        "max-velocity", ":", field("max_velocity", $._context_ref), ",",
        "max-acceleration", ":", field("max_acceleration", $._context_ref),
        optional(seq(",", "measured-velocity", ":", field("measured_velocity", $._view))),
        optional(seq(",", "max-jerk", ":", field("max_jerk", $._context_ref))),
        optional(seq(",", "shape", ":", field("shape", $.profile_shape))),
        "}",
      ),

    profile_shape: (_) => choice("trapezoidal", "s-curve"),

    // Views: what a constraint or controller observes.
    _view: ($) =>
      choice(
        $.distance_view,
        $.elapsed_view,
        $.progress_view,
        $.moving_view,
        $.quantity_view,
      ),

    distance_view: ($) =>
      seq("distance", "between", field("from", $.ref), "and", field("to", $.ref)),

    elapsed_view: (_) => "elapsed",

    progress_view: ($) =>
      seq(
        "progress", "of", field("moved", $.ref),
        "along", field("path", $._context_ref),
      ),

    moving_view: ($) =>
      seq(
        "moving", field("moved", $.ref),
        "along", field("path", $._context_ref),
        "with", field("profile", $._context_ref),
      ),

    // Plain quantity view, optionally observed along a path (textX OnPath).
    quantity_view: ($) =>
      seq(
        field("quantity", $.ref),
        optional($.selector_tail),
        optional(seq("on", field("path", $._context_ref))),
      ),

    selector_tail: ($) =>
      seq(".", field("subspace", $.subspace), optional(seq(".", field("axis", $.axis)))),

    subspace: (_) =>
      choice("angacc", "angvel", "linacc", "linvel", "torque", "force", "orientation", "position"),

    axis: (_) => choice("x", "y", "z"),

    _constraint_relation: ($) =>
      choice(
        $.equality_constraint,
        $.greater_than_constraint,
        $.less_than_constraint,
        $.bilateral_constraint,
        $.outside_constraint,
      ),

    equality_constraint: ($) => seq("equal", "to", field("reference", $._context_ref)),

    greater_than_constraint: ($) =>
      seq(
        choice(seq("greater", "than"), seq("more", "than"), seq("is", "larger", "than"), seq("away", "from")),
        field("threshold", $._context_ref),
      ),

    less_than_constraint: ($) =>
      seq(
        choice(seq("less", "than"), seq("is", "smaller", "than"), seq("up", "to")),
        field("threshold", $._context_ref),
      ),

    bilateral_constraint: ($) =>
      seq("between", field("lower", $._context_ref), "and", field("upper", $._context_ref)),

    outside_constraint: ($) =>
      seq("outside", field("lower", $._context_ref), "and", field("upper", $._context_ref)),

    // References to context quantities, in the two textX ContextRef shapes.
    _context_ref: ($) => choice($.qualified_ref, $.measure),

    qualified_ref: ($) => seq($.ref, optional($.selector_tail)),

    measure: ($) => seq(field("value", $.number), field("unit", $.unit)),

    // ---------------------------------------------------------------- path.tx

    _path_spec: ($) =>
      choice($.lerp_spec, $.circle_spec, $.arc_spec, $.helix_spec, $.figure8_spec),

    lerp_spec: ($) =>
      seq(
        "lerp", "{",
        "start", ":", field("start", $._context_ref), ",",
        "goal", ":", field("goal", $._context_ref),
        "}",
      ),

    circle_spec: ($) =>
      seq(
        "circle", "{",
        "start", ":", field("start", $._context_ref), ",",
        "center", ":", field("center", $._context_ref), ",",
        "plane-normal", ":", field("plane_normal", $._context_ref),
        "}",
      ),

    arc_spec: ($) =>
      seq(
        "arc", "{",
        "start", ":", field("start", $._context_ref), ",",
        "end", ":", field("end", $._context_ref), ",",
        "amplitude", ":", field("amplitude", $._context_ref), ",",
        "plane-normal", ":", field("plane_normal", $._context_ref),
        "}",
      ),

    helix_spec: ($) =>
      seq(
        "helix", "{",
        "start", ":", field("start", $._context_ref), ",",
        "center", ":", field("center", $._context_ref), ",",
        "axis", ":", field("axis", $._context_ref), ",",
        "pitch", ":", field("pitch", $._context_ref), ",",
        "revolutions", ":", field("revolutions", $._context_ref),
        "}",
      ),

    figure8_spec: ($) =>
      seq(
        "figure8", "{",
        "anchor", ":", field("anchor", $._context_ref), ",",
        "radius", ":", field("radius", $._context_ref), ",",
        "plane-normal", ":", field("plane_normal", $._context_ref),
        optional(seq(",", "form", ":", field("form", $.figure8_form))),
        "}",
      ),

    figure8_form: (_) => choice("gerono", "bernoulli"),

    // -------------------------------------------------- constraint_handler.tx

    constraint_handler: ($) =>
      seq(
        "constraint-handler",
        $._ns_header,
        field("name", $.name),
        "{",
        optional(seq("context", "{", optList($._handler_context_item), "}")),
        "handles", ":", field("motion", $.ref),
        optional(seq("runs-in", ":", field("state", $.ref))),
        optional(seq("monitors", "{", optList($.monitor_entry), "}")),
        optional(seq("controllers", "{", optList($._controller_item), "}")),
        optional(seq("solvers", "{", optList($._solver_item), "}")),
        "}",
      ),

    _handler_context_item: ($) =>
      choice($.world_context, $.spec_context, $.context_decl_reference),

    monitor_entry: ($) =>
      seq(
        field("name", $.name), ":", "monitor", field("constraint", $.ref),
        "{", optList($.monitor_state_block), "}",
      ),

    monitor_state_block: ($) =>
      seq(
        field("state", $.monitor_state),
        optional(seq("for", field("sustain", $.measure))),
        "{", optList($._monitor_action), "}",
      ),

    monitor_state: (_) => choice("satisfied", "violated"),

    _monitor_action: ($) =>
      choice(
        $.trigger_action,
        $.hold_action,
        $.flag_action,
        $.publish_action,
        $.result_action,
      ),

    trigger_action: ($) => seq("trigger", ":", "event", field("event", $.ref)),

    hold_action: ($) => seq("hold", ":", field("fallback", $.ref)),

    flag_action: ($) => seq("flag", ":", field("flag", $.name)),

    publish_action: ($) =>
      seq(
        "publish", ":",
        choice(
          seq(
            "events", "{", optList(field("event", $.ref)), "}",
            "to", field("topic", $.ref),
          ),
          seq(
            "to", field("topic", $.ref), "{", optList($.ros_field_assign), "}",
            optional(seq("at", field("rate", $.measure))),
          ),
          seq(
            field("value", $._ros_field_value), "to", field("topic", $.ref),
            optional(seq("at", field("rate", $.measure))),
          ),
        ),
      ),

    // The outcome member of a monitor: where a served goal is answered, and
    // with what status.
    result_action: ($) =>
      seq(
        "result", ":",
        field("outcome", $.goal_status),
        field("server", $.ref),
        "{", optList($.ros_field_assign), "}",
      ),

    _controller_item: ($) => choice($.controller_entry, $.controller_alias),

    controller_alias: ($) =>
      seq(optional(seq(field("name", $.name), ":")), field("reference", $.ref)),

    controller_entry: ($) =>
      seq(
        field("type", $.controller_type),
        field("name", $.name),
        "{", $.controller_params, "}",
        optional(seq("as", field("command_type", $._quantity_type))),
        optional(seq("apply", "at", field("apply_at", $.ref))),
        optional(seq("via", field("solver", $.ref))),
      ),

    controller_type: (_) => choice("pid", "impedance", "feed-forward"),

    // textX fixes the parameter order per controller type; keeping the list
    // unordered here means a half-typed controller still parses.
    controller_params: ($) =>
      seq(
        optional(seq("constraint", ":")),
        field("constraint", $.ref),
        repeat(seq(",", $._controller_param)),
        optional(","),
      ),

    _controller_param: ($) =>
      choice(
        seq("profile", ":", field("profile", $._context_ref)),
        seq("measured-derivative", ":", field("measured_derivative", $._view)),
        seq("output-saturation", ":", field("output_saturation", $.saturation_spec)),
        seq("integral-saturation", ":", field("integral_saturation", $.saturation_spec)),
        seq("error-normalization", ":", field("error_normalization", $.angle_range)),
        $.gain_param,
      ),

    gain_param: ($) => seq(field("name", $.gain_name), ":", field("value", $.number)),

    gain_name: (_) => choice("Kp", "Ki", "Kd", "decay", "stiffness", "damping"),

    saturation_spec: ($) =>
      seq(
        "saturation", "{",
        choice(
          seq("max", ":", field("max", $._context_ref)),
          seq(
            "lower", ":", field("lower", $._context_ref), ",",
            "upper", ":", field("upper", $._context_ref),
          ),
        ),
        "}",
      ),

    _solver_item: ($) =>
      choice(
        $.serial_chain_solver,
        $.mobile_platform_solver,
        $.command_forwarding_solver,
        $.solver_alias,
      ),

    solver_alias: ($) =>
      seq(optional(seq(field("name", $.name), ":")), field("reference", $.ref)),

    serial_chain_solver: ($) =>
      seq(
        field("name", $.name), ":", "serial-chain", "{",
        "agent", ":", field("agent", $.ref),
        optional(seq(",", "algorithm", ":", field("algorithm", $.serial_chain_algorithm))),
        optional(seq(",", $.solver_limits)),
        optional(seq(",", "gravity", ":", field("gravity", $.gravity_value))),
        optional(","),
        "}",
      ),

    serial_chain_algorithm: (_) => choice("achd", "rne"),

    mobile_platform_solver: ($) =>
      seq(
        field("name", $.name), ":", "mobile-platform", "{",
        "agent", ":", field("agent", $.ref), ",",
        "algorithm", ":", field("algorithm", $.mobile_platform_algorithm), ",",
        "configuration", ":", field("configuration", $.string), ",",
        "quantity", ":", field("quantity", $._context_ref),
        optional(","),
        "}",
      ),

    mobile_platform_algorithm: (_) =>
      choice(
        "velocity-composition",
        "velocity-distribution",
        "force-composition",
        "force-distribution",
      ),

    command_forwarding_solver: ($) =>
      seq(
        field("name", $.name), ":", "command-forwarding", "{",
        "agent", ":", field("agent", $.ref),
        optional(","),
        "}",
      ),

    solver_limits: ($) => seq("limits", "{", list($.torque_limit), "}"),

    torque_limit: ($) => seq("torque", ":", field("saturation", $.saturation_spec)),

    gravity_value: ($) =>
      choice(
        seq(optional("="), $.coordinates, field("unit", $.unit)),
        $._context_ref,
      ),

    // ------------------------------------------------------------------ atoms

    // textX IRI_TRUNK: starts with a letter or _, may contain inner hyphens.
    name: (_) => token(/[A-Za-z_][A-Za-z0-9_]*(-[A-Za-z0-9_]+)*/),

    // Either quote style, with backslash escapes.
    string: (_) =>
      token(
        choice(
          seq('"', /[^"\\]*(\\.[^"\\]*)*/, '"'),
          seq("'", /[^'\\]*(\\.[^'\\]*)*/, "'"),
        ),
      ),

    number: (_) => token(/[-+]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)(?:[eE][-+]?[0-9]+)?/),

    unit: (_) =>
      token(
        prec(1, choice(
          "rad/s^2", "deg/s^2", "m/s^2", "m/s^3",
          "rad/s", "deg/s", "m/s", "cm/s",
          "mm", "cm", "m", "rad", "deg", "Nm", "N", "ms", "s", "Hz",
        )),
      ),
  },
})
