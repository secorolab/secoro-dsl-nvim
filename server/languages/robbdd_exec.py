"""The robbdd execution language: how a scenario variant is run (`.bddx`).

The scenarios it executes live in `.bdd`, next door in [robbdd][robbdd].
"""

from __future__ import annotations

import re
from functools import lru_cache

from lsprotocol import types

NAME = "bddx"
PACKAGE = "robbdd"
EXTENSIONS = ("bddx",)


@lru_cache(maxsize=1)
def metamodel(path: str = ""):
    del path
    from robbdd.langs import bddx_metamodel

    return bddx_metamodel()


# --------------------------------------------------------------------- symbols

BLOCK_PATTERNS = (
    re.compile(
        r"^\s*(?P<kw>Scenario Exec|bhv impl|obs provider|obs policy|observation)\b"
        r"(?:\s*\(\s*ns\s*=\s*[\w.-]+\s*\))?"
        r"(?:\s+(?P<name>[A-Za-z_][\w-]*))?"
    ),
)

BLOCK_KIND = {
    "Scenario Exec": types.SymbolKind.Function,
    "bhv impl": types.SymbolKind.Method,
    "obs provider": types.SymbolKind.Interface,
    "obs policy": types.SymbolKind.Class,
    "observation": types.SymbolKind.Field,
}


# ----------------------------------------------------------------------- hover

HOVER_DOCS: dict[str, str] = {
    "import": '**import** `"<file>"`\n\nLoads the `.bdd` this executes and the `.scenex` it runs in.',
    "ns": '**ns** `<prefix> = "<uri>"`\n\nBinds a namespace prefix to a URI.',
    "Exec": "**Scenario Exec** `(ns=<prefix>) <name> { variant:, scene inst:, bhv:, policies: {...} }`\n\nHow one scenario variant is actually run.",
    "variant": "**variant** `: <scenario-variant>`\n\nThe `.bdd` variant this execution realizes.",
    "inst": "**scene inst** `: <scene-instance>`\n\nThe executable scene from the `.scenex`.",
    "bhv": '**bhv impl** `(ns=..) <name> { bhv action: "<action>" | py {...} }`\n\nWhat implements the behaviour. Inside an execution, **bhv** `: <impl>` names it.',
    "impl": "**bhv impl** `(ns=<prefix>) <name> { ... }`",
    "obs": "**obs provider** `(ns=..) <name> { ... }` and **obs policy** `(ns=..) <name> for <fluent> { ... }`\n\nWhere observations come from, and how they decide a fluent.",
    "provider": "**obs provider** `(ns=..) <name> { ros topic: ... | ros simulation entity state ... }`\n\nAs `provider: <p>` inside an observation, which one it reads.",
    "policy": "**obs policy** `(ns=..) <name> for <fluent> [horizon: <t> seconds] { observation..., <spec> }`\n\nHow a fluent's truth is decided from observations.",
    "policies": "**policies** `: { <policy>, ... }`\n\nThe policies this execution evaluates.",
    "observation": "**observation** `<name> { provider: <p>, [observes: <var>] }`",
    "observes": "**observes** `: <variable>`\n\nThe scenario variable this observation follows.",
    "horizon": "**horizon** `: <t> seconds`\n\nHow long the policy looks back before deciding.",
    "linear": "**linear distance between** `<a>` **and** `<b>` `{ <constraint> }`\n\nDecides the fluent from the distance between two observations.",
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
    "import", "ns", "Scenario", "Exec", "variant", "scene", "inst", "bhv",
    "impl", "obs", "provider", "policy", "policies", "observation", "observes",
    "horizon", "seconds", "linear", "distance", "between", "and", "tolerance",
    "equals", "less-than", "greater-than", "trinary", "topic", "type", "action",
    "update-rate", "ros", "simulation", "entity", "state", "for", "py",
    "module", "attr"
]

UNITS = ["mm", "cm", "m", "Hz", "seconds"]
# fmt: on
