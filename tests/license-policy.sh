#!/usr/bin/env bash
# Licence policy checker (scripts/compliance/check-license-policy.py) against small
# synthetic SBOMs and inventories, and the SBOM / inventory wrappers with syft and
# docker stubbed out. No network, no Docker.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
fixture=$(mktemp -d)
trap 'rm -rf "$fixture"' EXIT
checker=scripts/compliance/check-license-policy.py

fail() {
    echo "FAIL: $*" >&2
    cat "$fixture/out" "$fixture/err" >&2 2> /dev/null || true
    exit 1
}
# run_check STATUS ARGS...: run the checker, require its exit status
run_check() {
    local want=$1 got=0
    shift
    python3 -I "$checker" "$@" > "$fixture/out" 2> "$fixture/err" || got=$?
    [[ $got == "$want" ]] || fail "exit $got, expected $want: $*"
}
has() { grep -qF -- "$1" "$fixture/${2:-out}" || fail "'$1' not in ${2:-out}"; }
lacks() { if grep -qF -- "$1" "$fixture/${2:-out}"; then fail "'$1' in ${2:-out}"; fi; }

for script in scripts/compliance/*.sh; do bash -n "$script"; done

cat > "$fixture/policy.json" << 'EOF'
{
  "schema_version": 1,
  "image_tree": {"base": ["child"], "child": ["grandchild"]},
  "blocked_components": [
    {"id": "forbidden", "reason": "never ship", "match": {"purls": ["pkg:pypi/forbidden-tool*"]}}
  ],
  "review_required_components": [
    {"id": "vendor-sdk", "name": "Vendor SDK", "reason": "proprietary", "decision": "ask the vendor",
     "installed_in": ["base"], "images": ["base", "child", "grandchild"],
     "match": {"paths": ["/opt/vendor/"], "executables": ["vendortool"], "install_functions": ["vendor_install"]}},
    {"id": "agent", "reason": "all rights reserved", "match": {"purls": ["pkg:npm/@acme/agent*"]}},
    {"id": "nolicence", "reason": "no licence", "match": {"names": ["github.com/someone/tool"]}}
  ],
  "notice_required_components": [
    {"id": "nmap", "reason": "NPSL", "keep": "the copyright file", "match": {"names": ["nmap"]}}
  ]
}
EOF

# CycloneDX as syft writes it: purl with %40, Debian source in a property, locations as properties.
# The decoys must not match: other npm scope, sibling directory, other Go module, longer name.
cat > "$fixture/match.cdx.json" << 'EOF'
{"bomFormat": "CycloneDX", "specVersion": "1.6", "components": [
  {"type": "library", "name": "nmap-common", "version": "7.95+dfsg-3",
   "properties": [{"name": "syft:package:type", "value": "deb"},
                  {"name": "syft:metadata:source", "value": "nmap"},
                  {"name": "syft:location:0:path", "value": "/var/lib/dpkg/status"}]},
  {"type": "library", "name": "@acme/agent", "version": "2.0.0", "purl": "pkg:npm/%40acme/agent@2.0.0"},
  {"type": "library", "name": "libv", "version": "1",
   "properties": [{"name": "syft:location:0:path", "value": "/opt/vendor/lib/libv.so.1"}]},
  {"type": "library", "name": "agent", "version": "1.0.0", "purl": "pkg:npm/agent@1.0.0"},
  {"type": "library", "name": "other", "version": "1",
   "properties": [{"name": "syft:location:0:path", "value": "/opt/vendor-other/lib/libo.so"}]},
  {"type": "library", "name": "github.com/someone/tool-fork", "purl": "pkg:golang/github.com/someone/tool-fork@v1.0.0"},
  {"type": "library", "name": "nmap-foo", "version": "1"}
]}
EOF
run_check 0 "$fixture/match.cdx.json" --policy "$fixture/policy.json" --json "$fixture/report.json"
has "REVIEW: vendor-sdk (Vendor SDK): proprietary"
has "decision: ask the vendor"
has "/opt/vendor/lib/libv.so.1 [path]"
has "REVIEW: agent: all rights reserved"
has "NOTICE: nmap: NPSL"
has "keep: the copyright file"
has "Summary: 0 blocked, 2 review-required, 1 notice-required."
lacks "vendor-other"
lacks "agent 1.0.0"
lacks "nolicence"
lacks "nmap-foo"
[[ $(jq -c '[.review_required[].id]' "$fixture/report.json") == '["vendor-sdk","agent"]' ]] || fail "JSON review ids"
[[ $(jq -c '.not_found.review_required' "$fixture/report.json") == '["nolicence"]' ]] || fail "JSON not_found"
[[ $(jq -r '.sbom_format' "$fixture/report.json") == CycloneDX ]] || fail "JSON format"

# Nested CycloneDX components are walked too
cat > "$fixture/nested.cdx.json" << 'EOF'
{"bomFormat": "CycloneDX", "components": [
  {"type": "application", "name": "bundle", "components": [
    {"type": "library", "name": "github.com/someone/tool", "purl": "pkg:golang/github.com/someone/tool@v0.0.0-20200101000000-abcdef"}]}]}
EOF
run_check 0 "$fixture/nested.cdx.json" --policy "$fixture/policy.json"
has "REVIEW: nolicence: no licence"

# SPDX: purl from externalRefs, locations from sourceInfo
cat > "$fixture/match.spdx.json" << 'EOF'
{"spdxVersion": "SPDX-2.3", "packages": [
  {"name": "github.com/someone/tool", "versionInfo": "v0.0.0",
   "externalRefs": [{"referenceCategory": "PACKAGE-MANAGER", "referenceType": "purl",
                     "referenceLocator": "pkg:golang/github.com/someone/tool@v0.0.0"}]},
  {"name": "vendortool", "sourceInfo": "acquired package info from ELF binary: /opt/vendor/bin/vendortool"}
]}
EOF
run_check 0 "$fixture/match.spdx.json" --policy "$fixture/policy.json"
has "SPDX, 2 components"
has "REVIEW: nolicence"
has "REVIEW: vendor-sdk"
lacks "NOTICE:"

# Inventory alone finds what the SBOM does not list
printf '{"bomFormat": "CycloneDX", "components": []}\n' > "$fixture/empty.cdx.json"
printf '# comment\nfunc\tvendor_install\nexe\tvendortool\t/opt/vendor/bin/vendortool\ndeb\tnmap\t7.95\tnmap:amd64\t7.95\n/opt/vendor\nunknown\tkind\n' \
    > "$fixture/inventory.tsv"
run_check 0 "$fixture/empty.cdx.json" --policy "$fixture/policy.json" --inventory "$fixture/inventory.tsv"
has "found: inventory: install function vendor_install"
has "found: inventory: command vendortool -> /opt/vendor/bin/vendortool"
has "found: inventory: path /opt/vendor"
has "found: inventory: deb nmap 7.95 nmap:amd64 7.95"
has "Summary: 0 blocked, 1 review-required, 1 notice-required."

# Blocked component: exit 1, reported on stderr
printf '{"bomFormat": "CycloneDX", "components": [{"name": "forbidden-tool", "purl": "pkg:pypi/forbidden-tool@1.0"}]}\n' \
    > "$fixture/blocked.cdx.json"
run_check 1 "$fixture/blocked.cdx.json" --policy "$fixture/policy.json"
has "BLOCKED: forbidden: never ship" err
has "Release blocked by 1 component(s)." err
has "Summary: 1 blocked, 0 review-required, 0 notice-required."

# Bad policies and SBOMs: exit 2
jq '.notice_required_components[0].id = "agent"' "$fixture/policy.json" > "$fixture/duplicate.json"
run_check 2 "$fixture/empty.cdx.json" --policy "$fixture/duplicate.json"
has "id 'agent' is also used in review_required_components" err
jq '.review_required_components[1].match = {}' "$fixture/policy.json" > "$fixture/nomatch.json"
run_check 2 "$fixture/empty.cdx.json" --policy "$fixture/nomatch.json"
has "(agent) has nothing to match on" err
jq '.review_required_components[0].images = ["base", "child"]' "$fixture/policy.json" > "$fixture/stale.json"
run_check 0 "$fixture/empty.cdx.json" --policy "$fixture/stale.json"
has "policy warning: vendor-sdk: images lacks grandchild" err
printf 'not json\n' > "$fixture/broken.json"
run_check 2 "$fixture/broken.json" --policy "$fixture/policy.json"
printf '{"something": "else"}\n' > "$fixture/neither.json"
run_check 2 "$fixture/neither.json" --policy "$fixture/policy.json"
run_check 2 "$fixture/empty.cdx.json" --policy "$fixture/policy.json" --inventory "$fixture/missing.tsv"

# The real policy loads without errors or warnings, and its match rules work on syft-style input
run_check 0 "$fixture/empty.cdx.json"
lacks "policy" err
cat > "$fixture/real.cdx.json" << 'EOF'
{"bomFormat": "CycloneDX", "components": [
  {"name": "@anthropic-ai/claude-code", "version": "2.1.331", "purl": "pkg:npm/%40anthropic-ai/claude-code@2.1.331",
   "properties": [{"name": "syft:location:0:path", "value": "/usr/local/lib/node_modules/@anthropic-ai/claude-code/package.json"}]},
  {"name": "github.com/tomnomnom/waybackurls", "purl": "pkg:golang/github.com/tomnomnom/waybackurls@v0.1.0"},
  {"name": "nmap-common", "properties": [{"name": "syft:metadata:source", "value": "nmap"}]},
  {"name": "ofrak", "purl": "pkg:pypi/ofrak@3.3.0"}
]}
EOF
printf 'path\t/usr/bin/littlesnitch\nexe\tLogic\t/hardware/Saleae/squashfs-root/AppRun\n' > "$fixture/real.tsv"
run_check 1 "$fixture/real.cdx.json" --inventory "$fixture/real.tsv"
has "BLOCKED: ofrak" err
has "REVIEW: claude-code"
has "REVIEW: waybackurls"
has "REVIEW: saleae-logic2"
has "NOTICE: nmap"
has "NOTICE: little-snitch"

# generate-sbom.sh with a stub syft: arguments, output names, inventory pick-up, checksums, status
mkdir -p "$fixture/bin" "$fixture/out1"
cat > "$fixture/bin/syft" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$STUB_LOG"
while [[ $# -gt 0 ]]; do
    if [[ $1 == --output ]]; then
        case $2 in
            cyclonedx-json=*) cp "$STUB_CDX" "${2#*=}" ;;
            spdx-json=*) cp "$STUB_SPDX" "${2#*=}" ;;
        esac
        shift
    fi
    shift
done
EOF
cat > "$fixture/bin/docker" << 'EOF'
#!/usr/bin/env bash
line="$*"
printf '%s\n' "${line//$'\n'/ }" >> "$STUB_LOG"
script=""
for ((i = 1; i <= $#; i++)); do
    if [[ ${!i} == -c ]]; then
        j=$((i + 1))
        script=${!j}
        break
    fi
done
case $script in
    *"rfswift-inventory: inventory"*)
        printf 'func\tburpsuite_community_install\n'
        for arg in "$@"; do
            if [[ $arg == path:/opt/burpsuite/ ]]; then printf 'path\t/opt/burpsuite\n'; fi
        done
        printf 'deb\tnmap\t7.95+dfsg-3\tnmap\t7.95+dfsg-3\n'
        printf 'git\t/telecom/5G/open5gs\thttps://github.com/open5gs/open5gs\t0123456789abcdef0123456789abcdef01234567\n'
        ;;
    *) tar -czf - -T /dev/null ;;
esac
EOF
chmod +x "$fixture/bin/syft" "$fixture/bin/docker"
export STUB_LOG="$fixture/stub.log" STUB_CDX="$fixture/match.cdx.json" STUB_SPDX="$fixture/match.spdx.json"
prefix=rfswiftdev_resolute_network_amd64

PATH="$fixture/bin:$PATH" OUT_DIR="$fixture/out1" bash scripts/compliance/image-inventory.sh network_amd64 \
    > "$fixture/out" 2> "$fixture/err" || fail "image-inventory.sh failed"
grep -q -- '--network none' "$STUB_LOG" || fail "docker run without --network none"
grep -q -- '--platform linux/amd64 --entrypoint sh penthertz/rfswiftdev_resolute:network_amd64 -c' "$STUB_LOG" \
    || fail "docker run arguments"
[[ $(grep -c . "$STUB_LOG") == 3 ]] || fail "expected three docker runs"
grep -qx $'path\t/opt/burpsuite' "$fixture/out1/$prefix.inventory.tsv" || fail "policy paths not probed"
[[ $(cat "$fixture/out1/$prefix.debian-source-packages.tsv") == $'nmap\t7.95+dfsg-3\tnmap\t7.95+dfsg-3' ]] \
    || fail "Debian package list"
grep -q $'^/telecom/5G/open5gs\thttps://github.com/open5gs/open5gs\t0123' "$fixture/out1/$prefix.git-checkouts.tsv" \
    || fail "git checkout list"
(cd "$fixture/out1" && sha256sum -c --quiet "INVENTORY-SHA256SUMS-$prefix") || fail "inventory checksums"

PATH="$fixture/bin:$PATH" bash scripts/compliance/generate-sbom.sh network_amd64 "$fixture/out1" \
    > "$fixture/out" 2> "$fixture/err" || fail "generate-sbom.sh failed"
for want in scan penthertz/rfswiftdev_resolute:network_amd64 all-layers linux/amd64 package; do
    grep -qx -- "$want" "$STUB_LOG" || fail "syft called without $want"
done
for file in cdx.json spdx.json policy.txt policy.json; do
    [[ -s $fixture/out1/$prefix.$file ]] || fail "missing $prefix.$file"
done
(cd "$fixture/out1" && sha256sum -c --quiet "SHA256SUMS-$prefix") || fail "SBOM checksums"
grep -qF "Inventory: $fixture/out1/$prefix.inventory.tsv" "$fixture/out1/$prefix.policy.txt" || fail "inventory not used"
grep -qF "found: inventory: install function burpsuite_community_install" "$fixture/out1/$prefix.policy.txt" \
    || fail "inventory evidence missing from the report"

# A blocked component makes generate-sbom.sh exit 1, after writing everything
export STUB_CDX="$fixture/blocked.cdx.json"
status=0
PATH="$fixture/bin:$PATH" POLICY="$fixture/policy.json" bash scripts/compliance/generate-sbom.sh \
    registry:example.org/team/image:tool_arm64_1.2.3 "$fixture/out2" > "$fixture/out" 2> "$fixture/err" || status=$?
[[ $status == 1 ]] || fail "generate-sbom.sh exit $status on a blocked component"
grep -qx -- linux/arm64 "$STUB_LOG" || fail "platform not taken from the _arm64 tag"
grep -qF "BLOCKED: forbidden" "$fixture/out2/image_tool_arm64_1.2.3.policy.txt" || fail "blocked report"
(cd "$fixture/out2" && sha256sum -c --quiet SHA256SUMS-image_tool_arm64_1.2.3) || fail "checksums after a block"

echo 'license policy tests: ok'
