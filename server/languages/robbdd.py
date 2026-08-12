"""The robbdd acceptance-criteria languages: scenarios (`.bdd`) and how they are
executed (`.bddx`).

robbdd registers those as two languages, `robbdd` and `robbdd-exec`, and each
has its own metamodel -- but they are one surface to the editor, the way
`.scene` and `.scenex` are.
"""

from __future__ import annotations

import re
from functools import lru_cache

from lsprotocol import types

NAME = "bdd"
PACKAGE = "robbdd"
EXTENSIONS = ("bdd", "bddx")


@lru_cache(maxsize=2)
def _build(execution: bool):
    from robbdd.langs import bdd_metamodel, bddx_metamodel

    return bddx_metamodel() if execution else bdd_metamodel()


def metamodel(path: str):
    return _build(path.endswith(".bddx"))


# --------------------------------------------------------------------- symbols

BLOCK_PATTERNS = (
    re.compile(
        r"^\s*(?P<kw>User Story|Scenario Template|Scenario Exec|Scenario|const set"
        r"|Behaviour|bhv impl|obs provider|obs policy|observation"
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
    # .bddx
    "Scenario Exec": types.SymbolKind.Function,
    "bhv impl": types.SymbolKind.Method,
    "obs provider": types.SymbolKind.Interface,
    "obs policy": types.SymbolKind.Class,
    "observation": types.SymbolKind.Field,
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
    # .bddx
    "Exec": "**Scenario Exec** `(ns=<prefix>) <name> { variant:, scene inst:, bhv:, policies: {...} }`\n\nHow one scenario variant is actually run.",
    "variant": "**variant** `: <scenario-variant>`\n\nThe `.bdd` variant this execution realizes.",
    "inst": "**scene inst** `: <scene-instance>`\n\nThe executable scene from the `.scenex`.",
    "bhv": '**bhv impl** `(ns=..) <name> { bhv action: "<action>" | py {...} }`\n\nWhat implements the behaviour. Inside an execution, **bhv** `: <impl>` names it.',
    "impl": "**bhv impl** `(ns=<prefix>) <name> { ... }`",
    "obs": "**obs provider** `(ns=..) <name> { ... }` and **obs policy** `(ns=..) <name> for <fluent> { ... }`\n\nWhere observations come from, and how they decide a fluent.",
    "provider": "**obs provider** `(ns=..) <name> { ros topic: ... | ros simulation entity state ... }`\n\nAs `provider: <p>` inside an observation, which one it reads.",
    "policy": "**obs policy** `(ns=..) <name> for <fluent> [horizon: <t> seconds] { observation..., <spec> }`\n\nHow a fluent's truth is decided from observations.",
    "policies": "**policies** `: { <policy>, ... }`\n\nThe policies this execution evaluates.",
    "observation": "**observation** `<name> { provider: <p>, [observes var|obj|agn|ws <target>] }`",
    "observes": "**observes** `var|obj|agn|ws <target>`\n\nThe scenario or scene entity this observation follows.",
    "extractor": "**time extractor:** `py { module: <module>, attr: <name> }`\n\nExtracts timestamps from observations.",
    "mapper": "**entity mapper:** `py { module: <module>, attr: <name> }`\n\nOptionally maps observations to entities.",
    "evaluator": "**evaluator:** `linear distance { ... }` or `py { ... }`\n\nEvaluates the observations into the policy's fluent value.",
    "horizon": "**horizon** `: <t> seconds`\n\nHow long the policy looks back before deciding.",
    "linear": "**linear distance** `{ <constraint> }`\n\nEvaluates the distance between the policy's observations.",
    "distance": "**linear distance between** `<a>` **and** `<b>` `{ ... }`",
    "trinary": '**trinary topic** `: "<topic>"`\n\nThe fluent is whatever this topic reports: true, false, or unknown.',
    "ros": '**ros topic** `: "<t>" type: "<msg>"` | **ros simulation entity state** `update-rate: <r> Hz`',
    "py": "**py** `{ module: <a.b.c>, attr: <name> }`\n\nA Python callable stands in for the behaviour or the policy.",
    "less-than": "**less-than** `: <d> mm|cm|m`",
    "greater-than": "**greater-than** `: <d> mm|cm|m`",
    "equals": "**equals** `: <d> <unit>` **tolerance** `: <d> <unit>`",
    "update-rate": "**update-rate** `: <r> Hz`",
    "Scenario": "**Scenario Exec** `(ns=<prefix>) <name> { ... }`",
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
    "agn",
    "Exec", "variant", "inst", "bhv", "impl", "obs", "provider", "policy",
    "policies", "observation", "observes", "horizon", "seconds", "time",
    "extractor", "mapper", "evaluator", "linear",
    "distance", "between", "tolerance", "equals", "less-than", "greater-than",
    "trinary", "topic", "type", "action", "update-rate", "ros", "simulation",
    "entity", "state", "py", "module", "attr"
]

UNITS = ["mm", "cm", "m", "Hz", "seconds"]
# fmt: on
