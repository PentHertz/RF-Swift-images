#!/usr/bin/env python3
# This file is part of the RF Swift project (GPL-3.0-or-later, see LICENSE).
#
# Adapted from scripts/check-license-policy.py of Drost Community Edition
# (https://github.com/drost-ai/drost-community), Copyright 2026 Drost, licensed
# under the Apache License, Version 2.0 (scripts/compliance/LICENSE-Apache-2.0).
# Changed for RF Swift: matching on package URLs, Debian source packages, file
# locations, install functions and an image inventory; review and notice
# entries reported with their evidence; SPDX input; JSON report; policy checks.
"""Check a CycloneDX or SPDX JSON SBOM against compliance/license-policy.json.

Exit status: 0 when no blocked component is found, 1 when one is, 2 on bad
input (unreadable SBOM, inventory or policy).

Each policy entry says how to recognise the component in its "match" object:
  names              package names (also a Debian package's source name and
                     the name part of its purl), compared case-insensitively
  purls              purl patterns (fnmatch, case-insensitive, without the
                     version), e.g. "pkg:npm/@anthropic-ai/claude-code*"
  paths              path prefixes, compared with the locations syft records
                     for each package and with inventory paths ("/opt/x/"
                     matches /opt/x and everything under it)
  executables        command names found in the image (inventory "exe" lines)
  install_functions  RF Swift install functions recorded in the image
                     (/var/lib/db/rfswift_components.lst, inventory "func")

The inventory (--inventory, from scripts/compliance/image-inventory.sh) is a
tab-separated file of "kind<TAB>value..." lines: exe NAME [RESOLVED_PATH],
path PATH, func NAME, deb SOURCE SOURCE_VERSION BINARY VERSION and
git PATH REMOTE COMMIT. A bare line is read as a path when it starts with "/"
and as an executable name otherwise. Lines starting with "#" are ignored.
"""

from __future__ import annotations

import argparse
from fnmatch import fnmatchcase
import json
from pathlib import Path
import sys
from urllib.parse import unquote

SECTIONS = (
    ("blocked_components", "BLOCKED"),
    ("review_required_components", "REVIEW"),
    ("notice_required_components", "NOTICE"),
)
MATCH_KEYS = ("names", "purls", "paths", "executables", "install_functions")
MAX_EVIDENCE = 8


class InputError(Exception):
    """An input file is missing, unreadable or malformed."""


def read_json(path: Path, what: str) -> object:
    try:
        with path.open(encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, ValueError) as error:
        raise InputError(f"cannot read {what} {path}: {error}") from error


def purl_base(purl: str) -> str:
    """pkg:type/namespace/name@version?qualifiers#subpath -> decoded pkg:type/namespace/name.

    The version is cut from the last path segment only, so a scope written
    as a literal "@" ("pkg:npm/@scope/name") survives, as does "%40scope".
    """
    base = purl.split("#", 1)[0].split("?", 1)[0]
    head, separator, tail = base.rpartition("/")
    return unquote(head + separator + tail.split("@", 1)[0]).casefold()


def purl_names(purl: str) -> set[str]:
    base = purl_base(purl)
    if ":" not in base:
        return set()
    path = base.split(":", 1)[1]
    parts = path.split("/")[1:]  # drop the type
    if not parts:
        return set()
    names = {parts[-1]}
    if len(parts) > 1:
        names.add("/".join(parts))
        names.add("/".join(parts[1:]))
    return {name for name in names if name}


class Component:
    def __init__(self, name: str, version: str = "", purl: str = "", kind: str = "",
                 source: str = "", locations: list[str] | None = None) -> None:
        self.name = name
        self.version = version
        self.purl = purl
        self.kind = kind
        self.source = source
        self.locations = locations or []

    def names(self) -> set[str]:
        names = {self.name.casefold()} if self.name else set()
        if self.source:
            names.add(self.source.casefold())
        if self.purl:
            names |= purl_names(self.purl)
        return names

    def describe(self) -> str:
        text = self.name or "(unnamed)"
        if self.version:
            text += f" {self.version}"
        details = [self.kind or "", self.purl or ""]
        if self.source and self.source != self.name:
            details.append(f"source {self.source}")
        details = [detail for detail in details if detail]
        if details:
            text += f" ({', '.join(details)})"
        if self.locations:
            text += f" at {self.locations[0]}"
        return text


def cyclonedx_components(sbom: dict) -> list[Component]:
    found: list[Component] = []

    def walk(items: object) -> None:
        if not isinstance(items, list):
            return
        for item in items:
            if not isinstance(item, dict):
                continue
            props = {}
            locations = []
            for prop in item.get("properties") or []:
                if not isinstance(prop, dict):
                    continue
                key, value = prop.get("name"), prop.get("value")
                if not isinstance(key, str) or not isinstance(value, str):
                    continue
                if key.startswith("syft:location:") and key.endswith(":path"):
                    locations.append(value)
                else:
                    props.setdefault(key, value)
            name = item.get("name")
            if isinstance(name, str):
                found.append(Component(
                    name=name,
                    version=str(item.get("version") or ""),
                    purl=str(item.get("purl") or ""),
                    kind=props.get("syft:package:type", str(item.get("type") or "")),
                    source=props.get("syft:metadata:source", ""),
                    locations=locations,
                ))
            walk(item.get("components"))

    walk(sbom.get("components"))
    return found


def spdx_components(sbom: dict) -> list[Component]:
    found: list[Component] = []
    for package in sbom.get("packages") or []:
        if not isinstance(package, dict) or not isinstance(package.get("name"), str):
            continue
        purl = ""
        for ref in package.get("externalRefs") or []:
            if isinstance(ref, dict) and ref.get("referenceType") == "purl":
                purl = str(ref.get("referenceLocator") or "")
                break
        locations = []
        info = package.get("sourceInfo")
        if isinstance(info, str) and ": " in info:
            locations = [part.strip() for part in info.split(": ", 1)[1].split(", ")
                         if part.strip().startswith("/")]
        kind = purl.split("/", 1)[0].removeprefix("pkg:") if purl.startswith("pkg:") else ""
        found.append(Component(
            name=package["name"],
            version=str(package.get("versionInfo") or ""),
            purl=purl,
            kind=kind,
            locations=locations,
        ))
    return found


def load_sbom(path: Path) -> tuple[str, list[Component]]:
    sbom = read_json(path, "SBOM")
    if not isinstance(sbom, dict):
        raise InputError(f"{path} is not a JSON object")
    if sbom.get("bomFormat") == "CycloneDX" or "components" in sbom:
        return "CycloneDX", cyclonedx_components(sbom)
    if "spdxVersion" in sbom or "packages" in sbom:
        return "SPDX", spdx_components(sbom)
    raise InputError(f"{path} is neither a CycloneDX nor an SPDX JSON document")


class Inventory:
    def __init__(self) -> None:
        self.executables: dict[str, str] = {}
        self.paths: list[str] = []
        self.functions: set[str] = set()
        self.debs: list[tuple[str, str]] = []  # (name, description)
        self.lines = 0

    def load(self, path: Path) -> None:
        try:
            text = path.read_text(encoding="utf-8", errors="replace")
        except OSError as error:
            raise InputError(f"cannot read inventory {path}: {error}") from error
        for raw in text.splitlines():
            line = raw.rstrip("\r")
            if not line.strip() or line.lstrip().startswith("#"):
                continue
            self.lines += 1
            fields = line.split("\t")
            kind = fields[0].strip()
            values = [field.strip() for field in fields[1:]]
            if len(fields) == 1:
                value = kind
                if value.startswith("/"):
                    self.paths.append(value)
                else:
                    self.executables.setdefault(value, "")
            elif kind == "exe" and values and values[0]:
                resolved = values[1] if len(values) > 1 else ""
                self.executables[values[0]] = resolved
                if resolved.startswith("/"):
                    self.paths.append(resolved)
            elif kind == "path" and values and values[0].startswith("/"):
                self.paths.append(values[0])
            elif kind == "func" and values and values[0]:
                self.functions.add(values[0])
            elif kind == "deb" and values:
                description = "deb " + " ".join(value for value in values if value)
                for name in (values[0], values[2] if len(values) > 2 else ""):
                    if name:
                        self.debs.append((name.split(":", 1)[0].casefold(), description))
            elif kind == "git" and values and values[0].startswith("/"):
                self.paths.append(values[0])
            # Unknown kinds are ignored so newer inventories stay readable.


def path_matches(prefix: str, path: str) -> bool:
    if prefix.endswith("/"):
        return path == prefix.rstrip("/") or path.startswith(prefix)
    return path.startswith(prefix)


def entry_match(entry: dict) -> dict:
    match = entry.get("match")
    if isinstance(match, dict):
        return match
    # Drost-style entry: only a name.
    return {"names": [entry["name"]]} if isinstance(entry.get("name"), str) else {}


def find_evidence(entry: dict, components: list[Component], inventory: Inventory) -> list[str]:
    match = entry_match(entry)
    names = {str(name).casefold() for name in match.get("names") or []}
    purls = [purl_base(str(pattern)) for pattern in match.get("purls") or []]
    paths = [str(prefix) for prefix in match.get("paths") or []]
    executables = {str(name) for name in match.get("executables") or []}
    functions = {str(name) for name in match.get("install_functions") or []}

    evidence: list[str] = []
    for component in components:
        reasons = []
        if names and component.names() & names:
            reasons.append("name")
        if purls and component.purl and any(
                fnmatchcase(purl_base(component.purl), pattern) for pattern in purls):
            reasons.append("purl")
        if paths and any(path_matches(prefix, location)
                         for prefix in paths for location in component.locations):
            reasons.append("path")
        if reasons:
            evidence.append(f"sbom: {component.describe()} [{'+'.join(reasons)}]")
    for function in sorted(functions & inventory.functions):
        evidence.append(f"inventory: install function {function}")
    for name in sorted(executables & set(inventory.executables)):
        resolved = inventory.executables[name]
        evidence.append(f"inventory: command {name}" + (f" -> {resolved}" if resolved else ""))
    seen_paths = set()
    for path in inventory.paths:
        if path not in seen_paths and any(path_matches(prefix, path) for prefix in paths):
            seen_paths.add(path)
            evidence.append(f"inventory: path {path}")
    for name, description in inventory.debs:
        if name in names:
            evidence.append(f"inventory: {description}")
    unique = list(dict.fromkeys(evidence))
    return unique


def validate_policy(policy: object) -> tuple[list[str], list[str]]:
    """Return (errors, warnings) for the policy document."""
    errors: list[str] = []
    warnings: list[str] = []
    if not isinstance(policy, dict):
        return ["the policy is not a JSON object"], warnings
    tree = policy.get("image_tree")
    tree = tree if isinstance(tree, dict) else {}
    seen: dict[str, str] = {}
    for section, _label in SECTIONS:
        entries = policy.get(section, [])
        if not isinstance(entries, list):
            errors.append(f"{section} is not a list")
            continue
        for position, entry in enumerate(entries):
            where = f"{section}[{position}]"
            if not isinstance(entry, dict):
                errors.append(f"{where} is not an object")
                continue
            key = str(entry.get("id") or entry.get("name") or "")
            if not key:
                errors.append(f"{where} has no id or name")
            elif key in seen:
                errors.append(f"{where}: id {key!r} is also used in {seen[key]}")
            else:
                seen[key] = section
            if not isinstance(entry.get("reason"), str) or not entry["reason"].strip():
                errors.append(f"{where} ({key}) has no reason")
            match = entry_match(entry)
            if not any(match.get(name) for name in MATCH_KEYS):
                errors.append(f"{where} ({key}) has nothing to match on")
            unknown = sorted(set(match) - set(MATCH_KEYS))
            if unknown:
                errors.append(f"{where} ({key}) has unknown match keys: {', '.join(unknown)}")
            for name in MATCH_KEYS:
                value = match.get(name, [])
                if not isinstance(value, list) or not all(isinstance(item, str) and item for item in value):
                    errors.append(f"{where} ({key}): match.{name} must be a list of non-empty strings")
            if tree and isinstance(entry.get("images"), list):
                listed = set(entry["images"])
                needed = set()
                for image in entry.get("installed_in") or []:
                    needed.add(image)
                    needed |= descendants(tree, image)
                missing = sorted(needed - listed)
                if missing:
                    warnings.append(f"{key}: images lacks {', '.join(missing)} (built on installed_in)")
                known = set(tree) | {child for children in tree.values()
                                     if isinstance(children, list) for child in children}
                stray = sorted(image for image in listed if image not in known)
                if stray:
                    warnings.append(f"{key}: images not in image_tree: {', '.join(stray)}")
    return errors, warnings


def descendants(tree: dict, image: str) -> set[str]:
    found: set[str] = set()
    pending = [image]
    while pending:
        for child in tree.get(pending.pop(), []) or []:
            if isinstance(child, str) and child not in found:
                found.add(child)
                pending.append(child)
    return found


def report_entry(entry: dict, evidence: list[str]) -> dict:
    keys = ("id", "name", "status", "images", "licence", "reason", "decision", "keep", "found_in")
    item = {key: entry[key] for key in keys if key in entry}
    item["evidence"] = evidence
    return item


def print_entry(label: str, item: dict, stream) -> None:
    title = item.get("id") or item.get("name")
    if item.get("name") and item.get("name") != title:
        title = f"{title} ({item['name']})"
    print(f"{label}: {title}: {item.get('reason', '')}", file=stream)
    if item.get("licence"):
        print(f"  licence: {item['licence']}", file=stream)
    for key in ("decision", "keep"):
        if item.get(key):
            print(f"  {key}: {item[key]}", file=stream)
    for line in item["evidence"][:MAX_EVIDENCE]:
        print(f"  found: {line}", file=stream)
    if len(item["evidence"]) > MAX_EVIDENCE:
        print(f"  found: ... and {len(item['evidence']) - MAX_EVIDENCE} more", file=stream)


def main() -> int:
    root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("sbom", type=Path, help="CycloneDX or SPDX JSON SBOM (syft output)")
    parser.add_argument("--policy", type=Path, default=root / "compliance" / "license-policy.json",
                        help="licence policy JSON (default: compliance/license-policy.json)")
    parser.add_argument("--inventory", type=Path, action="append", default=[],
                        help="image inventory from image-inventory.sh (repeatable)")
    parser.add_argument("--json", type=Path, dest="json_report",
                        help="also write the report as JSON to this file")
    args = parser.parse_args()

    try:
        policy = read_json(args.policy, "policy")
        errors, warnings = validate_policy(policy)
        if errors:
            for error in errors:
                print(f"policy error: {args.policy}: {error}", file=sys.stderr)
            return 2
        for warning in warnings:
            print(f"policy warning: {warning}", file=sys.stderr)
        sbom_format, components = load_sbom(args.sbom)
        inventory = Inventory()
        for path in args.inventory:
            inventory.load(path)
    except InputError as error:
        print(f"error: {error}", file=sys.stderr)
        return 2

    found: dict[str, list[dict]] = {}
    not_found: dict[str, list[str]] = {}
    for section, _label in SECTIONS:
        found[section] = []
        not_found[section] = []
        for entry in policy.get(section, []):
            evidence = find_evidence(entry, components, inventory)
            if evidence:
                found[section].append(report_entry(entry, evidence))
            else:
                not_found[section].append(str(entry.get("id") or entry.get("name")))

    print(f"SBOM: {args.sbom} ({sbom_format}, {len(components)} components)")
    for path in args.inventory:
        print(f"Inventory: {path}")
    if not args.inventory:
        print("Inventory: none (tools installed from git or tarballs may be missed; "
              "see scripts/compliance/image-inventory.sh)")
    for section, label in SECTIONS[1:]:
        for item in found[section]:
            print_entry(label, item, sys.stdout)
    for item in found["blocked_components"]:
        print_entry("BLOCKED", item, sys.stderr)

    blocked, review, notice = (len(found[section]) for section, _ in SECTIONS)
    print(f"Summary: {blocked} blocked, {review} review-required, {notice} notice-required.")

    if args.json_report:
        report = {
            "schema_version": 1,
            "sbom": str(args.sbom),
            "sbom_format": sbom_format,
            "component_count": len(components),
            "inventory": [str(path) for path in args.inventory],
            "policy": str(args.policy),
            "policy_warnings": warnings,
            "blocked": found["blocked_components"],
            "review_required": found["review_required_components"],
            "notice_required": found["notice_required_components"],
            "not_found": {
                "blocked": not_found["blocked_components"],
                "review_required": not_found["review_required_components"],
                "notice_required": not_found["notice_required_components"],
            },
        }
        try:
            args.json_report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        except OSError as error:
            print(f"error: cannot write {args.json_report}: {error}", file=sys.stderr)
            return 2

    if blocked:
        print(f"Release blocked by {blocked} component(s).", file=sys.stderr)
        return 1
    print("No blocked components detected.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
