#!/usr/bin/env bash
# Build the twelve release ZIPs without publishing or installing them.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$REPO_ROOT/scripts/prepare-build.sh" --all
for module in . mediation/applovin mediation/meta mediation/inmobi mediation/unity mediation/liftoff; do
  for platform in android ios; do
    echo "Building $module/$platform"
    (cd "$REPO_ROOT/$module/$platform" && ti build -p "$platform" --build-only --no-prompt)
  done
done

python3 "$REPO_ROOT/scripts/prepare-package-docs.py"
python3 "$REPO_ROOT/scripts/verify-packages.py"
