#!/usr/bin/env bash
# matugen-notify: after a template write, notify which running apps need to
# pick up their newly generated color files.
#
# Each post_hook for a template that produces a user-facing color change calls
# this script with the name of the app. When multiple templates are regenerated
# in one matugen run, the notifications are debounced/coalesced into a single one.
#
# The verb describing what the user must do is looked up per app below.
#   restart : the app needs a full restart (Zen, Steam, Prism Launcher)
#   reload  : the app can refresh without restarting (Obsidian snippet reload)
set -euo pipefail

LOCK_DIR="${XDG_RUNTIME_DIR:-/tmp}/matugen-notify"
LOCK_FILE="$LOCK_DIR/pending"
LOCK_ACTIONS="$LOCK_DIR/actions"
MAX_WAIT_MS=600

mkdir -p "$LOCK_DIR"

# Map app-name → the action the user must take to apply the new colors.
action_for() {
	case "$1" in
		zen-browser|steam|prismlauncher) echo "restart" ;;
		obsidian) echo "reload snippets" ;;
		*) echo "restart" ;;
	esac
}

flush() {
	[ -f "$LOCK_FILE" ] || return 0
	local names verb group comments
	names="$(cat "$LOCK_FILE")"
	rm -f "$LOCK_FILE" "$LOCK_ACTIONS"
	[ -n "$names" ] || return 0

	# Group apps by action verb so the message stays readable.
	group=""
	verb=""
	comments=""
	while IFS= read -r app; do
		[ -n "$app" ] || continue
		v="$(action_for "$app")"
		if [[ -z "$group" ]]; then
			group="$app"
			verb="$v"
		elif [[ "$v" == "$verb" ]]; then
			group="$group, $app"
		else
			comments="${comments:+$comments, }$app ($v)"
		fi
	done <<< "$names"

	local body
	if [[ -n "$comments" ]]; then
		body="Colors updated — $verb: $group; $comments"
	else
		body="Colors updated — $verb: $group"
	fi
	notify-send -u low -t 6000 "Matugen" "$body"
}

if [[ "${1:-}" == "--flush" ]]; then
	flush
	exit 0
fi

app="${1:-}"
[[ -n "$app" ]] || exit 0

# Ignore apps that aren't currently running (their colors apply on next launch).
if ! pgrep -f "$app" >/dev/null 2>&1; then
	exit 0
fi

# Coalesce: append this app to the pending list.
touch "$LOCK_FILE"
grep -qxF "$app" "$LOCK_FILE" || echo "$app" >> "$LOCK_FILE"

# Debounce + flush. First call starts a timer that flushes once the run settles.
if ! pgrep -f "matugen-notify --flush" >/dev/null 2>&1; then
	( sleep "$((MAX_WAIT_MS / 1000))" 2>/dev/null || sleep 1; "$0" --flush ) &
fi
