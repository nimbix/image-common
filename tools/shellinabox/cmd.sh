#!/bin/bash

URL="$1"
PASS="$(python -c "import urlparse;p=urlparse.urlparse(\"$URL\");print urlparse.parse_qs(p.query)[\"password\"][0];")"
USER="${JARVICE_ID_USER}"

sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -t "$USER@localhost"

