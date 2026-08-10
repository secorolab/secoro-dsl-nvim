"""The DSLs the server knows, and which file belongs to which.

A language module declares: NAME, PACKAGE, EXTENSIONS, metamodel(path),
BLOCK_PATTERNS and BLOCK_KIND for the outline, HOVER_DOCS, and the plain word
lists completion is built from (KEYWORDS, optionally TYPES and UNITS).
"""

from os.path import splitext

from . import coord_dsl, motion_spec, robbdd, scene_dsl

MODULES = (motion_spec, scene_dsl, coord_dsl, robbdd)

_BY_EXTENSION = {extension: module for module in MODULES for extension in module.EXTENSIONS}


def for_path(path: str):
    """The language module for a file, by extension; None if it is not ours."""
    return _BY_EXTENSION.get(splitext(path)[1].lstrip("."))
