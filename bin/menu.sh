menu() {
  local prompt="$1"
  local options="$2"
  local extra="$3"
  local preselect="$4"

  read -r -a args <<<"$extra"

  if [[ -n "$preselect" ]]; then
    local index
    index=$(echo -e "$options" | grep -nxF "$preselect" | cut -d: -f1)
    if [[ -n "$index" ]]; then
      args+=("-a" "$index")
    fi
  fi

  echo -e "$options" | rofi -dmenu "$prompt…" "${args[@]}"
}

open_menu() {
  prompt=$1
  options=$2
  menu $prompt $(${!options[@]})
}

function join_by {
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

screenshot_prompt="Capture"
declare -A screenshot_options
screenshot_options["  Screenshot"]=$(echo "NOT IMPLEMENTED")
screenshot_options["  Screenrecord"]=$(echo "NOT IMPLEMENTED")
screenshot_options["󰃉  Color"]=$(echo "NOT IMPLEMENTED")
show_screenshot_menu() {
  # need to get the keys, and pass them into the menu, might need to adjust the menu function
  menu $screenshot_prompt $(${!screenshot_options[@]})
}
