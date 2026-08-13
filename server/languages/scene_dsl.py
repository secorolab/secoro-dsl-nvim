"""The scene DSL: abstract scenes (`.scene`), instances (`.scenex`) and device
trees (`.ktree`).

A `.ktree` holds scenex content -- textX itself parses one with the metamodel
importing it -- so only `.scene` gets the abstract metamodel.
"""

from __future__ import annotations

import re
from functools import lru_cache

from lsprotocol import types

NAME = "scenex"
PACKAGE = "scene_dsl"
EXTENSIONS = ("scene", "scenex", "ktree")


@lru_cache(maxsize=2)
def _build(abstract: bool):
    from scene_dsl.langs import scene_metamodel, scenex_metamodel

    return scene_metamodel() if abstract else scenex_metamodel()


def metamodel(path: str):
    return _build(path.endswith(".scene"))


# --------------------------------------------------------------------- symbols

# Multi-word introducers come first, longest first, so `obj set` is not read as
# `obj`. `ktree inst ... of <t>` is the one declaration written without a block,
# hence the `bare` group.
BLOCK_PATTERNS = (
    re.compile(
        r"^\s*(?P<kw>similar obj set|similar agn set|obj set|ws set|agn set|ws comp"
        r"|scene inst|(?P<bare>ktree inst)|ktree|kgraph|distrib|comp|scene|obj|ws|agn"
        r"|body|frame|pose|joints|inertia|fixed|revolute|serial|parallel|actuation"
        r"|limits|mimic|offset|model|camera|force-torque|imu)\b"
        r"(?:\s*\(\s*ns\s*=\s*[\w.-]+\s*\))?"
        r"(?:\s+(?P<name>[A-Za-z_][\w-]*|<[\w.-]+>))?"
    ),
)

BLOCK_KIND = {
    "obj set": types.SymbolKind.Array,
    "similar obj set": types.SymbolKind.Array,
    "ws set": types.SymbolKind.Array,
    "agn set": types.SymbolKind.Array,
    "similar agn set": types.SymbolKind.Array,
    "comp": types.SymbolKind.Struct,
    "ws comp": types.SymbolKind.Struct,
    "scene": types.SymbolKind.Namespace,
    "scene inst": types.SymbolKind.Namespace,
    "distrib": types.SymbolKind.Constant,
    "ktree": types.SymbolKind.Class,
    "ktree inst": types.SymbolKind.Object,
    "kgraph": types.SymbolKind.Class,
    "body": types.SymbolKind.Struct,
    "frame": types.SymbolKind.Field,
    "pose": types.SymbolKind.Property,
    "joints": types.SymbolKind.Package,
    "inertia": types.SymbolKind.Property,
    "fixed": types.SymbolKind.Method,
    "revolute": types.SymbolKind.Method,
    "serial": types.SymbolKind.Method,
    "parallel": types.SymbolKind.Method,
    "actuation": types.SymbolKind.Property,
    "limits": types.SymbolKind.Property,
    "mimic": types.SymbolKind.Property,
    "offset": types.SymbolKind.Property,
    "model": types.SymbolKind.File,
    "obj": types.SymbolKind.Object,
    "ws": types.SymbolKind.Object,
    "agn": types.SymbolKind.Object,
    "camera": types.SymbolKind.Event,
    "force-torque": types.SymbolKind.Event,
    "imu": types.SymbolKind.Event,
}


# ----------------------------------------------------------------------- hover

HOVER_DOCS: dict[str, str] = {
    # top-level declarations
    "import": '**import** `"<file>"`\n\nLoads a `.scene`, `.scenex` or `.ktree` file so its names resolve here.',
    "ns": '**ns** `<prefix> = "<uri>"`\n\nBinds a namespace prefix to a URI. An element\'s IRI is its namespace plus the path down to it.',
    "obj": "**obj set** `(ns=<prefix>) <name> { object <a>, object <b> }`\n\nA set of scene objects. Inside a `scene`: `obj set <ref>`; inside a `scene inst`: `obj <ref> { model ... }`.",
    "ws": "**ws set** `(ns=<prefix>) <name> { workspace <a>, ... }`\n\nA set of workspaces. Inside a composition, `ws <ref>` nests one and `ws comp <ref>` nests a composition.",
    "agn": "**agn set** `(ns=<prefix>) <name> { agent <a>, ... }`\n\nA set of agents. Inside a `scene inst`, `agn <ref> { model ..., <sensors> }` models one.",
    "similar": "**similar obj|agn set** `(ns=<prefix>) <name> { base name: <n>, count: <k> }`\n\nA set of `k` elements named after one base, when they differ in nothing that matters.",
    "comp": "**comp** `(ns=<prefix>) <name> of ws <ws> { obj <o> | ws <w> | ws comp <c> }`\n\nWhat a workspace is composed of.",
    "scene": "**scene** `(ns=<prefix>) <name> { obj set <s>, ws comp <c>, agn set <a> }`\n\nAbstract scene content. As `scene inst (ns=..) <name> { scene: <s> ... }` it is the executable instance; as `scene: <ref>` inside one, the abstract scene it realizes.",
    "inst": "**scene inst** / **ktree inst**\n\nThe executable instance of an abstract scene, or the named copy of a tree template.",
    "distrib": "**distrib** `(ns=<prefix>) <name> { uniform|normal|uniform-rotation {...} }`\n\nA distribution to sample a pose from.",
    "sample": "**sample** `<distribution>`\n\nDraws the position or orientation from a distribution instead of stating it.",
    "ktree": "**ktree** `[(ns=<prefix>)] <name> { root: <frame>, body..., joints {...} }`\n\nA kinematic tree: one root, no loops. Without a namespace it is a *template* -- a device without being any particular one -- and every use is `ktree inst (ns=..) <name> of <template>`.",
    "kgraph": "**kgraph** `(ns=<prefix>) <name> { anchor: <frame>, tree <t>, body..., [joints {...}] }`\n\nBodies held together without the promise of a tree: no single root, and loops allowed.",
    "anchor": "**anchor** `: <frame>`\n\nThe frame the graph stands on. A tree hangs from its `root` and stands on nothing, so it declares that instead.",
    "tree": '**tree** `<ref>`\n\nComposes another tree into this one. As `map tree <t> to "<entity>"`, binds it to an element of a model file.',
    # structure
    "body": "**body** `<name> { frame..., [inertia {...}] }`\n\nA rigid body: the frames on it, and the mass it carries.",
    "frame": "**frame** `<name> { pose... }`\n\nA coordinate frame on a body. As `frame: <ref>`, the frame an inertia or a sensor is expressed in.",
    "pose": "**pose** `<name> { [wrt: <frame>], xyz: (x, y, z) <unit>, orientation: <coord> }`",
    "wrt": "**wrt** `: <frame>`\n\nThe frame this pose is relative to.",
    "xyz": "**xyz** `: (x, y, z) mm|cm|m` or `: sample <distribution> <unit>`",
    "orientation": "**orientation** `: quat|euler|direction-cosine { ... }`\n\nAlso an IMU measure (`observes: orientation`).",
    "quat": "**quat** `{ xyzw: (x, y, z, w) }`",
    "euler": "**euler** `{ [axes: xyz|zyx|...] [extrinsic] angles: (a, b, c) [unit: rad|deg] }`",
    "direction-cosine": "**direction-cosine** `{ x: (..), y: (..), z: (..) }`\n\nThe rotation as its three axis vectors.",
    "extrinsic": "**extrinsic**\n\nEuler angles about the fixed axes rather than the rotating ones.",
    "inertia": "**inertia** `{ frame: <f>, [mass: <m> kg|g], [inertia-matrix: ((..),(..),(..)) kg*m^2] }`\n\nExpress it in the body's COM frame, so the matrix stays diagonal.",
    "joints": "**joints** `{ fixed|revolute ..., [serial {...} | parallel {}] }`",
    "fixed": "**fixed** `<name> { parent: <frame>, child: <frame> }`",
    "revolute": "**revolute** `<name> { parent: <frame>.<axis>, child: <frame>.<axis>, [actuation], [offset], [limits], [mimic], polarity: ... }`\n\nA revolute joint is the collinearity of two axes, coincident at q=0.",
    "serial": "**serial** `{ root: <frame>, tip: <frame> }`\n\nSlices a chain out of the tree; the tip must lie below the root.",
    "parallel": "**parallel** `{ }`",
    "polarity": "**polarity** `: PositivePolarity | NegativePolarity`\n\nWhich way positive rotation runs relative to the joint axis.",
    "actuation": "**actuation** `{ gear ratio: <r>, command-interface: <i>..., state-interface: <i>... }`\n\nInterfaces: `position`, `velocity`, `torque`, `current`.",
    "limits": "**limits** `{ [position: (lo, hi) rad], [velocity: .. rad/s], [acceleration: .. rad/s^2], [effort: .. N*m] }`",
    "mimic": "**mimic** `{ joint: <j>, multiplier: <m>, offset: <o> }`\n\nThis joint follows another one.",
    "offset": "**offset** `{ xyz: (x, y, z) m }`\n\nWhere the joint sits on its parent. Inside `mimic`, the constant added to the mimicked position.",
    # scenex
    "model": '**model** `<name> [as urdf|mjcf|usd] { <spec>, map tree|body <ref> [to "<entity>"] }`\n\nThe model file describing an object or agent, and which of its elements each tree or body is.',
    "map": '**map** `tree <t> to "<entity>"` | `map body <b> to "<entity>"`\n\nBinds a modelled element to a named element of the model file. Only one model may map a given tree or body.',
    "sys": '**sys path** `= "<path>"`\n\nThe model file, by filesystem path.',
    "ros": '**ros pkg** `= "<pkg>", path = "<path>"`\n\nThe model file, relative to a ROS package.',
    "py": "**py** `{ module: <a.b.c>, attr: <name> }`\n\nThe model file, from a Python module attribute.",
    "mjcf": "**mjcf**\n\nMuJoCo XML model.",
    "urdf": "**urdf**\n\nURDF model.",
    "usd": "**usd**\n\nUSD model.",
    # sensors
    "camera": "**camera** `<name> { frame: <f>, type: rgb|depth|rgbd, resolution: (w, h), fov: <a> rad|deg, update-rate: <r> Hz }`",
    "force-torque": "**force-torque** `<name> { frame: <f>, observes: force|torque..., update-rate: <r> Hz }`",
    "imu": "**imu** `<name> { frame: <f>, observes: angular-velocity|linear-acceleration|orientation..., update-rate: <r> Hz }`",
    "observes": "**observes** `: <measure>...`\n\nWhat the sensor reports; several may be listed, space-separated.",
    "update-rate": "**update-rate** `: <r> Hz`",
    # distributions
    "uniform": "**uniform** `{ dimension: <n>, lower: (..), upper: (..) }`",
    "normal": "**normal** `{ dimension: <n>, mean: <v>|(..), std-dev: <s> | covariance: ((..),(..),(..)) }`",
    "uniform-rotation": "**uniform-rotation**\n\nA rotation drawn uniformly over SO(3).",
}


# ------------------------------------------------------------------ completion

# fmt: off
KEYWORDS = [
    "import", "ns", "obj", "ws", "agn", "set", "similar", "comp", "scene", "inst", "object",
    "workspace", "agent", "base", "count", "of", "to", "as", "distrib", "uniform", "normal",
    "uniform-rotation", "sample", "dimension", "lower", "upper", "mean", "std-dev",
    "covariance", "ktree", "kgraph", "tree", "body", "frame", "pose", "wrt", "xyz",
    "orientation", "quat", "euler", "direction-cosine", "axes", "angles", "unit", "xyzw",
    "extrinsic", "inertia", "mass", "inertia-matrix", "joints", "fixed", "revolute", "serial",
    "parallel", "parent", "child", "root", "anchor", "tip", "actuation", "gear", "ratio",
    "command-interface", "state-interface", "limits", "mimic", "multiplier", "offset",
    "polarity", "PositivePolarity", "NegativePolarity", "position", "velocity", "acceleration",
    "effort", "torque", "current", "model", "map", "sys", "ros", "path", "pkg", "py", "module",
    "attr", "urdf", "mjcf", "usd", "camera", "force-torque", "imu", "type", "resolution",
    "fov", "update-rate", "observes", "rgb", "depth", "rgbd", "angular-velocity",
    "linear-acceleration", "force"
]
# fmt: on

# fmt: off
UNITS = [
    "mm", "cm", "m", "rad", "deg", "rad/s", "deg/s", "rad/s^2", "deg/s^2", "kg", "g", "kg*m^2",
    "N*m", "Hz"
]
# fmt: on
