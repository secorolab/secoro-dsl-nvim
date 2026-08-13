"""The motion-spec guarded-motion DSL (`.robmot`)."""

from __future__ import annotations

import re
from functools import lru_cache

from lsprotocol import types

NAME = "robmot"
PACKAGE = "motion_spec_dsl"
EXTENSIONS = ("robmot",)


@lru_cache(maxsize=1)
def metamodel(path: str = ""):
    del path
    from motion_spec_dsl.langs import motion_spec_metamodel

    return motion_spec_metamodel()


# --------------------------------------------------------------------- symbols

BLOCK_PATTERNS = (
    # Top-level specifications and the sections inside a motion or handler.
    re.compile(
        r"^\s*(?P<kw>context|exec-context|tolerances|ros|guarded-motion|constraint-handler"
        r"|world|pre|spec|post|when|while|until|monitors|controllers|solvers"
        r"|publishers|action-clients|action-servers|always)\b"
        r"(?:\s*\(\s*ns\s*=\s*[\w.-]+\s*\))?"
        r"(?:\s+(?:any|all))?"
        r"(?:\s+(?P<name>[A-Za-z_][\w-]*))?"
    ),
    # Controllers are written kind-first, `pid ctrl-name { ... }`.
    re.compile(r"^\s*(?P<kw>pid|impedance|feed-forward)\s+(?P<name>[A-Za-z_][\w-]*)"),
    # Monitors, solvers and named until-groups are written name-first.
    re.compile(
        r"^\s*(?P<name>[A-Za-z_][\w-]*)\s*:\s*"
        r"(?P<kw>monitor|serial-chain|mobile-platform|command-forwarding)\b"
    ),
    re.compile(r"^\s*(?P<name>[A-Za-z_][\w-]*)\s+(?P<kw>any|all)\s*(?=\{)"),
)

BLOCK_KIND = {
    "context": types.SymbolKind.Namespace,
    "exec-context": types.SymbolKind.Struct,
    "tolerances": types.SymbolKind.Constant,
    "ros": types.SymbolKind.Interface,
    "guarded-motion": types.SymbolKind.Function,
    "constraint-handler": types.SymbolKind.Class,
    "world": types.SymbolKind.Package,
    "pre": types.SymbolKind.Package,
    "spec": types.SymbolKind.Package,
    "post": types.SymbolKind.Package,
    "when": types.SymbolKind.Event,
    "while": types.SymbolKind.Event,
    "until": types.SymbolKind.Event,
    "any": types.SymbolKind.Event,
    "all": types.SymbolKind.Event,
    "monitors": types.SymbolKind.Package,
    "controllers": types.SymbolKind.Package,
    "solvers": types.SymbolKind.Package,
    "publishers": types.SymbolKind.Package,
    "action-clients": types.SymbolKind.Package,
    "action-servers": types.SymbolKind.Package,
    "always": types.SymbolKind.Package,
    "monitor": types.SymbolKind.Method,
    "pid": types.SymbolKind.Method,
    "impedance": types.SymbolKind.Method,
    "feed-forward": types.SymbolKind.Method,
    "serial-chain": types.SymbolKind.Method,
    "mobile-platform": types.SymbolKind.Method,
    "command-forwarding": types.SymbolKind.Method,
}


# ----------------------------------------------------------------------- hover

HOVER_DOCS: dict[str, str] = {
    # top-level blocks
    "import": '**import** `"<file>"`\n\nLoads a `.robmot`, `.scenex` or `.fsm` file so its names resolve here.',
    "ns": '**ns** `<prefix> = "<uri>"`\n\nBinds a namespace prefix to a URI.',
    "exec-context": "**exec-context** `(ns=<prefix>) <name> { runs-scene, platform, [config], timestep }`\n\nBinds the imported scene to a platform and a control timestep.",
    "context": "**context** `(ns=<prefix>) <name> { world {...}, pre/spec/post {...} }`\n\nShared quantity declarations that motions reference; inside a motion or handler it introduces the local context block.",
    "tolerances": "**tolerances** `{ <quantity-kind>: <band>, ... }`\n\nModel-wide satisfaction bands. A constraint without `within` uses the band declared for the kind its error carries.",
    "ros": "**ros** `(ns=<prefix>) { publishers, subscribers, action-clients, action-servers, always }`\n\nROS channels the model publishes to, listens on, and the actions it calls or serves.",
    "always": "**always** `{ publish at <r> Hz to <topic> with <quantity> [{ <field>: <quantity>.<selector> }] }`\n\nPublishers that run for the whole run. The message reports the quantity whole; a listed field overrides what that one carries.",
    "subscribers": '**subscribers** `{ <name>: topic "<channel>" message "<type>" { observes { <target>, ... } <field> from <container> } }`\n\nA topic the model reads: which scene elements the message reports on, and which of its fields carries their pose.',
    "observes": "**observes** `{ <target>, ... }`\n\nThe scene elements a subscription's messages report on.",
    "guarded-motion": "**guarded-motion** `(ns=<prefix>) <name> { description, context, [detects], when/while/until }`\n\nA motion with its activation, maintenance and termination constraints.",
    "constraint-handler": "**constraint-handler** `(ns=<prefix>) <name> { [context], handles, [runs-in], [monitors], controllers, solvers }`\n\nThe control-side assembly for one guarded motion.",
    # sections
    "world": "**world** `{ <type> <name> { of:, wrt:, as-seen-by: } , ... }`\n\nMeasured quantities: what the robot senses about the scene.",
    "normalization": "**normalization** `: (<lower>, <upper>) rad|deg`\n\nThe interval a joint-position reading is taken into. A bound may be written `pi`, `-pi` or `2*pi`. A value outside is moved onto the interval by whole turns, not clamped -- that is what a joint limit does.",
    "pre": "**pre** `{ ... }`\n\nQuantities established before the motion runs.",
    "spec": "**spec** `{ ... }`\n\nQuantities the motion's own constraints reference.",
    "post": "**post** `{ ... }`\n\nQuantities that only matter after the motion.",
    "when": "**when** `[any|all] { ... }`\n\nActivation constraints: what must hold for the motion to start.",
    "while": "**while** `{ ... }`\n\nConstraints held during execution; each one is what a controller drives.",
    "until": "**until** `[any|all] { ... }`\n\nTermination conditions. Transition monitors watch these, not `while`.",
    "handles": "**handles** `: <motion>`\n\nThe guarded motion this handler implements.",
    "runs-in": "**runs-in** `: <ns.STATE>`\n\nThe FSM state this handler is active in.",
    "monitors": "**monitors** `{ <name>: monitor <constraint> { satisfied {...}, violated {...} } }`",
    "controllers": "**controllers** `{ pid|impedance|feed-forward <name> { ... } }`",
    "solvers": "**solvers** `{ <name>: serial-chain|mobile-platform|command-forwarding { ... } }`",
    "detect": "**detect** `{ <target>, ... } using <action>`\n\nAsks a ROS action to locate scene objects; its `.status` can be tested in `until`.",
    # views and relations
    "keeping": "**keeping** `<view> <relation> [within <band>]`\n\nMarks a maintained constraint; optional sugar, the relation is what counts.",
    "distance": "**distance between** `<a>` **and** `<b>`\n\nScalar distance view between two poses.",
    "elapsed": "**elapsed**\n\nTime since the motion was entered; compare it like any scalar.",
    "progress": "**progress of** `<quantity>` **along** `<path>`\n\nRate of advance along a path.",
    "moving": "**moving** `<quantity>` **along** `<path>` **at** `<speed>`\n\nTangential path-following view.",
    "on": "**on** `<path>`\n\nLateral/orientation deviation of a quantity from a path.",
    "snapshot": "**snapshot of** `<view>` `[+ <offset>]` `[on event <e>]`\n\nCaptures a value once, or re-captures it whenever the event fires.",
    "rotated": "**rotated** `[in <frame>]` **by** `euler|quat|direction-cosine`\n\nOrientation relative to another orientation.",
    "equal": "**equal to** `<reference>`\n\nEquality constraint; pair it with `within <band>`.",
    "between": "**between** `<lower>` **and** `<upper>`\n\nBand constraint: satisfied inside the interval.",
    "outside": "**outside** `<lower>` **and** `<upper>`\n\nSatisfied outside the interval.",
    "within": "**within** `<band>`\n\nSatisfaction band for this constraint; defaults to the `tolerances` entry for its kind.",
    "@disable": "**@disable**\n\nKeeps the constraint in the model but takes it out of the generated assembly.",
    # controllers and solvers
    "pid": "**pid** `<name> { constraint: <c>, [profile:], [measured-derivative:], [output-saturation:], [integral-saturation:], Kp:, Ki:, Kd:, [decay:], [error-normalization:] }`",
    "error-normalization": "**error-normalization** `: (<lower>, <upper>) rad|deg`\n\nThe interval this controller's error wraps into, so an angular error takes the short way round.",
    "impedance": "**impedance** `<name> { constraint: <c>, [output-saturation:], [Ki:], stiffness:, damping: }`",
    "feed-forward": "**feed-forward** `<name> { constraint: <c>, [output-saturation:] }`\n\nPasses the constraint's reference straight through as a command.",
    "serial-chain": "**serial-chain** `{ agent: <a>, [algorithm: achd|rne], [limits {...}], [gravity: ...] }`",
    "mobile-platform": "**mobile-platform** `{ agent:, algorithm:, configuration:, quantity: }`\n\nPlatform kinematics / control allocation (hddc2b).",
    "command-forwarding": "**command-forwarding** `{ agent: <a> }`\n\nForwards commands to a device instead of solving dynamics.",
    "achd": "**achd**\n\nVereshchagin (acceleration-constrained hybrid dynamics) solver.",
    "rne": "**rne**\n\nRecursive Newton-Euler solver; adds the Jdot*qd feedforward term.",
    "saturation": "**saturation** `{ max: <v> }` or `{ lower: <v>, upper: <v> }`",
    "profile": "**profile** `{ max-velocity:, max-acceleration:, [measured-velocity:], [max-jerk:], [shape: trapezoidal|s-curve] }`",
    "admittance": "**admittance** `= { force:, mass:, damping:, stiffness:, max-velocity: }`\n\nTurns a measured force into a commanded velocity.",
    # monitors
    "monitor": "**monitor** `<constraint|motion.until|motion.when> { satisfied [for <t>] { ... }, violated { ... } }`",
    "satisfied": "**satisfied** `[for <duration>] { ... }`\n\nActions taken while (or after sustaining) the monitored constraint holds.",
    "violated": "**violated** `[for <duration>] { ... }`\n\nActions taken while the monitored constraint does not hold.",
    "trigger": "**trigger** `: event <ns.EVENT>`\n\nFires an FSM event.",
    "hold": "**hold** `: <motion>`\n\nFalls back to another guarded motion.",
    "flag": "**flag** `: <name>`\n\nRaises a boolean flag while the state holds.",
    "publish": "**publish** `: event to <topic>` | `: to <topic> { field: value }` | `: <value> to <topic>`",
    # platform
    "real-world": "**real-world** `{ <target> realized by <device>, ... }`\n\nNames the hardware standing in for each modelled agent or sensor.",
    "simulation": '**simulation** `{ name: "MuJoCo" }`',
    "path": "**path** `<name> = lerp|circle|arc|helix|figure8 { ... }`",
}


# ------------------------------------------------------------------ completion

# fmt: off
KEYWORDS = [
    "import", "ns", "context", "exec-context", "tolerances", "ros", "guarded-motion",
    "constraint-handler", "description", "publishers", "subscribers", "action-clients",
    "action-servers", "always", "observes", "topic", "message", "from", "with", "world",
    "normalization", "error-normalization", "pre", "spec", "post",
    "when", "while", "until", "any", "all", "handles", "runs-in", "monitors", "controllers",
    "solvers", "path", "detect", "keeping", "equal", "to", "greater", "less", "more", "than",
    "between", "outside", "within", "distance", "elapsed", "progress", "moving", "along", "at",
    "on", "snapshot", "rotated", "using", "as", "via", "apply", "for", "monitor", "satisfied",
    "violated", "trigger", "hold", "flag", "publish", "pid", "impedance", "feed-forward",
    "saturation", "profile", "admittance", "serial-chain", "mobile-platform",
    "command-forwarding", "achd", "rne", "real-world", "simulation", "velocity-profile",
    "lerp", "circle", "arc", "helix", "figure8", "euler", "quat", "direction-cosine"
]
# fmt: on

# fmt: off
TYPES = [
    "pose", "position", "orientation", "velocity-twist", "acceleration-twist", "wrench",
    "angular-velocity", "linear-velocity", "linear-acceleration", "angular-acceleration",
    "linear-jerk", "force", "torque", "direction", "free-vector", "joint-position", "distance",
    "angle", "dimensionless", "duration", "path-parameter", "length"
]
# fmt: on

# fmt: off
UNITS = [
    "mm", "cm", "m", "rad", "deg", "m/s", "cm/s", "rad/s", "deg/s", "m/s^2", "rad/s^2",
    "m/s^3", "N", "Nm", "s", "ms", "Hz"
]
# fmt: on
