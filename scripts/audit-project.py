#!/usr/bin/env python3

from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]


def require(path: str, text: str) -> None:
    content = (ROOT / path).read_text()
    if text not in content:
        raise SystemExit(f"{path}: missing {text!r}")


def reject(path: str, text: str) -> None:
    content = (ROOT / path).read_text()
    if text in content:
        raise SystemExit(f"{path}: compact App must not render {text!r}")


controller = "UIKitLifecycleDemo/GuidedExperimentViewController.swift"
catalog = "UIKitLifecycleDemo/GuidedExperiment.swift"
guide = "docs/guided-learning.md"
scheme = "UIKitLifecycleDemo.xcodeproj/xcshareddata/xcschemes/UIKitLifecycleDemo.xcscheme"
project = "UIKitLifecycleDemo.xcodeproj/project.pbxproj"

for token in ("guideSourceCue", "guideXcodeAction", "docs/guided-learning.md"):
    require(controller, token)

for token in (
    "snapshotReminder.id",
    "self?.reminders.first(where:",
):
    require("UIKitLifecycleDemo/ReminderListViewController.swift", token)

for token in (
    "action: #selector(toggleAutoScroll)",
    "@objc private func toggleAutoScroll()",
):
    require("UIKitLifecycleDemo/DemoLogPanelViewController.swift", token)
reject("UIKitLifecycleDemo/DemoLogPanelViewController.swift", "toggleAutoScroll(action)")

for verbose_surface in ("experiment.title", "experiment.goal", "guideGoal"):
    reject(controller, verbose_surface)

for verbose_field in (
    "predictionQuestion",
    "expectedLogs",
    "understandingQuestion",
    "recap",
    "victoryCondition",
):
    reject(controller, verbose_field)
    reject(catalog, verbose_field)

for token in ("sourceFile", "sourceAnchor", "xcodeAction"):
    require(catalog, token)

catalog_text = (ROOT / catalog).read_text()
source_cues = re.findall(
    r'sourceFile:\s*"([^"]+)",\s*sourceAnchor:\s*"([^"]+)"',
    catalog_text,
)
if len(source_cues) != 9:
    raise SystemExit(f"{catalog}: expected 9 source cues, found {len(source_cues)}")
for source_file, source_anchor in source_cues:
    source_path = ROOT / "UIKitLifecycleDemo" / source_file
    if not source_path.is_file():
        raise SystemExit(f"{catalog}: source file does not exist: {source_file}")
    if source_anchor not in source_path.read_text():
        raise SystemExit(
            f"{catalog}: source anchor does not exist: "
            f"{source_file} -> {source_anchor}"
        )

experiment_ids = re.findall(r'GuidedStep\(\s*id:\s*"([^"]+)"', catalog_text)
if len(experiment_ids) != 9:
    raise SystemExit(f"{catalog}: expected 9 experiment ids, found {len(experiment_ids)}")
if len(set(experiment_ids)) != len(experiment_ids):
    raise SystemExit(f"{catalog}: duplicate experiment ids")

xcode_actions = re.findall(r'xcodeAction:\s*"([^"]+)"', catalog_text)
if len(xcode_actions) != 9:
    raise SystemExit(f"{catalog}: expected 9 Xcode actions, found {len(xcode_actions)}")
lldb_command = re.compile(
    r"\b(?:bt(?:\s+all)?|po|expr|thread\s+(?:backtrace|info|list))\b",
    re.IGNORECASE,
)
for action in xcode_actions:
    if lldb_command.search(action):
        raise SystemExit(
            f"{catalog}: App Xcode cue must describe the action, "
            f"while LLDB commands stay in docs: {action}"
        )

guide_text = (ROOT / guide).read_text()
card_matches = re.findall(
    r"<!-- experiment-card: ([a-z0-9-]+) -->\s*(.*?)\s*"
    r"<!-- /experiment-card -->",
    guide_text,
    re.DOTALL,
)
card_ids = [card_id for card_id, _ in card_matches]
if card_ids != experiment_ids:
    raise SystemExit(
        f"{guide}: experiment cards must match catalog order; "
        f"expected {experiment_ids}, found {card_ids}"
    )

required_card_fields = (
    "学习目标",
    "机制",
    "真实源码锚点",
    "App 操作",
    "Xcode / LLDB 操作",
    "预期真实证据",
    "Reset / 复验",
    "误区 / 边界",
    "思考题",
)
for (card_id, card), (source_file, source_anchor) in zip(
    card_matches,
    source_cues,
):
    compact_length = len(re.sub(r"\s+", "", card))
    if compact_length < 500:
        raise SystemExit(
            f"{guide}: {card_id} is too short for a standalone experiment card "
            f"({compact_length} non-whitespace characters)"
        )

    for field in required_card_fields:
        matches = re.findall(
            rf"^### {re.escape(field)}\s*$\n(.*?)(?=^### |\Z)",
            card,
            re.MULTILINE | re.DOTALL,
        )
        if len(matches) != 1 or not matches[0].strip():
            raise SystemExit(
                f"{guide}: {card_id} must contain one non-empty "
                f"'### {field}' section"
            )

    if source_file not in card or source_anchor not in card:
        raise SystemExit(
            f"{guide}: {card_id} must cite its exact catalog source cue: "
            f"{source_file} -> {source_anchor}"
        )
    if "```lldb" not in card:
        raise SystemExit(f"{guide}: {card_id} must include runnable LLDB commands")
    if "？" not in re.search(
        r"^### 思考题\s*$\n(.*?)(?=^### |\Z)",
        card,
        re.MULTILINE | re.DOTALL,
    ).group(1):
        raise SystemExit(f"{guide}: {card_id} thought question must be explicit")

for token in (
    'selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"',
    'disableMainThreadChecker = "NO"',
    'queueDebuggingEnabled = "Yes"',
    'viewDebuggingEnabled = "Yes"',
    'key = "PrefersMallocStackLoggingLite"',
    'key = "MallocStackLogging"',
):
    require(scheme, token)

for token in (
    'SWIFT_OPTIMIZATION_LEVEL = "-Onone"',
    "ENABLE_TESTABILITY = YES",
    "DEBUG_INFORMATION_FORMAT = dwarf",
    'SWIFT_OPTIMIZATION_LEVEL = "-O"',
    'DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"',
    "SWIFT_COMPILATION_MODE = wholemodule",
    "VALIDATE_PRODUCT = YES",
):
    require(project, token)

makefile = "Makefile"
for token in ("build-release:", "release-check: check build-release test-ui"):
    require(makefile, token)

print(
    "project audit passed: compact App guide, 9 standalone experiment cards, "
    "9 real source cues, debugger-ready scheme and Debug/Release gates"
)
