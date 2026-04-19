#!/usr/bin/env bash

set -u

target="capture.rnnoise_mic:playback_MONO"

current_default() {
    wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null |
        sed -n 's/^.*node\.name = "\(.*\)"/\1/p' |
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

linked_inputs() {
    pw-link -I -l 2>/dev/null | awk -v target="$target" '
        $2 == target { in_target = 1; next }
        in_target && /^ *[0-9]+ +\|<-/ {
            link_id = $1
            source = $3
            print link_id "\t" source
            next
        }
        in_target && $0 !~ /^  / { in_target = 0 }
    '
}

disconnect_all_inputs() {
    while IFS=$'\t' read -r link_id source; do
        [[ -n "$link_id" ]] || continue
        pw-link -d "$link_id" >/dev/null 2>&1 || true
    done < <(linked_inputs)
}

current_input_count() {
    linked_inputs | wc -l
}

current_input_source() {
    linked_inputs | awk -F '\t' 'NR == 1 { print $2 }'
}

while true; do
    current_source="$(current_default)"

    if [[ -n "$current_source" && "$current_source" != "rnnoise_mic" ]]; then
        if current_port="$(source_port "$current_source")"; then
            current_link="${current_source}:${current_port}"
            existing_count="$(current_input_count)"
            existing_source="$(current_input_source)"

            if [[ "$existing_count" -ne 1 || "$existing_source" != "$current_link" ]]; then
                disconnect_all_inputs
                pw-link "$current_link" "$target" >/dev/null 2>&1 || true
            fi
        else
            disconnect_all_inputs
        fi
    else
        disconnect_all_inputs
    fi

    sleep 2
done
