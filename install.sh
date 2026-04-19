#!/usr/bin/env bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pipewire_dir="${HOME}/.config/pipewire/pipewire.conf.d"
bin_dir="${HOME}/.local/bin"
systemd_dir="${HOME}/.config/systemd/user"

mkdir -p "$pipewire_dir" "$bin_dir" "$systemd_dir"

install -m 0644 "${repo_dir}/99-rnnoise-source.conf" "${pipewire_dir}/99-rnnoise-source.conf"
install -m 0755 "${repo_dir}/rnnoise-watch-default.sh" "${bin_dir}/rnnoise-watch-default.sh"
install -m 0644 "${repo_dir}/rnnoise-watch-default.service" "${systemd_dir}/rnnoise-watch-default.service"

systemctl --user daemon-reload
systemctl --user enable --now rnnoise-watch-default.service
systemctl --user restart pipewire pipewire-pulse wireplumber

printf '%s\n' "Installed RNNoise Mic watcher."
printf '%s\n' "If missing plugin package install noise-suppression-for-voice then rerun this script."
