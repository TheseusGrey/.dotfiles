#!/usr/bin/env bash
# Brightness control for the brightness keys.
#
# Uses a hardware backlight when brightnessctl reports one. Desktops without a
# backlight fall back to hyprsunset gamma dimming, persisted in the same
# settings key as the brightness panel so the two stay in sync.

set -euo pipefail

qsh="${HOME}/.local/bin/qsh"
action="${1:-}"
step="${2:-5}"

case "$action" in
    i|up)   delta="$step" ;;
    d|down) delta="-$step" ;;
    m|max)  delta=100 ;;
    n|min)  delta=-100 ;;
    *)
        echo "usage: $(basename "$0") <i|d|m|n> [step]" >&2
        exit 1
        ;;
esac

# Serialise concurrent invocations: the keys repeat while held, and the gamma
# value lives in a read-modify-write settings file.
lock="${XDG_RUNTIME_DIR:-/tmp}/brightnesscontrol.lock"
exec 9>"$lock"
flock 9

notify_osd() {
    local pct="$1"
    if command -v qs >/dev/null 2>&1; then
        qs ipc call tui.shell osdBrightness \
            "$(awk -v p="$pct" 'BEGIN { printf "%.2f", p / 100 }')" >/dev/null 2>&1 || true
    fi
}

# Start the daemon when it is missing. If it is alive but not answering
# (seen after a Hyprland reload), replace it: the panel would otherwise keep
# looking at a dead socket while `pgrep` says everything is fine.
ensure_hyprsunset() {
    if hyprctl hyprsunset gamma >/dev/null 2>&1; then
        return 0
    fi
    pkill -x hyprsunset >/dev/null 2>&1 || true
    sleep 0.2
    setsid hyprsunset >/dev/null 2>&1 9>&- &
    sleep 0.4
}

dev="$(brightnessctl -m -l 2>/dev/null | awk -F, '$2 == "backlight" { print $1; exit }' || true)"

if [[ -n "$dev" ]]; then
    cur="$(brightnessctl -m -d "$dev" get 2>/dev/null || echo 0)"
    max="$(brightnessctl -m -d "$dev" max 2>/dev/null || echo 100)"
    pct=$(( cur * 100 / max + delta ))
else
    cur="$("$qsh" settings get display.brightness 2>/dev/null || true)"
    [[ "$cur" =~ ^[0-9]+$ ]] || cur=100
    pct=$(( cur + delta ))
fi

pct=$(( pct < 1 ? 1 : (pct > 100 ? 100 : pct) ))

if [[ -n "$dev" ]]; then
    brightnessctl -d "$dev" set "${pct}%" >/dev/null
else
    eye="$("$qsh" settings get display.eyeEnabled 2>/dev/null || true)"
    temp="$("$qsh" settings get display.eyeTemperature 2>/dev/null || true)"
    [[ "$temp" =~ ^[0-9]+$ ]] || temp=3000

    ensure_hyprsunset
    if [[ "$eye" == "true" ]]; then
        hyprctl hyprsunset temperature "$temp" >/dev/null 2>&1 || true
    else
        hyprctl hyprsunset identity >/dev/null 2>&1 || true
    fi
    hyprctl hyprsunset gamma "$(( 10 + pct * 9 / 10 ))" >/dev/null 2>&1 || true

    "$qsh" settings set display.brightness "$pct" >/dev/null 2>&1 || true
fi

# Eye protection also works alongside a hardware backlight, so reapply it when
# the daemon was restarted or the keybinds were used after a toggle.
if [[ -n "$dev" ]]; then
    eye="$("$qsh" settings get display.eyeEnabled 2>/dev/null || true)"
    if [[ "$eye" == "true" ]]; then
        temp="$("$qsh" settings get display.eyeTemperature 2>/dev/null || true)"
        [[ "$temp" =~ ^[0-9]+$ ]] || temp=3000
        ensure_hyprsunset
        hyprctl hyprsunset temperature "$temp" >/dev/null 2>&1 || true
    fi
fi

notify_osd "$pct"
