"""The robbdd acceptance-criteria language: scenarios (`.bdd`).

Its executions live in `.bddx`, next door in [robbdd_exec][robbdd_exec].
"""

from __future__ import annotations

import re
from functools import lru_cache

from lsprotocol import types

NAME = "bdd"
PACKAGE = "robbdd"
EXTENSIONS = ("bdd",)


@lru_cache(maxsize=1)
def metamodel(path: str = ""):
    del path
    from robbdd.langs import bdd_metamodel

    return bdd_metamodel()


# --------------------------------------------------------------------- symbols

BLOCK_PATTERNS = (
    re.compile(
        r"^\s*(?P<kw>User Story|Scenario Template|Scenario|const set"
        r"|Behaviour"
        r"|(?P<bare>Event|Task))\b"
        r"(?:\s*\(\s*ns\s*=\s*[\w.-]+\s*\))?"
        r"(?:\s+(?P<name>[A-Za-z_][\w-]*))?"
    ),
    # A quantifier holds clauses the way a section does, and is worth an entry:
    # `for all ( var x in <s> ) {`.
    re.compile(r"^\s*(?P<kw>for all)\s*\(\s*var\s+(?P<name>[A-Za-z_][\w-]*)"),
    # A fluent is named where it is asserted, `fc-located: holds(...)`, and
    # opens no block -- hence `bare`, which must match non-empty text to count.
    re.compile(r"^\s*(?P<name>[A-Za-z_][\w-]*)\s*:\s*(?P<bare>(?P<kw>holds))\b"),
)

BLOCK_KIND = {
    "User Story": types.SymbolKind.Class,
    "Scenario Template": types.SymbolKind.Interface,
    "Scenario": types.SymbolKind.Function,
    "const set": types.SymbolKind.Array,
    "Event": types.SymbolKind.Event,
    "Task": types.SymbolKind.Constant,
    "Behaviour": types.SymbolKind.Method,
    "for all": types.SymbolKind.Operator,
    "holds": types.SymbolKind.Boolean,
}


# ----------------------------------------------------------------------- hover

HOVER_DOCS: dict[str, str] = {
    # .bdd
    "import": '**import** `"<file>"`\n\nLoads a `.scene`, `.bdd` or `.scenex` file so its names resolve here.',
    "ns": '**ns** `<prefix> = "<uri>"`\n\nBinds a namespace prefix to a URI.',
    "Event": "**Event** `(ns=<prefix>) <name>`\n\nA moment the clauses are timed against: `before`, `after`, or `from ... until`.",
    "Task": "**Task** `(ns=<prefix>) <name>`\n\nWhat the scenario is about; a template names one.",
    "Behaviour": "**Behaviour** `(ns=<prefix>) <name> { duration: ..., <agent> picks <object> ... }`\n\nWhat the robot does during the scenario, and between which events.",
    "User": "**User Story** `(ns=<prefix>) <name> { As A ..., I Want ..., So That ..., Scenarios: ... }`",
    "Story": "**User Story** `(ns=<prefix>) <name> { ... }`\n\nThe stakeholder view a set of scenario variants answers.",
    "Scenario": "**Scenario Template** `(ns=..) <name> { duration, task, var..., Given/When/Then }`\n\nAs **Scenario** `<name> { template:, scene:, variation: }` inside a story, one variant of a template; as **Scenario Exec** in a `.bddx`, how a variant is run.",
    "Template": "**Scenario Template** `(ns=<prefix>) <name> { ... }`\n\nThe reusable scenario: variables, and the clauses that must hold.",
    "Scenarios": "**Scenarios** `: Scenario <name> { ... }`\n\nThe variants this story is satisfied by.",
    "template": "**template** `: <scenario-template>`\n\nThe template this variant instantiates.",
    "scene": "**scene** `: <scene-model>`\n\nThe abstract scene the variant plays in. In a `.bddx`, **scene inst** names the executable instance instead.",
    "duration": "**duration** `: from <event> until <event>`\n\nThe window the scenario or behaviour spans.",
    "task": "**task** `: <task>`",
    "variation": "**variation** `:` a table, or `var <v>: <set>` lines\n\nHow the variant's variables are filled: one row per case, or a cartesian product of sets.",
    "var": "**var** `<name>` declares a scenario variable; **set var** `<name>` one standing for a set. In a variation, `var <v>: <values>` fills it.",
    "const": "**const set** `(ns=<prefix>) <name> { <a>, <b> }`\n\nA set written out, for a variation to draw from.",
    "Given": "**Given** `:` a fluent, a text clause, or an `exists` clause\n\nWhat holds before the behaviour runs.",
    "When": "**When** `:` `event <e> occurs` and/or a `Behaviour { ... }`\n\nWhat happens.",
    "Then": "**Then** `:` a fluent, a text clause, or an `exists` clause\n\nWhat must hold afterwards.",
    "holds": "**holds** `(<predicate>, <time-constraint>)`\n\nA named fluent: `fc-x: holds(<obj> is located at <ws>, after <evt>)`.",
    "pred": '**pred** `("<template>", <arg>=<var>, ...)`\n\nA predicate the metamodel has no keyword for, written as a string template with its variables bound.',
    "for": "**for all** `( var <x> in <set-var> ) { ... }`\n\nQuantifies the clauses inside over every element of a set variable.",
    "all": "**for all** `( var <x> in <set-var> ) { ... }`",
    "exists": "**(** `var <y>` **exists in** `<set-var>` **) such that** `{ ... }`\n\nOne element is enough for the clause to hold.",
    "select": "**select** `<n> [repeated] combinations from <set>` | **select** `<n> permutations from <set>`\n\nEnumerates a set variable's values.",
    "before": "**before** `<event>`",
    "after": "**after** `<event>`",
    "from": "**from** `<event>` **until** `<event>`",
    "event": "**event** `<event>` **occurs**\n\nA When clause that fires on an event rather than a behaviour.",
}


# ------------------------------------------------------------------ completion

# fmt: off
KEYWORDS = [
    "import", "ns", "Event", "Task", "Behaviour", "User", "Story", "Scenario",
    "Template", "Scenarios", "As", "A", "I", "Want", "So", "That",
    "template", "scene", "duration", "task", "variation", "var", "set", "const",
    "Given", "When", "Then", "holds", "pred", "for", "all", "in", "exists",
    "such", "that", "and", "or", "not", "before", "after", "from", "until",
    "event", "occurs", "picks", "places", "at", "is", "located", "held", "by",
    "can", "reach", "does", "drop", "collide", "has", "config", "are", "sorted",
    "into", "select", "combinations", "permutations", "repeated", "obj", "ws",
    "agn"
]
# fmt: on
