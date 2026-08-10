/// <reference types="tree-sitter-cli/dsl" />
// @ts-check

// Mirrors the textX grammars in coord_dsl/metamodels/*.tx (base, event_loop,
// fsm). Deliberately more permissive than textX: the FSM's sections may appear
// in any order and any of them may be missing, so a half-written buffer keeps
// its highlighting. Semantic checking is the language server's job.

const commaSep1 = (rule) => seq(rule, repeat(seq(",", rule)), optional(","))
const commaSep = (rule) => optional(commaSep1(rule))

module.exports = grammar({
  name: "fsm",

  word: ($) => $.name,

  extras: ($) => [/\s+/, $.comment],

  rules: {
    source_file: ($) =>
      repeat(choice($.import, $.namespace_decl, $.event_loop, $.fsm)),

    comment: (_) => token(seq("//", /.*/)),

    import: ($) => seq("import", field("uri", $.string)),

    namespace_decl: ($) =>
      seq("ns", field("name", $.name), "=", field("uri", $.string)),

    // Every cross-reference in the DSL is written <dotted.path>.
    ref: ($) => seq("<", field("path", $.fqn), ">"),

    fqn: ($) => seq($.name, repeat(seq(".", $.name))),

    _ns_header: ($) => seq("(", "ns", "=", field("namespace", $.fqn), ")"),

    // ---------------------------------------------------------- event_loop.tx

    event_loop: ($) =>
      seq(
        "evt", "loop",
        $._ns_header,
        field("name", $.name),
        "{",
        commaSep($.event),
        "}",
      ),

    event: ($) => seq("evt", field("name", $.name)),

    // ----------------------------------------------------------------- fsm.tx

    fsm: ($) =>
      seq(
        "fsm",
        $._ns_header,
        field("name", $.name),
        "{",
        repeat(
          choice(
            $.description,
            $.states,
            $.event_loop_ref,
            $.start_state,
            $.end_state,
            $.transitions,
            $.reactions,
          ),
        ),
        "}",
      ),

    description: ($) => seq("description", ":", field("text", $.string)),

    states: ($) => seq("states", "{", commaSep($.state), "}"),

    state: ($) => field("name", $.name),

    event_loop_ref: ($) => seq("evt", "loop", ":", field("loop", $.ref)),

    start_state: ($) => seq("start", ":", field("state", $.ref)),

    end_state: ($) => seq("end", ":", field("state", $.ref)),

    transitions: ($) => seq("transitions", "{", commaSep($.transition), "}"),

    transition: ($) =>
      seq(
        field("name", $.name),
        "{",
        "from", ":", field("from", $.ref), ",",
        "to", ":", field("to", $.ref),
        optional(","),
        "}",
      ),

    reactions: ($) => seq("reactions", "{", commaSep($.reaction), "}"),

    reaction: ($) =>
      seq(
        field("name", $.name),
        "{",
        "when", ":", field("when", $.ref), ",",
        "do", ":", field("do", $.ref),
        optional(seq(",", $.fires)),
        optional(","),
        "}",
      ),

    fires: ($) => seq("fires", "{", commaSep(field("event", $.ref)), "}"),

    // --------------------------------------------------------------- terminals

    // textX IRI_TRUNK: a word that does not start with a digit, hyphens allowed.
    name: (_) => /[A-Za-z_][A-Za-z0-9_-]*/,

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
