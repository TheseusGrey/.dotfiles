#!/bin/sh
# Scans all XDG application directories and outputs JSON lines for each
# launchable .desktop entry. Intended as a complete drun replacement.
#
# Output format (one JSON object per line):
#   {"name":"...","exec":"...","icon":"...","comment":"...","keywords":"..."}
#
# Directories scanned (per XDG Base Directory spec):
#   - $XDG_DATA_HOME/applications (default: ~/.local/share/applications)
#   - Each dir in $XDG_DATA_DIRS/applications (default: /usr/local/share:/usr/share)
#   - Flatpak exports (system + user)
#
# Filtering rules (matching rofi drun behavior):
#   - Skip entries with NoDisplay=true or Hidden=true
#   - Skip entries where TryExec binary is not found in PATH
#   - Skip entries with OnlyShowIn that doesn't match $XDG_CURRENT_DESKTOP
#   - Skip entries with NotShowIn that matches $XDG_CURRENT_DESKTOP
#   - Include Desktop Actions as separate entries (e.g. "Firefox — New Window")

set -f  # disable globbing

# ─── Determine search directories ─────────────────────────────────────
data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
data_dirs="${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

# Build list of application directories
app_dirs="$data_home/applications"
IFS=':'
for dir in $data_dirs; do
    [ -d "$dir/applications" ] && app_dirs="$app_dirs $dir/applications"
done
unset IFS

# Flatpak exports (common locations)
for fp_dir in \
    "$data_home/flatpak/exports/share/applications" \
    "/var/lib/flatpak/exports/share/applications"; do
    [ -d "$fp_dir" ] && app_dirs="$app_dirs $fp_dir"
done

# Current desktop for OnlyShowIn/NotShowIn filtering
current_desktop="$XDG_CURRENT_DESKTOP"  # e.g. "Hyprland" or "GNOME:XFCE"

# ─── Helper: check if a value list contains current desktop ───────────
desktop_matches() {
    match_list="$1"
    [ -z "$current_desktop" ] && return 1
    # Both can be semicolon-separated lists
    IFS=';'
    for show_de in $match_list; do
        IFS=':'
        for my_de in $current_desktop; do
            [ "$show_de" = "$my_de" ] && return 0
        done
        unset IFS
    done
    unset IFS
    return 1
}

# ─── Helper: escape for JSON string ──────────────────────────────────
json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/	/\\t/g'
}

# ─── Helper: strip field codes from Exec ─────────────────────────────
strip_field_codes() {
    printf '%s' "$1" | sed 's/ %[fFuUdDnNickvm]//g'
}

# ─── Emit a JSON entry ────────────────────────────────────────────────
emit_entry() {
    e_name="$1"
    e_exec="$2"
    e_icon="$3"
    e_comment="$4"
    e_keywords="$5"

    [ -z "$e_name" ] || [ -z "$e_exec" ] && return

    e_name=$(json_escape "$e_name")
    e_exec=$(json_escape "$e_exec")
    e_icon=$(json_escape "$e_icon")
    e_comment=$(json_escape "$e_comment")
    e_keywords=$(json_escape "$e_keywords")

    printf '{"name":"%s","exec":"%s","icon":"%s","comment":"%s","keywords":"%s"}\n' \
        "$e_name" "$e_exec" "$e_icon" "$e_comment" "$e_keywords"
}

# ─── Track seen desktop IDs to handle duplicates ─────────────────────
# (Higher-priority dirs listed first in XDG_DATA_DIRS take precedence)
seen_ids=""

already_seen() {
    case "$seen_ids" in
        *"|$1|"*) return 0 ;;
        *) return 1 ;;
    esac
}

mark_seen() {
    seen_ids="${seen_ids}|$1|"
}

# ─── Main scan ────────────────────────────────────────────────────────
for dir in $app_dirs; do
    [ -d "$dir" ] || continue
    find "$dir" -name '*.desktop' -type f 2>/dev/null
done | while IFS= read -r filepath; do
    # Desktop file ID: relative path with / replaced by - (for dedup)
    basename_id="${filepath##*/}"
    if already_seen "$basename_id"; then
        continue
    fi
    mark_seen "$basename_id"

    # ─── Parse the [Desktop Entry] section ────────────────────────────
    name="" exec_cmd="" icon="" comment="" keywords=""
    type="" no_display="" hidden="" try_exec=""
    only_show_in="" not_show_in="" terminal=""
    in_section=""
    actions=""

    while IFS= read -r line; do
        case "$line" in
            "["*"]")
                case "$line" in
                    "[Desktop Entry]") in_section="main" ;;
                    "[Desktop Action "*)
                        in_section="action"
                        # We'll handle actions in a second pass
                        ;;
                    *) in_section="other" ;;
                esac
                continue
                ;;
        esac

        [ "$in_section" = "main" ] || continue

        case "$line" in
            Name=*) [ -z "$name" ] && name="${line#Name=}" ;;
            Exec=*) exec_cmd="${line#Exec=}" ;;
            Icon=*) icon="${line#Icon=}" ;;
            Comment=*) [ -z "$comment" ] && comment="${line#Comment=}" ;;
            Keywords=*) keywords="${line#Keywords=}" ;;
            Type=*) type="${line#Type=}" ;;
            NoDisplay=*) no_display="${line#NoDisplay=}" ;;
            Hidden=*) hidden="${line#Hidden=}" ;;
            TryExec=*) try_exec="${line#TryExec=}" ;;
            OnlyShowIn=*) only_show_in="${line#OnlyShowIn=}" ;;
            NotShowIn=*) not_show_in="${line#NotShowIn=}" ;;
            Terminal=*) terminal="${line#Terminal=}" ;;
            Actions=*) actions="${line#Actions=}" ;;
        esac
    done < "$filepath"

    # ─── Apply filters ────────────────────────────────────────────────
    # Must be Application type
    [ "$type" = "Application" ] || [ -z "$type" ] || continue

    # Skip NoDisplay/Hidden
    [ "$no_display" = "true" ] && continue
    [ "$hidden" = "true" ] && continue

    # OnlyShowIn/NotShowIn
    if [ -n "$only_show_in" ]; then
        desktop_matches "$only_show_in" || continue
    fi
    if [ -n "$not_show_in" ]; then
        desktop_matches "$not_show_in" && continue
    fi

    # TryExec — skip if binary not found
    if [ -n "$try_exec" ]; then
        command -v "$try_exec" >/dev/null 2>&1 || continue
    fi

    # Must have Name and Exec
    [ -z "$name" ] || [ -z "$exec_cmd" ] && continue

    # Strip field codes from Exec
    clean_exec=$(strip_field_codes "$exec_cmd")

    # Wrap in terminal if needed
    if [ "$terminal" = "true" ]; then
        # Use sensible default terminal
        term="${TERMINAL:-kitty}"
        clean_exec="$term -e $clean_exec"
    fi

    # ─── Emit main entry ──────────────────────────────────────────────
    emit_entry "$name" "$clean_exec" "$icon" "$comment" "$keywords"

    # ─── Emit Desktop Actions ─────────────────────────────────────────
    if [ -n "$actions" ]; then
        IFS=';'
        for action_id in $actions; do
            [ -z "$action_id" ] && continue

            action_name="" action_exec="" action_icon=""
            in_target=0
            target_header="[Desktop Action $action_id]"

            while IFS= read -r line; do
                if [ "$line" = "$target_header" ]; then
                    in_target=1
                    continue
                fi
                case "$line" in
                    "["*"]")
                        [ "$in_target" = "1" ] && break
                        ;;
                esac
                [ "$in_target" = "1" ] || continue

                case "$line" in
                    Name=*) action_name="${line#Name=}" ;;
                    Exec=*) action_exec="${line#Exec=}" ;;
                    Icon=*) action_icon="${line#Icon=}" ;;
                esac
            done < "$filepath"

            if [ -n "$action_name" ] && [ -n "$action_exec" ]; then
                action_clean_exec=$(strip_field_codes "$action_exec")
                [ -z "$action_icon" ] && action_icon="$icon"
                emit_entry "$name — $action_name" "$action_clean_exec" "$action_icon" "" ""
            fi
        done
        unset IFS
    fi
done
