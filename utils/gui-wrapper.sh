#!/bin/sh

set -e

resolution="$1" # e.g. 800x600x24 (width x height x bits_per_pixel)
shift           # the following arguments are the program to execute and its arguments

bg="$(mktemp --suffix='.xbm')"
twm_cfg="$(mktemp --suffix='_twm.cfg')"
anim="$(mktemp -d)"

# Create solid black background
convert -size "$(echo "$resolution" | cut -d 'x' -f1-2)" \
        tile:pattern:checkerboard \
        -auto-level +level-colors 'gray(192),gray(128)' \
        "$bg"

cat > "$twm_cfg" <<EOF
RandomPlacement
EOF

# -fg chocolate -bg coral looks nice too :)
echo "$bg $twm_cfg $anim"
xvfb-run -a --server-args="-screen 0 ${resolution}" sh -c 'twm -f "'"$twm_cfg"'" & xsetroot -bitmap "'"$bg"'" -fg gray75 -bg gray50; sleep 1; utils/screenshots-loop.sh "'"$anim"'" & "$@"' utils/gui-wrapper.sh-subshell "$@"

touch "$anim/stop-screenshots"
for i in `seq 60`; do if test -e "$anim/anim-done"; then break; fi; sleep 1; done
if test -e "$anim/anim.gif"; then
  mv "$anim/anim.gif" "./deploy-screenshots/$(basename "$1" .sh)-anim.gif"
fi
cp "$bg" "./deploy-screenshots/$(basename "$1" .sh)-bg-$(basename "$bg")"

# Cleanup
rm "$bg"
