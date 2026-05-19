#!/bin/sh
# Scans XDG application directories and outputs JSON lines for each visible .desktop entry.
# Output format: {"name":"...","exec":"...","icon":"...","comment":"..."}

dirs="/usr/share/applications ${XDG_DATA_HOME:-$HOME/.local/share}/applications"

for dir in $dirs; do
  [ -d "$dir" ] || continue
  find "$dir" -maxdepth 2 -name '*.desktop' -type f 2>/dev/null
done | sort -u | while IFS= read -r f; do
  # Skip hidden/nodisplay entries
  grep -qE '^(NoDisplay|Hidden)=true' "$f" && continue

  name=$(grep -m1 '^Name=' "$f" | cut -d= -f2-)
  [ -z "$name" ] && continue

  exec=$(grep -m1 '^Exec=' "$f" | cut -d= -f2- | sed 's/ %[fFuUdDnNickvm]//g')
  [ -z "$exec" ] && continue

  icon=$(grep -m1 '^Icon=' "$f" | cut -d= -f2-)
  comment=$(grep -m1 '^Comment=' "$f" | cut -d= -f2-)

  # Escape double quotes in values
  name=$(printf '%s' "$name" | sed 's/"/\\"/g')
  exec=$(printf '%s' "$exec" | sed 's/"/\\"/g')
  icon=$(printf '%s' "$icon" | sed 's/"/\\"/g')
  comment=$(printf '%s' "$comment" | sed 's/"/\\"/g')

  printf '{"name":"%s","exec":"%s","icon":"%s","comment":"%s"}\n' "$name" "$exec" "$icon" "$comment"
done
