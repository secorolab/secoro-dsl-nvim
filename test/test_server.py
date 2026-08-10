#!/usr/bin/env python3
"""Self-check for the language server: run `python3 test/test_server.py`."""

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "server"))

import languages  # noqa: E402
import secoro_dsl_lsp as lsp  # noqa: E402

SOURCES = {
    language.NAME: (ROOT / "test" / f"coverage.{language.NAME}").read_text()
    for language in languages.MODULES
}

# Real models, to check the outline and the diagnostics against something the
# toolchain accepts.
WORKSPACE = ROOT.parent
SCENE_EXAMPLES = WORKSPACE / "scene-dsl" / "examples" / "models"
MOTION_MODELS = WORKSPACE / "motion-spec-dsl" / "models"
BDD_EXAMPLES = WORKSPACE / "robbdd" / "examples" / "models"


def blocks_of(name):
    return lsp.blocks(SOURCES[name], languages.for_path(f"x.{name}").BLOCK_PATTERNS)


def test_every_language_is_reachable_by_extension():
    for module in languages.MODULES:
        for extension in module.EXTENSIONS:
            assert languages.for_path(f"/m/model.{extension}") is module, extension
    assert languages.for_path("/m/notes.txt") is None
    assert languages.for_path("/m/no-extension") is None


def test_bdd_extensions_pick_their_own_metamodel():
    if _skip_without("robbdd"):
        return
    # Only the execution metamodel knows how a variant is run.
    assert "ScenarioExecution" in languages.robbdd.metamodel("/m/x.bddx")
    assert "ScenarioExecution" not in languages.robbdd.metamodel("/m/x.bdd")


def test_scene_extensions_pick_their_own_metamodel():
    if _skip_without("scene_dsl"):
        return
    scene = languages.scene_dsl
    # Only the scenex grammar knows about instances, trees and sensors.
    assert "SceneInstance" not in scene.metamodel("/m/lab.scene")
    for path in ["/m/lab.scenex", "/m/kinova.ktree"]:
        assert "SceneInstance" in scene.metamodel(path), path


def _skip_without(package):
    try:
        __import__(package)
        return False
    except ImportError:
        print(f"     ({package} not importable; skipped)")
        return True


def test_robmot_outline_nests_sections_under_their_motion():
    found = {name: (kw, depth) for kw, name, _, _, depth in blocks_of("robmot")}
    assert found["cover"] == ("guarded-motion", 0), found.get("cover")
    assert found["cover-handler"] == ("constraint-handler", 0)
    assert found["shared"] == ("context", 0)
    for section in ["while", "until", "monitors", "controllers", "solvers"]:
        assert found[section][1] == 1, (section, found[section])
    # Entries written name-first are found too, under the section holding them.
    assert found["m1"][0] == "monitor" and found["m1"][1] == 2, found["m1"]
    assert found["arm"][0] == "serial-chain" and found["arm"][1] == 2, found["arm"]


def test_scenex_outline_nests_frames_under_bodies():
    found = {name: (kw, depth) for kw, name, _, _, depth in blocks_of("scenex")}
    assert found["cov_template"] == ("ktree", 0)
    assert found["cov_base"] == ("body", 1)
    assert found["cov_base_com"] == ("frame", 2)
    assert found["cov_base_com_in_base"] == ("pose", 3)
    # `ktree inst ... of <t>` is a declaration with no block at all.
    assert found["cov_arm1"] == ("ktree inst", 0)
    # `scene: <cov_scene>` is a field key, not a second `scene` declaration.
    top = [(kw, name) for kw, name, _, _, depth in blocks_of("scenex") if depth == 0]
    assert sum(1 for kw, _ in top if kw == "scene") == 1, top


def test_fsm_outline_lists_transitions_and_reactions():
    found = {name: (kw, depth) for kw, name, _, _, depth in blocks_of("fsm")}
    assert found["cov_events"] == ("evt loop", 0)
    assert found["cov_fsm"] == ("fsm", 0)
    for section in ["states", "transitions", "reactions"]:
        assert found[section][1] == 1, (section, found[section])
    assert found["T_SELF"][1] == 2, found["T_SELF"]
    assert found["R_DONE"][1] == 2, found["R_DONE"]
    assert found["fires"][1] == 3, found["fires"]


def test_bdd_outline_lists_stories_templates_and_fluents():
    found = {name: (kw, depth) for kw, name, _, _, depth in blocks_of("bdd")}
    assert found["cov-template"] == ("Scenario Template", 0)
    assert found["cov-story"] == ("User Story", 0)
    assert found["evt-start"] == ("Event", 0)
    assert found["cov-const-set"] == ("const set", 0)
    # A variant nests under its story, and a fluent under the clause holding it.
    assert found["cov-table"] == ("Scenario", 1)
    assert found["x"] == ("for all", 1)
    assert found["fc-located"][0] == "holds"
    assert found["fc-located"][1] > found["x"][1]


def test_bddx_outline_lists_policies_and_their_observations():
    # `.bdd` and `.bddx` share a parser and a module, so one coverage file holds
    # both halves.
    found = {name: (kw, depth) for kw, name, _, _, depth in blocks_of("bdd")}
    assert found["cov-exec"] == ("Scenario Exec", 0)
    assert found["cov-ros-bhv"] == ("bhv impl", 0)
    assert found["cov-entity-state"] == ("obs provider", 0)
    assert found["cov-equals"] == ("obs policy", 0)
    assert found["object-pose"] == ("observation", 1)


def test_a_one_line_block_does_not_swallow_the_next():
    ktree = (SCENE_EXAMPLES / "kinova_gen3_7dof.ktree").read_text()
    patterns = languages.scene_dsl.BLOCK_PATTERNS
    frames = {name: depth for kw, name, _, _, depth in lsp.blocks(ktree, patterns) if kw == "frame"}
    assert frames["base_link_origin"] == frames["joint_1_anchor"] == 2, frames


def test_find_declaration():
    for name, word, expected in [
        ("robmot", "cover", "guarded-motion (ns=app) cover {"),
        ("robmot", "here", "            pose here = snapshot"),
        ("robmot", "tan", "        tan:  moving"),
        ("robmot", "m1", "        m1: monitor"),
        ("robmot", "adm", "        admittance adm = {"),
        ("scenex", "cov_template", "ktree cov_template {"),
        ("scenex", "cov_arm1", "ktree inst (ns=cov) cov_arm1 of <cov_template>"),
        ("scenex", "cov_base_origin", "        frame cov_base_origin { }"),
        ("scenex", "ball", "    object ball,"),
        ("fsm", "E_STEP", "    evt E_STEP,"),
        ("fsm", "S_START", "        S_START,"),
        ("fsm", "T_SELF", "        T_SELF         { from:"),
        ("fsm", "cov_fsm", "fsm (ns=cov) cov_fsm {"),
    ]:
        found = lsp.find_declaration(SOURCES[name], word)
        assert found is not None, f"no declaration found for {name}:{word}"
        line, column = found
        text = SOURCES[name].splitlines()[line]
        assert text.startswith(expected), (name, word, text)
        assert text[column : column + len(word)] == word, (name, word, text)

    assert lsp.find_declaration(SOURCES["robmot"], "not-a-name") is None


def test_word_at():
    source = "    hold-x: keeping <shared.world.ee>.position.x equal to 1.0 m"
    assert lsp.word_at(source, 0, 5) == "hold-x"
    assert lsp.word_at(source, 0, 25) == "shared"
    assert lsp.word_at(source, 0, 99) == "m"
    assert lsp.word_at(source, 5, 0) == ""


def test_diagnostics_of_the_workspace_models():
    models = [
        *SCENE_EXAMPLES.glob("*"),
        *MOTION_MODELS.glob("*/*.robmot"),
        *MOTION_MODELS.glob("*/*.fsm"),
        *BDD_EXAMPLES.glob("*.bdd"),
        *BDD_EXAMPLES.glob("*.bddx"),
    ]
    checked = 0
    for model in sorted(models):
        module = languages.for_path(str(model))
        if module is None or _importable(module) is False:
            continue
        found = lsp._diagnostics(model.as_uri(), model.read_text())
        assert not found, (model.name, [d.message for d in found])
        checked += 1
    assert checked > 10, checked


def _importable(module):
    try:
        __import__(module.PACKAGE)
        return True
    except ImportError:
        print(f"     ({module.PACKAGE} not importable; its models skipped)")
        return False


def test_diagnostics_report_the_real_error():
    cases = [
        (
            SCENE_EXAMPLES / "broken.scenex",
            "ns lab = 'https://example.org/'\nbody nope { }\n",
            1,
            "body",
        ),
        (
            SCENE_EXAMPLES / "broken.scenex",
            "ns lab = 'https://example.org/'\nktree inst (ns=lab) a of <missing>\n",
            1,
            "missing",
        ),
        (
            BDD_EXAMPLES / "broken.bdd",
            'import "lab.scene"\n'
            "ns b = 'https://example.org/b/'\n"
            "Task (ns=b) t\n"
            "Event (ns=b) e1\n"
            "Event (ns=b) e2\n"
            "Scenario Template (ns=b) tmpl {\n"
            "    duration: from <e1> until <e2>\n"
            "    task: <t>\n"
            "    var robot\n"
            "    var obj\n"
            "    When:\n"
            "        Behaviour (ns=b) bhv {\n"
            "            duration: from <e1> until <e2>\n"
            "            <robot> picks <obj>\n"
            "        }\n"
            "    Then: fc: holds(<robot> can reach <nope>, after <e1>)\n"
            "}\n",
            15,
            "nope",
        ),
        (
            MOTION_MODELS / "broken.fsm",
            'ns f = "https://example.org/"\n'
            "evt loop (ns=f) el { evt E_A }\n"
            "fsm (ns=f) m {\n"
            "    states { S_A }\n"
            "    evt loop: <el>\n"
            "    start: <S_NOPE>\n"
            "    end: <S_A>\n"
            "    transitions { T_A { from: <S_A>, to: <S_A> } }\n"
            "    reactions { R_A { when: <el.E_A>, do: <T_A> } }\n"
            "}\n",
            5,
            "S_NOPE",
        ),
    ]
    for path, source, line, needle in cases:
        module = languages.for_path(str(path))
        if not _importable(module):
            continue
        found = lsp._diagnostics(path.as_uri(), source)
        assert len(found) == 1, (path.name, found)
        assert needle in found[0].message, found[0].message
        assert found[0].range.start.line == line, (found[0].message, found[0].range)


def test_diagnostic_from_imported_file_is_pinned_to_line_one():
    error = Exception("bad thing")
    error.line, error.col, error.filename = 42, 7, "/models/lab.scenex"
    diagnostic = lsp._as_diagnostic(error, "/models/motion.robmot")
    assert diagnostic.range.start.line == 0
    assert "lab.scenex:42:7" in diagnostic.message

    error.filename = "/models/motion.robmot"
    diagnostic = lsp._as_diagnostic(error, "/models/motion.robmot")
    assert diagnostic.range.start.line == 41
    assert diagnostic.range.start.character == 6
    assert diagnostic.message == "bad thing"


def test_completion_offers_each_language_its_own_words():
    offered = {
        module.NAME: {item.label for item in lsp.completions(module)}
        for module in languages.MODULES
    }
    assert "guarded-motion" in offered["robmot"] and "achd" in offered["robmot"]
    assert "ktree" in offered["scenex"] and "force-torque" in offered["scenex"]
    assert "transitions" in offered["fsm"] and "fires" in offered["fsm"]
    assert "Scenario" in offered["bdd"] and "holds" in offered["bdd"]
    assert "obs" in offered["bdd"] and "horizon" in offered["bdd"]
    # No language offers another's vocabulary.
    assert "guarded-motion" not in offered["scenex"] | offered["fsm"]
    assert "ktree" not in offered["robmot"] | offered["fsm"]
    assert "reactions" not in offered["robmot"] | offered["scenex"]
    assert "holds" not in offered["scenex"] | offered["fsm"]
    # Every offered word carries a one-line detail.
    for module in languages.MODULES:
        for item in lsp.completions(module):
            assert item.detail, (module.NAME, item.label)


def test_hover_documents_what_completion_offers():
    for module in languages.MODULES:
        assert module.HOVER_DOCS, module.NAME
        documented = set(module.HOVER_DOCS)
        assert documented <= set(module.KEYWORDS) | {"@disable"}, (
            module.NAME,
            documented - set(module.KEYWORDS),
        )


if __name__ == "__main__":
    failures = 0
    for name, case in sorted(globals().items()):
        if name.startswith("test_") and callable(case):
            try:
                case()
                print(f"ok   {name}")
            except AssertionError as exc:
                failures += 1
                print(f"FAIL {name}: {exc}")
    sys.exit(1 if failures else 0)
