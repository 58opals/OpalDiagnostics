#!/bin/sh
set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
usage() {
    printf '%s\n' 'usage: validate.sh [--list] [develop | focused IDENTIFIER | assurance]' \
        'focused IDENTIFIER matches a literal suite or test-identifier substring.' \
        'OPAL_VALIDATION_SCRATCH_PATH selects a per-repository, toolchain-compatible SwiftPM cache.'
}
list_only=false
if [ "${1:-}" = --help ] || [ "${1:-}" = -h ]; then usage; exit 0; fi
if [ "${1:-}" = --list ]; then list_only=true; shift; fi
lane=${1:-develop}
[ "$#" -eq 0 ] || shift
case "$lane" in
    develop | assurance) [ "$#" -eq 0 ] || { usage >&2; exit 64; } ;;
    focused)
        [ "$#" -eq 1 ] && [ -n "$1" ] || { usage >&2; exit 64; }
        case "$1" in -*|*[[:cntrl:]]*) usage >&2; exit 64 ;; esac
        identifier=$1
        ;;
    *) usage >&2; exit 64 ;;
esac

scratch_path=${OPAL_VALIDATION_SCRATCH_PATH:-"$repo_root/.build/validation"}
temporary=$(mktemp -d "${TMPDIR:-/tmp}/opal-diagnostics-validation.XXXXXX")
trap 'rm -rf -- "$temporary"' EXIT HUP INT TERM
cd "$repo_root"

# Discovery performs the only build; execution below reuses this exact lane.
env -u SDKROOT /usr/bin/xcrun swift test --scratch-path "$scratch_path" list > "$temporary/inventory"
if [ "$lane" = focused ]; then
    grep -F -- "$identifier" "$temporary/inventory" > "$temporary/selection" || {
        printf '%s\n' 'No test identifiers match the requested literal substring.' >&2; exit 65;
    }
    filter=$(printf '%s' "$identifier" | sed 's/[][\\.^$*+?(){}|]/\\&/g')
else
    cp "$temporary/inventory" "$temporary/selection"
fi
selected=$(awk 'NF { count++ } END { print count+0 }' "$temporary/selection")
total=$(awk 'NF { count++ } END { print count+0 }' "$temporary/inventory")
[ "$selected" -gt 0 ] || { printf '%s\n' 'Test discovery returned no tests.' >&2; exit 65; }
printf 'OpalDiagnostics %s: %s/%s test definitions selected.\n' "$lane" "$selected" "$total"
if "$list_only"; then cat "$temporary/selection"; exit 0; fi
status=0
if [ "$lane" = focused ]; then
    env -u SDKROOT /usr/bin/xcrun swift test --scratch-path "$scratch_path" --skip-build --filter "$filter" --xunit-output "$temporary/results.xml" || status=$?
else
    env -u SDKROOT /usr/bin/xcrun swift test --scratch-path "$scratch_path" --skip-build --xunit-output "$temporary/results.xml" || status=$?
fi
[ "$status" -eq 0 ] || exit "$status"
executed=0
for result in "$temporary"/results*.xml; do
    [ -f "$result" ] || continue
    count=$(/usr/bin/xmllint --nonet --xpath 'count(//testcase[not(skipped)])' "$result")
    case "$count" in ''|*[!0-9]*) printf '%s\n' 'Invalid test execution count.' >&2; exit 65 ;; esac
    executed=$((executed + count))
done
[ "$executed" -gt 0 ] || { printf '%s\n' 'No non-skipped tests executed.' >&2; exit 65; }
printf 'Executed %s non-skipped test definitions.\n' "$executed"
