#!/bin/bash

URL="$1"
PASS="$(python -c "import urlparse;p=urlparse.urlparse(\"$URL\");print urlparse.parse_qs(p.query)[\"password\"][0];")"
USER="nimbix"

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -t "$USER@localhost"

