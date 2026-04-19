#!/usr/bin/env bash

set -euo pipefail

pipewire_config="${HOME}/.config/pipewire/pipewire.conf.d/99-rnnoise-source.conf"
watcher_script="${HOME}/.local/bin/rnnoise-watch-default.sh"
service_file="${HOME}/.config/systemd/user/rnnoise-watch-default.service"

systemctl --user disable --now rnnoise-watch-default.service >/dev/null 2>&1 || true

rm -f "$pipewire_config" "$watcher_script" "$service_file"

systemctl --user daemon-reload
systemctl --user restart pipewire pipewire-pulse wireplumber

printf '%s\n' "Removed RNNoise Mic watcher and user level config."
