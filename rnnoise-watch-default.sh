#!/usr/bin/env bash

set -u

target="capture.rnnoise_mic:playback_MONO"
previous_source=""
previous_port=""

current_default() {
    wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null |
        sed -n 's/^[[:space:]]*node\.name = "\(.*\)"/\1/p' |
        head -n 1
}

source_port() {
    local source="$1"

    if pw-link -o 2>/dev/null | grep -Fxq "${source}:capture_MONO"; then
        printf '%s\n' "capture_MONO"
        return 0
    fi

    if pw-link -o 2>/dev/null | grep -Fxq "${source}:capture_FL"; then
        printf '%s\n' "capture_FL"
        return 0
    fi

    return 1
}

disconnect_previous() {
    if [[ -n "$previous_source" && -n "$previous_port" ]]; then
        pw-link -d "${previous_source}:${previous_port}" "$target" >/dev/null 2>&1 || true
    fi
}

while true; do
    current_source="$(current_default)"

    if [[ -n "$current_source" && "$current_source" != "rnnoise_mic" ]]; then
        if current_port="$(source_port "$current_source")"; then
            if [[ "$current_source" != "$previous_source" || "$current_port" != "$previous_port" ]]; then
                disconnect_previous

                if pw-link "${current_source}:${current_port}" "$target" >/dev/null 2>&1; then
                    previous_source="$current_source"
                    previous_port="$current_port"
                else
                    previous_source=""
                    previous_port=""
                fi
            fi
        else
            disconnect_previous
            previous_source=""
            previous_port=""
        fi
    else
        disconnect_previous
        previous_source=""
        previous_port=""
    fi

    sleep 2
done
