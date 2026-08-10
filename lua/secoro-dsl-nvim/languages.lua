-- The DSLs this plugin knows. Everything else -- filetype detection, parser
-- builds, health checks, the language server's filetype list -- is driven from
-- here, so adding a language is this entry plus its grammar, queries and server
-- module.
return {
  {
    name = "robmot",
    extensions = { "robmot" },
    package = "motion_spec_dsl",
    description = "motion-spec guarded-motion DSL",
  },
  {
    name = "scenex",
    -- One filetype for all three: their top-level constructs are disjoint, so
    -- one grammar reads each. The server picks the metamodel per extension.
    extensions = { "scene", "scenex", "ktree" },
    package = "scene_dsl",
    description = "scene-dsl scene models",
  },
  {
    name = "fsm",
    extensions = { "fsm" },
    package = "coord_dsl",
    description = "coord-dsl finite state machines",
  },
  {
    -- Two registered languages, one editor surface: a `.bddx` executes the
    -- `.bdd` next to it, and their constructs are disjoint.
    name = "bdd",
    extensions = { "bdd", "bddx" },
    package = "robbdd",
    description = "robbdd scenarios and their executions",
  },
}
