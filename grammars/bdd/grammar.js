/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

// Mirrors the textX grammars in robbdd/grammars/*.tx (base, bdd, bddx): the
// scenarios of a `.bdd` and the executions of a `.bddx`. robbdd registers those
// as two languages, but their top-level constructs are disjoint, so one parser
// reads either file -- the way `.scene` and `.scenex` share the scenex grammar.
// Which metamodel checks a buffer still follows its extension.
//
// Deliberately more permissive than textX where being strict would only cost
// error recovery while editing: a scenario template's clauses may appear in any
// order and any of them may be missing. Semantic checking is the language
// server's job.
//
// The scene references (`scene: <s>`, `scene inst: <si>`) resolve against the
// scene-dsl language, which textX links in by registration; here they are plain
// references like any other.

const commaSep1 = (rule) => seq(rule, repeat(seq(",", rule)), optional(","))

module.exports = grammar({
  name: "bdd",

  word: ($) => $.name,

  extras: ($) => [/\s+/, $.comment],

  rules: {
    source_file: ($) =>
      repeat(
        choice(
          $.import,
          $.namespace_decl,
          $.event,
          $.task,
          $.explicit_set,
          $.scenario_template,
          $.user_story,
          // .bddx: how a variant is executed. Disjoint from the above, so one
          // parser reads either file without ever accepting the other's.
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

    // ------------------------------------------------------------ declarations

    event: ($) => seq("Event", $._ns_header, field("name", $.name)),

    task: ($) => seq("Task", $._ns_header, field("name", $.name)),

    behaviour: ($) => seq("Behaviour", $._ns_header, field("name", $.name)),

    explicit_set: ($) =>
      seq(
        "const", "set",
        $._ns_header,
        field("name", $.name),
        "{",
        commaSep1($._valid_var_value),
        "}",
      ),

    // ------------------------------------------------------------- user story

    user_story: ($) =>
      seq(
        "User", "Story",
        $._ns_header,
        field("name", $.name),
        "{",
        "As", "A", field("role", $.string),
        "I", "Want", field("feature", $.string),
        "So", "That", field("benefit", $.string),
        "Scenarios", ":",
        repeat1($.scenario_variant),
        "}",
      ),

    scenario_variant: ($) =>
      seq(
        "Scenario",
        field("name", $.name),
        "{",
        "template", ":", field("template", $.ref),
        "scene", ":", field("scene", $.ref),
        optional($.given_expr),
        optional(seq("When", ":", repeat1($.when_event_clause))),
        optional($.then_expr),
        "variation", ":",
        field("variation", $._task_variation),
        "}",
      ),

    // -------------------------------------------------------------- template

    scenario_template: ($) =>
      seq(
        "Scenario", "Template",
        $._ns_header,
        field("name", $.name),
        "{",
        "duration", ":", field("duration", $.during_event),
        "task", ":", field("task", $.ref),
        repeat($._variable),
        $._gwt_expr,
        "}",
      ),

    // textX fixes the order and allows each clause once; a repetition keeps a
    // half-written template highlighted.
    _gwt_expr: ($) =>
      repeat1(choice($.given_expr, $.when_expr, $.forall_expr, $.then_expr)),

    given_expr: ($) => seq("Given", ":", field("given", $._clause)),

    when_expr: ($) =>
      seq("When", ":", repeat($.when_event_clause), $.when_behaviour_clause),

    then_expr: ($) => seq("Then", ":", field("then", $._clause)),

    forall_expr: ($) =>
      seq(
        "for", "all",
        "(", field("var", $.scenario_variable), "in", field("in_set", $.ref), ")",
        "{",
        $._gwt_expr,
        "}",
      ),

    exists_expr: ($) =>
      seq(
        "(", field("var", $.scenario_variable), "exists", "in", field("in_set", $.ref), ")",
        "such", "that",
        "{",
        field("expr", $._fluent_logic_expr),
        "}",
      ),

    when_event_clause: ($) => seq("event", field("event", $.ref), "occurs"),

    when_behaviour_clause: ($) =>
      seq(
        field("behaviour", $.behaviour),
        "{",
        "duration", ":", field("duration", $.during_event),
        field("does", $._parameterized_behaviour),
        "}",
      ),

    _parameterized_behaviour: ($) =>
      choice($.pick_place_behaviour, $.pick_behaviour, $.place_behaviour),

    pick_behaviour: ($) =>
      seq(field("agent", $.ref), "picks", field("object", $.ref)),

    place_behaviour: ($) =>
      seq(
        field("agent", $.ref), "places", field("object", $.ref),
        "at", field("workspace", $.ref),
      ),

    pick_place_behaviour: ($) =>
      seq(
        field("agent", $.ref), "picks", field("object", $.ref),
        "and", "places", "at", field("workspace", $.ref),
      ),

    // ---------------------------------------------------------------- clauses

    _clause: ($) => choice($.text_clause, $._fluent_logic_expr, $.exists_expr),

    text_clause: ($) => seq(field("text", $.string), field("tc", $._time_constraint)),

    _fluent_logic_expr: ($) =>
      choice($.fluent_group_expr, $.fluent_not_expr, $.holds_expr),

    holds_expr: ($) =>
      seq(
        field("name", $.name), ":", "holds",
        "(", field("predicate", $._fol_expr), ",", field("tc", $._time_constraint), ")",
      ),

    // textX reads `and` and `or` groups as separate rules; one rule covers both,
    // and which operator was written stays in the tree.
    fluent_group_expr: ($) =>
      seq(
        "(",
        $._fluent_logic_expr,
        repeat(seq(field("operator", choice("and", "or")), $._fluent_logic_expr)),
        ")",
      ),

    fluent_not_expr: ($) => seq("(", "not", $._fluent_logic_expr, ")"),

    // ------------------------------------------------------- time constraints

    _time_constraint: ($) => choice($.before_event, $.after_event, $.during_event),

    before_event: ($) => seq("before", field("event", $.ref)),

    after_event: ($) => seq("after", field("event", $.ref)),

    during_event: ($) =>
      seq("from", field("start", $.ref), "until", field("end", $.ref)),

    // --------------------------------------------------------- predicates

    _fol_expr: ($) =>
      choice(
        $.str_tmpl_pred,
        $.located_at_pred,
        $.is_held_pred,
        $.does_not_drop_pred,
        $.does_not_collide_pred,
        $.can_reach_pred,
        $.has_config_pred,
        $.is_sorted_pred,
      ),

    str_tmpl_pred: ($) =>
      seq("pred", "(", field("template", $.string), ",", commaSep1($.arg_var_map), ")"),

    arg_var_map: ($) =>
      seq(field("arg", $.name), "=", field("var", $.ref)),

    can_reach_pred: ($) =>
      seq(field("agent", $.ref), "can", "reach", field("object", $.ref)),

    located_at_pred: ($) =>
      seq(field("object", $.ref), "is", "located", "at", field("workspace", $.ref)),

    is_held_pred: ($) =>
      seq(field("object", $.ref), "is", "held", "by", field("agent", $.ref)),

    does_not_drop_pred: ($) =>
      seq(field("agent", $.ref), "does", "not", "drop", field("object", $.ref)),

    does_not_collide_pred: ($) =>
      seq(field("agent", $.ref), "does", "not", "collide", field("target", $.ref)),

    has_config_pred: ($) =>
      seq(
        field("target", $.ref), "has", "config",
        field("config", $.name), "=", field("value", $.ref),
      ),

    is_sorted_pred: ($) =>
      seq(field("objects", $.ref), "are", "sorted", "into", field("workspaces", $.ref)),

    // -------------------------------------------------------------- variation

    _task_variation: ($) => choice($.table_variation, $.cartesian_product_variation),

    cartesian_product_variation: ($) =>
      repeat1(choice($.variable_variation_set, $.set_variable_variation_set)),

    variable_variation_set: ($) =>
      seq(
        "var", field("variable", $.ref), ":",
        field("values", choice($.const_set_link, $.set_expr)),
      ),

    set_variable_variation_set: ($) =>
      seq(
        "set", "var", field("variable", $.ref), ":",
        field("values", choice($.combination, $.permutation, $.set_of_sets_expr)),
      ),

    table_variation: ($) =>
      seq($.variable_header, "|", repeat1(seq("---", "|")), repeat1($.value_row)),

    variable_header: ($) => seq("|", repeat1(seq(field("variable", $.ref), "|"))),

    value_row: ($) =>
      seq("|", $._valid_cell_value, repeat(seq("|", $._valid_cell_value)), "|"),

    _valid_cell_value: ($) =>
      choice($._valid_var_value, $.const_set_link, $.set_expr),

    // -------------------------------------------------------------------- sets

    const_set_link: ($) =>
      seq(
        choice("set", seq("obj", "set"), seq("ws", "set"), seq("agn", "set")),
        field("linked", $.ref),
      ),

    set_expr: ($) => seq("{", commaSep1($._valid_var_value), "}"),

    set_of_sets_expr: ($) => seq("{", commaSep1($.set_expr), "}"),

    combination: ($) =>
      seq(
        "select", field("length", $.number),
        optional("repeated"), "combinations",
        "from", field("from", $.ref),
      ),

    permutation: ($) =>
      seq(
        "select", field("length", $.number), "permutations",
        "from", field("from", $.ref),
      ),

    // --------------------------------------------------------------- variables

    _variable: ($) => choice($.scenario_set_variable, $.scenario_variable),

    scenario_variable: ($) => seq("var", field("name", $.name)),

    scenario_set_variable: ($) => seq("set", "var", field("name", $.name)),

    _valid_var_value: ($) => choice($.ref, $.number, $.string),

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
        field("spec", choice($.ros_trinary_topic_policy, $.evaluated_observation_policy)),
        "}",
      ),

    horizon_seconds: ($) => seq(field("value", $.number), "seconds"),

    observation: ($) =>
      seq(
        "observation",
        field("name", $.name),
        "{",
        "provider", ":", field("provider", $.ref),
        optional(seq(
          "observes",
          choice(
            seq("var", field("var_target", $.ref)),
            seq("obj", field("obj_target", $.ref)),
            seq("agn", field("agn_target", $.ref)),
            seq("ws", field("ws_target", $.ref)),
          ),
        )),
        "}",
      ),

    ros_trinary_topic_policy: ($) =>
      seq("trinary", "topic", ":", field("topic", $.string)),

    evaluated_observation_policy: ($) =>
      seq(
        repeat1($.observation),
        "time", "extractor", ":", field("time_extractor", $.py_module_attr),
        optional(seq("entity", "mapper", ":", field("entity_mapper", $.py_module_attr))),
        "evaluator", ":", field("evaluator", choice($.py_module_attr, $.linear_distance_evaluator)),
      ),

    linear_distance_evaluator: ($) =>
      seq(
        "linear", "distance",
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

    // Either quote style, with backslash escapes: a predicate template carries
    // quoted names, `pred("\"{robot}\" can reach \"{x}\"", ...)`.
    string: (_) =>
      token(
        choice(
          seq('"', /[^"\\]*(\\.[^"\\]*)*/, '"'),
          seq("'", /[^'\\]*(\\.[^'\\]*)*/, "'"),
        ),
      ),
  },
})
