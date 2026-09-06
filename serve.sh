#!/usr/bin/env bash
# Serve the site locally at http://localhost:4000 with live reload.
# Builds the docker image on first run (or after Gemfile changes).
set -euo pipefail
cd "$(dirname "$0")"
docker build -q -t gagkhan-site . >/dev/null
exec docker run --rm -it \
  -p 4000:4000 -p 35729:35729 \
  -v "$PWD:/site" \
  gagkhan-site "$@"
