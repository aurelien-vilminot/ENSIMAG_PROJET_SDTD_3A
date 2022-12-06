#!/bin/sh
# Give environnement variable to terraform script
cat <<EOF
{
  "GOOGLE_CLOUD_PROJECT": "$GOOGLE_CLOUD_PROJECT"
}
EOF