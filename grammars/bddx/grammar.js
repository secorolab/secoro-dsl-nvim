/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

// Mirrors the textX grammar in robbdd/grammars/bddx.tx: how a scenario variant
// is executed -- which behaviour implements it, and which observations decide
// whether its fluents held.
//
// The `.bdd` fluents and the `.scenex` scene instance it references belong to
// the other two languages; textX links them in by registration, and here they
// are plain references like any other.

const commaSep1 = (rule) => seq(rule, repeat(seq(",", rule)), optional(","))

module.exports = grammar({
  name: "bddx",

  word: ($) => $.name,

  extras: ($) => [/\s+/, $.comment],

  rules: {
    source_file: ($) =>
      repeat(
        choice(
          $.import,
          $.namespace_decl,
          $.behaviour_implementation,
          $.observation_policy,
          $.observation_provider,
          $.scenario_execution,
        ),
      ),

    comment: (_) => token(seq("//", /.*/)),

    import: ($) => seq("import", field("uri", $.string)),

    namespace_decl: ($) =>
      seq("ns", field("name", $.name), "=", field("uri", $.string)),

    ref: ($) => seq("<", field("path", $.fqn), ">"),

    fqn: ($) => seq($.name, repeat(seq(".", $.name))),

    _ns_header: ($) => seq("(", "ns", "=", field("namespace", $.fqn), ")"),

    // ------------------------------------------------------------- execution

    scenario_execution: ($) =>
      seq(
        "Scenario", "Exec",
        $._ns_header,
        field("name", $.name),
        "{",
        "variant", ":", field("variant", $.ref),
        "scene", "inst", ":", field("scene_inst", $.ref),
        "bhv", ":", field("bhv_impl", $.ref),
        "policies", ":", "{", commaSep1(field("policy", $.ref)), "}",
        "}",
      ),

    behaviour_implementation: ($) =>
      seq(
        "bhv", "impl",
        $._ns_header,
        field("name", $.name),
        "{",
        field("spec", choice($.ros_bhv_action, $.py_module_attr)),
        "}",
      ),

    ros_bhv_action: ($) => seq("bhv", "action", ":", field("action", $.string)),

    // ------------------------------------------------------------ observation

    observation_provider: ($) =>
      seq(
        "obs", "provider",
        $._ns_header,
        field("name", $.name),
        "{",
        field("spec", choice($.ros_topic_provider, $.simulation_entity_state_provider)),
        "}",
      ),

    ros_topic_provider: ($) =>
      seq(
        "ros", "topic", ":", field("topic", $.string),
        "type", ":", field("type", $.string),
      ),

    simulation_entity_state_provider: ($) =>
      seq(
        "ros", "simulation", "entity", "state",
        "update-rate", ":", field("update_rate", $.number), "Hz",
      ),

    observation_policy: ($) =>
      seq(
        "obs", "policy",
        $._ns_header,
        field("name", $.name),
        "for", field("fluent", $.ref),
        optional(seq("horizon", ":", field("horizon", $.horizon_seconds))),
        "{",
        repeat($.observation),
        field("spec", $._policy_spec),
        "}",
      ),

    horizon_seconds: ($) => seq(field("value", $.number), "seconds"),

    observation: ($) =>
      seq(
        "observation",
        field("name", $.name),
        "{",
        "provider", ":", field("provider", $.ref),
        optional(seq("observes", ":", field("target", $.ref))),
        "}",
      ),

    _policy_spec: ($) =>
      choice($.ros_trinary_topic, $.linear_distance_observation, $.py_module_attr),

    ros_trinary_topic: ($) => seq("trinary", "topic", ":", field("topic", $.string)),

    linear_distance_observation: ($) =>
      seq(
        "linear", "distance", "between", field("left", $.ref),
        "and", field("right", $.ref),
        "{",
        field("constraint", $.distance_constraint),
        "}",
      ),

    distance_constraint: ($) =>
      choice(
        seq("less-than", ":", field("less_than", $.distance_value)),
        seq("greater-than", ":", field("greater_than", $.distance_value)),
        seq(
          "between", ":", field("lower", $.distance_value),
          "and", field("upper", $.distance_value),
        ),
        seq(
          "equals", ":", field("equals", $.distance_value),
          "tolerance", ":", field("tolerance", $.distance_value),
        ),
      ),

    distance_value: ($) => seq(field("value", $.number), field("unit", $.length_unit)),

    length_unit: (_) => choice("mm", "cm", "m"),

    // ---------------------------------------------------------------- base.tx

    py_module_attr: ($) =>
      seq(
        "py",
        "{",
        "module", ":", field("module", $.fqn), ",",
        "attr", ":", field("attr", $.name),
        "}",
      ),

    // --------------------------------------------------------------- terminals

    // textX IRI_TRUNK: a word that does not start with a digit, hyphens allowed.
    name: (_) => /[A-Za-z_][A-Za-z0-9_-]*/,

    number: (_) =>
      token(seq(optional(/[-+]/), choice(/\d+(\.\d*)?([eE][-+]?\d+)?/, /\.\d+([eE][-+]?\d+)?/))),

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
