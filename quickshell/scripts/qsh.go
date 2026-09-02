package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
)

const socketPath = "/tmp/qs-finder.sock"

// settingsPath is the dedicated, shareable settings file. Flat JSON object:
// key -> string value. Written atomically on every change so it survives
// crashes and can be read/written by other tools.
const settingsPath = "/home/ashe/.config/quickshell/settings.json"

const (
	dotfilesRoot = "/home/ashe/.dotfiles"
	wallpaperDir  = dotfilesRoot + "/wallpapers"
	hyprPaperConf = dotfilesRoot + "/hypr/hyprpaper.conf"
)

// fallbackPreset is used when "sync colours to wallpaper" is turned OFF but no
// manual preset has ever been picked (and no blackwhite-accent exists to use).
const fallbackPreset = "blackwhite"

// target is the Quickshell IpcHandler target the TUI shell registers.
const target = "tui.shell"

var errCancelled = errors.New("cancelled")

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(2)
	}

	args := os.Args[2:]
	switch os.Args[1] {
	case "finder":
		finderCmd(args)
	case "panel":
		panelCmd(args)
	case "osd":
		osdCmd(args)
	case "notify":
		notifyCmd(args)
	case "pick":
		pickCmd(args)
	case "wallpaper":
		wallpaperCmd(args)
	case "colors":
		colorsCmd(args)
	case "wallpapers":
		listWallpapersCmd()
	case "accent":
		accentCmd(args)
	case "theme":
		themeCmd(args)
	case "themes":
		listThemesCmd()
	case "sync":
		syncCmd(args)
	case "scheme":
		schemeCmd(args)
	case "call":
		if len(args) < 2 {
			fatal("usage: qsh call <target> <method> [args...]")
		}
		mustIPC(args)
	case "settings":
		settingsCmd(args)
	case "lock":
		mustIPC([]string{target, "lock"})
	case "version":
		fmt.Println("qsh 0.1.0")
	case "help":
		usage()
	default:
		fmt.Fprintf(os.Stderr, "unknown command: %s\n", os.Args[1])
		usage()
		os.Exit(2)
	}
}

// ─── Commands ────────────────────────────────────────────────────────

// qsh finder [apps|screenshot|keybinds]  — open the finder in a mode
// qsh finder toggle                       — toggle the finder
func finderCmd(args []string) {
	switch len(args) {
	case 0:
		mustIPC([]string{target, "openFinder", "apps"})
	case 1:
		switch args[0] {
		case "toggle":
			mustIPC([]string{target, "toggleFinder"})
		case "apps", "screenshot", "keybinds":
			mustIPC([]string{target, "openFinder", args[0]})
		default:
			fatal("unknown finder mode %q (want apps|screenshot|keybinds|toggle)", args[0])
		}
	default:
		fatal("usage: qsh finder [apps|screenshot|keybinds|toggle]")
	}
}

// qsh panel open <context>  — open a right-panel context
// qsh panel close           — close all panels
// qsh panel left            — expand/collapse the left rail
func panelCmd(args []string) {
	valid := []string{
		"volume", "brightness", "wifi", "bluetooth",
		"power", "notifications", "keybinds", "menu", "theme",
	}

	if len(args) == 0 {
		fatal("usage: qsh panel open <context> | close | left")
	}

	switch args[0] {
	case "open":
		if len(args) != 2 {
			fatal("usage: qsh panel open <context>")
		}
		if !contains(valid, args[1]) {
			fatal("unknown context %q (want volume|brightness|wifi|bluetooth|power|notifications|keybinds|menu|theme)", args[1])
		}
		dispatch := map[string]string{
			"volume":        "toggleVolume",
			"brightness":    "toggleBrightness",
			"wifi":          "toggleWifi",
			"bluetooth":     "toggleBluetooth",
			"power":         "togglePower",
			"notifications": "toggleNotifications",
			"keybinds":      "toggleKeybinds",
			"menu":          "toggleMenu",
			"theme":         "toggleTheme",
		}
		mustIPC([]string{target, dispatch[args[1]]})
	case "close":
		mustIPC([]string{target, "closeAll"})
	case "left":
		mustIPC([]string{target, "toggleLeft"})
	default:
		fatal("unknown panel subcommand %q (want open|close|left)", args[0])
	}
}

// qsh osd volume <level> [muted]      — show volume OSD
// qsh osd brightness <level>          — show brightness OSD
func osdCmd(args []string) {
	if len(args) < 2 {
		fatal("usage: qsh osd volume <0-1> [muted] | qsh osd brightness <0-1>")
	}

	level, err := strconv.ParseFloat(args[1], 64)
	if err != nil || level < 0 || level > 1 {
		fatal("level must be a number between 0 and 1")
	}

	switch args[0] {
	case "volume":
		muted := "false"
		if len(args) >= 3 {
			b, err := strconv.ParseBool(args[2])
			if err != nil {
				fatal("muted must be true or false")
			}
			muted = strconv.FormatBool(b)
		}
		mustIPC([]string{target, "osdVolume", strconv.FormatFloat(level, 'f', -1, 64), muted})
	case "brightness":
		mustIPC([]string{target, "osdBrightness", strconv.FormatFloat(level, 'f', -1, 64)})
	default:
		fatal("unknown osd type %q (want volume|brightness)", args[0])
	}
}

// qsh notify clear — clear all notifications
func notifyCmd(args []string) {
	if len(args) == 1 && args[0] == "clear" {
		mustIPC([]string{target, "dismissNotifications"})
		return
	}
	fatal("usage: qsh notify clear")
}

// qsh pick [--items a,b,c] [--prompt text]
// Reads items from stdin (one per line) unless --items is given.
func pickCmd(args []string) {
	fs := flag.NewFlagSet("pick", flag.ContinueOnError)
	itemsStr := fs.String("items", "", "comma-separated items (default: read stdin, one per line)")
	prompt := fs.String("prompt", "pick one", "prompt text")
	if err := fs.Parse(args); err != nil {
		os.Exit(2)
	}

	var items []string
	if *itemsStr != "" {
		for _, item := range strings.Split(*itemsStr, ",") {
			item = strings.TrimSpace(item)
			if item != "" {
				items = append(items, item)
			}
		}
	} else {
		scanner := bufio.NewScanner(os.Stdin)
		for scanner.Scan() {
			line := strings.TrimSpace(scanner.Text())
			if line != "" {
				items = append(items, line)
			}
		}
		if err := scanner.Err(); err != nil {
			fatal("read stdin: %v", err)
		}
	}

	if len(items) == 0 {
		fatal("no items to pick from")
	}

	selection, err := pickItems(items, *prompt)
	if err != nil {
		if errors.Is(err, errCancelled) {
			fmt.Fprintln(os.Stderr, "cancelled")
			os.Exit(1)
		}
		fatal("%v", err)
	}
	fmt.Println(selection)
}

// qsh wallpaper <image> [--index N] [--scheme T] — regenerate the theme from
// an image. Runs matugen (sets the wallpaper via hyprpaper and regenerates
// Colors.qml / hypr / waybar from the config.toml templates).
// --index  N overrides which source colour is used (0 = most dominant).
// --scheme T overrides the material scheme type (e.g. scheme-expressive).
// Both are persisted for future wallpaper changes and sync-on.
func wallpaperCmd(args []string) {
	name, index, scheme := firstPlusFlags(args)
	file := resolveExisting(name, wallpaperDir, "wallpaper")
	if index != "" {
		saveSetting("theme.sourceColorIndex", index)
	}
	if scheme != "" {
		saveSetting("theme.scheme", scheme)
	}
	applyHyprpaper(file)
	// matugen's own wallpaper side-effects are disabled (set = false) so qsh
	// is the single owner of hyprpaper changes.
	cmdArgs := []string{"image", "--type", matugenScheme()}
	cmdArgs = append(cmdArgs, matugenSourceFlag()...)
	cmdArgs = append(cmdArgs, file)
	out, err := exec.Command("matugen", cmdArgs...).CombinedOutput()
	if err != nil {
		fatal("matugen image %s: %v\n%s", file, err, strings.TrimSpace(string(out)))
	}
	if len(out) > 0 {
		fmt.Print(string(out))
	}
	// Persist so the sync-on path knows which wallpaper to re-derive from.
	saveSetting("theme.wallpaper", file)
}

// parseFlags extracts optional trailing `--index N` and `--scheme T` flags.
// It returns the remaining positional args, the index ("" if absent) and the
// scheme ("" if absent). Unknown flags are fatal.
func parseFlags(args []string) (pos []string, index, scheme string) {
	for i := 0; i < len(args); i++ {
		switch args[i] {
		case "--index":
			if i+1 >= len(args) {
				fatal("--index requires a value")
			}
			index = args[i+1]
			i++
		case "--scheme":
			if i+1 >= len(args) {
				fatal("--scheme requires a value")
			}
			scheme = args[i+1]
			i++
		default:
			pos = append(pos, args[i])
		}
	}
	return pos, index, scheme
}

// firstPlusFlags is a convenience for commands that take exactly one positional
// argument plus optional --index / --scheme flags.
func firstPlusFlags(args []string) (name, index, scheme string) {
	pos, idx, sc := parseFlags(args)
	if len(pos) != 1 {
		fatal("expected <image|name> [--index N] [--scheme T]")
	}
	return pos[0], idx, sc
}

// matugenSourceFlag returns the --source-color-index flag for the persisted
// choice (default 0, most dominant).
func matugenSourceFlag() []string {
	idx := loadSettings()["theme.sourceColorIndex"]
	if idx == "" {
		idx = "0"
	}
	return []string{"--source-color-index", idx}
}

// matugenScheme returns the persisted material scheme type (default
// scheme-expressive). Validated against the known set.
func matugenScheme() string {
	s := loadSettings()["theme.scheme"]
	if s == "" {
		return "scheme-expressive"
	}
	if !containsString(schemeTypes, s) {
		return "scheme-expressive"
	}
	return s
}

var schemeTypes = []string{
	"scheme-content", "scheme-expressive", "scheme-fidelity",
	"scheme-fruit-salad", "scheme-monochrome", "scheme-neutral",
	"scheme-rainbow", "scheme-smart", "scheme-tonal-spot", "scheme-vibrant",
}

func containsString(list []string, s string) bool {
	for _, v := range list {
		if v == s {
			return true
		}
	}
	return false
}

// qsh sync on|off — toggle whether colours track the wallpaper.
//   on:  re-derive colours from the current wallpaper.
//   off: apply the last manually picked preset (falls back to black-white).
func syncCmd(args []string) {
	if len(args) != 1 {
		fatal("usage: qsh sync on|off")
	}
	p := loadSettings()
	state := args[0]
	if state != "on" && state != "off" {
		fatal("usage: qsh sync on|off (got %q)", state)
	}
	switch state {
	case "on":
		saveSetting("theme.syncedToWallpaper", "true")
		if w := p["theme.wallpaper"]; w != "" {
			cmdArgs := []string{"image", "--type", matugenScheme()}
			cmdArgs = append(cmdArgs, matugenSourceFlag()...)
			cmdArgs = append(cmdArgs, w)
			out, err := exec.Command("matugen", cmdArgs...).CombinedOutput()
			if err != nil {
				fatal("matugen sync %s: %v\n%s", w, err, strings.TrimSpace(string(out)))
			}
			if len(out) > 0 {
				fmt.Print(string(out))
			}
		}
	case "off":
		saveSetting("theme.syncedToWallpaper", "false")
		preset := p["theme.preset"]
		if preset == "" {
			preset = fallbackPreset
		}
		applyPreset(resolvePreset(preset))
	}
}

// qsh scheme <type> — persist the matugen material scheme type and regenerate
// the theme from the current wallpaper with it. If no wallpaper is set, it only
// stores the choice.
func schemeCmd(args []string) {
	if len(args) != 1 {
		fatal("usage: qsh scheme <scheme-type>")
	}
	scheme := args[0]
	if !containsString(schemeTypes, scheme) {
		fatal("unknown scheme %q; expected one of: %s", scheme, strings.Join(schemeTypes, ", "))
	}
	saveSetting("theme.scheme", scheme)
	p := loadSettings()
	if w := p["theme.wallpaper"]; w != "" {
		cmdArgs := []string{"image", "--type", scheme}
		cmdArgs = append(cmdArgs, matugenSourceFlag()...)
		cmdArgs = append(cmdArgs, w)
		out, err := exec.Command("matugen", cmdArgs...).CombinedOutput()
		if err != nil {
			fatal("matugen scheme %s: %v\n%s", w, err, strings.TrimSpace(string(out)))
		}
		if len(out) > 0 {
			fmt.Print(string(out))
		}
	}
}

// applyHyprpaper switches the live wallpaper: it rewrites hypr/hyprpaper.conf
// to (pre)load every wallpaper plus mark `file` active, then applies it via the
// IPC that this hyprpaper build actually supports. Newly added wallpapers that
// weren't loaded at hyprpaper boot need a restart to take effect; that's done
// automatically here.
func applyHyprpaper(file string) {
	old := ""
	if data, err := os.ReadFile(hyprPaperConf); err == nil {
		old = string(data)
	}
	writeHyprpaperConf(file)
	// If the chosen wallpaper wasn't already preloaded in the config hyprpaper
	// started with, the running daemon can't display it yet — bounce it so the
	// regen'd preload list takes effect. Otherwise a live IPC switch suffices.
	if !wasPreloaded(old, file) {
		restartHyprpaper()
	}
	sh("hyprctl hyprpaper wallpaper ," + shellQuote(file))
}

// wasPreloaded reports whether hyprpaper's previous config already loaded file.
func wasPreloaded(cfg, file string) bool {
	for _, line := range strings.Split(cfg, "\n") {
		l := strings.TrimSpace(line)
		if !strings.HasPrefix(l, "preload = ") {
			continue
		}
		if strings.Contains(l, file) || strings.Contains(l, shellQuote(file)) {
			return true
		}
	}
	return false
}

// writeHyprpaperConf generates hypr/hyprpaper.conf with every wallpaper
// preloaded and `active` marked as the wallpaper on every monitor. Paths are
// written raw (hyprpaper's hyprlang parser does NOT strip surrounding quotes).
func writeHyprpaperConf(active string) {
	var b strings.Builder
	b.WriteString("preload = " + active + "\n")
	for _, n := range listImages(wallpaperDir) {
		f := filepath.Join(wallpaperDir, n)
		if f != active {
			b.WriteString("preload = " + f + "\n")
		}
	}
	b.WriteString("\n# Active wallpaper (every monitor + fallback):\n")
	mons := listMonitors()
	if len(mons) == 0 {
		b.WriteString("wallpaper {\n  monitor =\n  path = " + active + "\n  fit_mode = cover\n}\n")
	}
	for _, m := range mons {
		b.WriteString("wallpaper {\n  monitor = " + m + "\n  path = " + active + "\n  fit_mode = cover\n}\n")
	}
	if len(mons) > 0 {
		b.WriteString("wallpaper {\n  monitor =\n  path = " + active + "\n  fit_mode = cover\n}\n")
	}
	b.WriteString("splash = false\n")
	if err := os.WriteFile(hyprPaperConf, []byte(b.String()), 0o644); err != nil {
		fatal("write %s: %v", hyprPaperConf, err)
	}
}

// listMonitors returns the names of the active Hyprland monitors.
func listMonitors() []string {
	out, err := exec.Command("hyprctl", "monitors", "-j").Output()
	if err != nil {
		return nil
	}
	var list []struct {
		Name string `json:"name"`
	}
	if json.Unmarshal(out, &list) == nil {
		names := []string{}
		for _, m := range list {
			if m.Name != "" {
				names = append(names, m.Name)
			}
		}
		return names
	}
	return nil
}

// restartHyprpaper bounces the daemon so it reloads hypr/hyprpaper.conf. The
// relaunch is fully detached (setsid + redirects) so Wait() doesn't block on the
// backgrounded daemon's inherited descriptors.
func restartHyprpaper() {
	sh("pkill -x hyprpaper")
	_ = exec.Command("setsid", "hyprpaper").Start()
	// give it a moment to connect to Hyprland
	time.Sleep(500 * time.Millisecond)
}

// shellQuote wraps s in double quotes for use inside hyprpaper.conf keywords
// and shell arguments (hyprpaper paths may contain spaces).
func shellQuote(s string) string {
	return `"` + strings.ReplaceAll(s, `"`, `\"`) + `"`
}

// sh runs a command via the shell; fatal on error.
func sh(cmd string) {
	out, err := exec.Command("sh", "-c", cmd).CombinedOutput()
	if err != nil {
		fatal("`%s`: %v\n%s", cmd, err, strings.TrimSpace(string(out)))
	}
}

// qsh wallpapers — list available wallpapers (image files only, one per line).
func listWallpapersCmd() {
	for _, n := range listImages(os.Getenv("HOME") + "/.dotfiles/wallpapers") {
		fmt.Println(n)
	}
}

// imageExts are the wallpaper extensions this tool recognises.
var imageExts = []string{".png", ".jpg", ".jpeg", ".webp", ".gif", ".bmp"}

// listImages returns the sorted basenames of image files (by extension) in dir.
func listImages(dir string) []string {
	entries, err := os.ReadDir(dir)
	if err != nil {
		fatal("couldn't list %s: %v", dir, err)
	}
	var names []string
	for _, e := range entries {
		if e.IsDir() {
			continue
		}
		if !containsImageExt(e.Name()) {
			continue
		}
		names = append(names, e.Name())
	}
	sort.Strings(names)
	return names
}

// containsImageExt reports whether name ends in a recognised image extension.
func containsImageExt(name string) bool {
	low := strings.ToLower(name)
	for _, ext := range imageExts {
		if strings.HasSuffix(low, ext) {
			return true
		}
	}
	return false
}

// accentPQ is a polymer palette read from matugen's --json hex dump.
type accentPQ struct{ bg, primary, secondary, tertiary string }

// qsh accent <image|name> — print the wallpaper's derived palette
// (bg, primary, secondary, tertiary as #hex on one space-separated line)
// WITHOUT applying the wallpaper or any templates (matugen --dry-run).
func accentCmd(args []string) {
	if len(args) != 1 {
		fatal("usage: qsh accent <image|name>")
	}
	file := resolveExisting(args[0],
		os.Getenv("HOME")+"/.dotfiles/wallpapers", "wallpaper")
	cmdArgs := []string{"image", "--type", matugenScheme(),
		"--dry-run", "--json", "hex"}
	cmdArgs = append(cmdArgs, matugenSourceFlag()...)
	cmdArgs = append(cmdArgs, file)
	out, err := exec.Command("matugen", cmdArgs...).CombinedOutput()
	if err != nil {
		fatal("matugen accent %s: %v\n%s", file, err, strings.TrimSpace(string(out)))
	}
	var doc struct {
		Colors map[string]struct {
			Default struct{ Color string } `json:"default"`
		} `json:"colors"`
	}
	if err := json.Unmarshal(out, &doc); err != nil {
		fatal("parse matugen accent for %s: %v", file, err)
	}
	pick := func(k string) string {
		if c, ok := doc.Colors[k]; ok {
			return c.Default.Color
		}
		return "#ff00ff"
	}
	fmt.Printf("%s %s %s %s\n", pick("background"), pick("primary"), pick("secondary"), pick("tertiary"))
}

// qsh colors <image> — diagnose how matugen will theme an image. Prints the
// candidate source colours, then the bg/primary/secondary/tertiary that each
// source-colour index (0 = most dominant … 4) would produce, so you can pick
// one. E.g. `qsh wallpaper <name> --index 1` to use index 1. The value in
// settings.json key theme.sourceColorIndex is marked.
func colorsCmd(args []string) {
	file := resolveExisting(args[0], wallpaperDir, "wallpaper")
	fmt.Printf("image: %s\n", filepath.Base(file))
	fmt.Println("candidate source colours (matugen picks by --source-color-index):")
	out, err := exec.Command("matugen", "image", "--show-source-colors", file).CombinedOutput()
	candCount := 0
	if err == nil {
		for i, line := range strings.Split(strings.TrimSpace(string(out)), "\n") {
			line = strings.TrimSpace(line)
			if line != "" {
				fmt.Printf("  [%d] %s\n", i, line)
				candCount = i + 1
			}
		}
	}
	if candCount == 0 {
		candCount = 1
	}
	fmt.Printf("scheme: %s (change with `qsh wallpaper ... --scheme T`)\n", matugenScheme())
	fmt.Println("derived palette per source-color-index (bg / primary / secondary / tertiary):")
	for i := 0; i < candCount; i++ {
		cmdArgs := []string{"image", "--type", matugenScheme(),
			"--source-color-index", strconv.Itoa(i), "--dry-run", "--json", "hex", file}
		o, e := exec.Command("matugen", cmdArgs...).CombinedOutput()
		mark := ""
		if loadSettings()["theme.sourceColorIndex"] == strconv.Itoa(i) {
			mark = "   <-- active"
		}
		if e != nil {
			fmt.Printf("  [%d] error\n", i)
			continue
		}
		var doc struct {
			Colors map[string]struct{ Default struct{ Color string } `json:"default"` } `json:"colors"`
		}
		if json.Unmarshal(o, &doc) != nil {
			fmt.Printf("  [%d] parse error\n", i)
			continue
		}
		pick := func(k string) string {
			if c, ok := doc.Colors[k]; ok {
				return c.Default.Color
			}
			return "??????"
		}
		fmt.Printf("  [%d] %s / %s / %s / %s%s\n", i, pick("background"),
			pick("primary"), pick("secondary"), pick("tertiary"), mark)
	}
}

// qsh themes — list available theme presets (names, one per line).
func listThemesCmd() {
	names := listDir(os.Getenv("HOME") + "/.config/matugen/presets")
	for _, n := range names {
		if strings.HasSuffix(n, ".json") {
			fmt.Println(strings.TrimSuffix(n, ".json"))
		}
	}
}

// listDir returns the sorted basenames (files only) in a directory.
func listDir(dir string) []string {
	entries, err := os.ReadDir(dir)
	if err != nil {
		fatal("couldn't list %s: %v", dir, err)
	}
	var names []string
	for _, e := range entries {
		if !e.IsDir() {
			names = append(names, e.Name())
		}
	}
	sort.Strings(names)
	return names
}

// resolveExisting returns arg if it's an existing file; otherwise it tries
// to match it (case-insensitive) against filenames in dir. If no match is
// found it fails with a message that lists the available choices.
func resolveExisting(arg, dir, kind string) string {
	if info, err := os.Stat(arg); err == nil && !info.IsDir() {
		return arg
	}
	entries, err := os.ReadDir(dir)
	if err != nil {
		fatal("not an image file: %s", arg)
	}
	low := strings.ToLower(arg)
	for _, e := range entries {
		if !e.IsDir() && strings.EqualFold(e.Name(), low) {
			return filepath.Join(dir, e.Name())
		}
	}
	// Also allow matching a short name against a stem (e.g. "spellforce-mage-art").
	for _, e := range entries {
		if !e.IsDir() {
			stem := strings.TrimSuffix(e.Name(), filepath.Ext(e.Name()))
			if strings.EqualFold(stem, low) {
				return filepath.Join(dir, e.Name())
			}
		}
	}
	fatal("unknown %s %q (available: %s)", kind, arg, strings.Join(listDir(dir), ", "))
	return ""
}

// qsh theme <preset> — apply a fixed theme preset (not tied to the wallpaper).
// Presets: default | catppuccin (or path to a matugen colors .json).
// Renders through the raw (unclamped) templates in matugen/presets/config.toml.
func themeCmd(args []string) {
	if len(args) != 1 {
		fatal("usage: qsh theme <preset|json-file> (presets: default, catppuccin)")
	}
	preset := resolvePreset(args[0])
	applyPreset(preset)
	// Remember it so turning sync OFF reverts to this scheme.
	saveSetting("theme.preset", filepath.Base(preset))
}

// resolvePreset returns the full path to a theme preset: either a direct file
// path or a preset name resolved from ~/.config/matugen/presets.
func resolvePreset(name string) string {
	if _, err := os.Stat(name); err == nil {
		return name
	}
	home, herr := os.UserHomeDir()
	if herr != nil {
		fatal("couldn't resolve home: %v", herr)
	}
	candidate := home + "/.config/matugen/presets/" + name + ".json"
	if _, err := os.Stat(candidate); err == nil {
		return candidate
	}
	return resolveExisting(name, home+"/.config/matugen/presets", "theme")
}

// applyPreset renders a matugen preset through the presets templates.
func applyPreset(file string) {
	cfg := os.Getenv("HOME") + "/.config/matugen/presets/config.toml"
	out, err := exec.Command("matugen", "json", file, "-c", cfg).CombinedOutput()
	if err != nil {
		fatal("matugen json %s: %v\n%s", file, err, strings.TrimSpace(string(out)))
	}
	if len(out) > 0 {
		fmt.Print(string(out))
	}
}

// ─── Settings ────────────────────────────────────────────────────────

// loadSettings reads the settings JSON into a map. A missing or malformed
// file yields an empty map (never an error).
func loadSettings() map[string]string {
	m := map[string]string{}
	data, err := os.ReadFile(settingsPath)
	if err != nil {
		return m
	}
	_ = json.Unmarshal(data, &m)
	return m
}

// saveSettings writes the map as pretty JSON, atomically (temp file + rename).
func saveSettings(m map[string]string) {
	data, _ := json.MarshalIndent(m, "", "  ")
	tmp := settingsPath + ".tmp"
	if err := os.WriteFile(tmp, data, 0o644); err != nil {
		fatal("write settings: %v", err)
	}
	if err := os.Rename(tmp, settingsPath); err != nil {
		fatal("commit settings: %v", err)
	}
}

// saveSetting updates a single key in the settings file.
func saveSetting(key, value string) {
	m := loadSettings()
	m[key] = value
	saveSettings(m)
}

// qsh settings get <key>   — print the value for a key ("" if unset)
// qsh settings set <k> <v> — set a key's value (persisted for all apps)
func settingsCmd(args []string) {
	if len(args) == 2 && args[0] == "get" {
		fmt.Println(loadSettings()[args[1]])
		return
	}
	if len(args) == 3 && args[0] == "set" {
		m := loadSettings()
		m[args[1]] = args[2]
		saveSettings(m)
		return
	}
	if len(args) == 2 && args[0] == "unset" {
		m := loadSettings()
		if _, ok := m[args[1]]; ok {
			delete(m, args[1])
			saveSettings(m)
		}
		return
	}
	fatal("usage: qsh settings get <key> | set <key> <value> | unset <key>")
}

// ─── IPC ─────────────────────────────────────────────────────────────

// ipc runs `qs ipc call <args...>`; returns an error on exec failure or when
// quickshell replies with a textual failure ("Target not found." and friends —
// quickshell still exits 0 for those, so we inspect stdout).
func ipc(args []string) error {
	call := append([]string{"ipc", "call"}, args...)
	out, err := exec.Command("qs", call...).CombinedOutput()
	msg := strings.TrimSpace(string(out))
	if err != nil {
		return fmt.Errorf("qs ipc call %s: %v\n%s", strings.Join(args, " "), err, msg)
	}
	if msg != "" && isIPCFailure(msg) {
		return errors.New(msg)
	}
	return nil
}

func isIPCFailure(msg string) bool {
	return strings.Contains(msg, "Function not found") ||
		strings.Contains(msg, "Target not found") ||
		strings.Contains(msg, "Target required")
}

func mustIPC(args []string) {
	if err := ipc(args); err != nil {
		fatal("%v", err)
	}
}

// ─── Socket picker ───────────────────────────────────────────────────

func pickItems(items []string, prompt string) (string, error) {
	conn, err := net.Dial("unix", socketPath)
	if err != nil {
		return "", fmt.Errorf("connect to finder socket: %w", err)
	}
	defer conn.Close()

	request, err := json.Marshal(map[string]interface{}{
		"items":  items,
		"prompt": prompt,
	})
	if err != nil {
		return "", err
	}
	if _, err := conn.Write(append(request, '\n')); err != nil {
		return "", err
	}

	scanner := bufio.NewScanner(conn)
	if !scanner.Scan() {
		return "", errors.New("finder did not respond")
	}

	var response struct {
		Selection string `json:"selection"`
		Cancelled bool   `json:"cancelled"`
		Error     string `json:"error"`
	}
	if err := json.Unmarshal(scanner.Bytes(), &response); err != nil {
		return "", fmt.Errorf("parse response: %w", err)
	}
	if response.Error != "" {
		return "", errors.New(response.Error)
	}
	if response.Cancelled {
		return "", errCancelled
	}
	return response.Selection, nil
}

// ─── Helpers ─────────────────────────────────────────────────────────

func contains(list []string, s string) bool {
	for _, item := range list {
		if item == s {
			return true
		}
	}
	return false
}

func fatal(format string, a ...interface{}) {
	fmt.Fprintf(os.Stderr, "qsh: "+format+"\n", a...)
	os.Exit(1)
}

func usage() {
	fmt.Print(`qsh — Quickshell TUI shell client

Usage:
  qsh finder [apps|screenshot|keybinds]   open the finder in a mode
  qsh finder toggle                       toggle the finder
  qsh panel open <context>                open right panel (volume|brightness|wifi|
                                          bluetooth|power|notifications|keybinds|menu|theme)
  qsh panel left                          expand/collapse the left rail
  qsh panel close                         close all panels
  qsh osd volume <0-1> [muted]            show volume OSD
  qsh osd brightness <0-1>                show brightness OSD
  qsh notify clear                        clear notifications
  qsh lock                                show the lock screen
  qsh pick [--items a,b,c] [--prompt t]   interactive picker (items from stdin
                                          unless --items is given); prints selection
  qsh wallpapers                          list available wallpapers (basenames)
  qsh wallpaper <image|name> [--index N]  apply background + regenerate theme
         [--scheme T]                     --index 0 = most dominant colour;
                                          --scheme e.g. scheme-expressive
  qsh colors <image|name>                 diagnose: candidate source colours +
                                          resulting palette for each index
                                          (and current scheme)
  qsh sync on|off                         sync colours to wallpaper (or revert preset)
  qsh scheme <type>                       persist matugen scheme type + re-derive
  qsh themes                              list available theme presets
  qsh theme <preset|json-file>            apply a fixed theme preset
  qsh settings get <key>                  print a persisted setting
  qsh settings set <key> <value>          persist a setting (shareable file)
  qsh settings unset <key>                remove a persisted setting
  qsh call <target> <method> [args...]    raw IPC call
  qsh help                                show this help
  qsh version                             show version

Examples:
  qsh panel open volume
  qsh osd volume 0.75 true
  qsh pick --prompt "checkout branch" < <(git branch --format='%(refname:short)')
  qsh call tui.shell toggleWifi
  qsh wallpaper spellforce-mage-art
  qsh theme nordic
`)
}
