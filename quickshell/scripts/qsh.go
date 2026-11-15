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

// Paths are derived from the environment so the dotfiles work outside
// /home/ashe. DOTFILES overrides the repository location; XDG_CONFIG_HOME
// overrides ~/.config.
func userHome() string {
	if h, err := os.UserHomeDir(); err == nil && h != "" {
		return h
	}
	return os.Getenv("HOME")
}

func configHome() string {
	if x := os.Getenv("XDG_CONFIG_HOME"); x != "" {
		return x
	}
	return filepath.Join(userHome(), ".config")
}

func repoRoot() string {
	if d := os.Getenv("DOTFILES"); d != "" {
		return d
	}
	return filepath.Join(userHome(), ".dotfiles")
}

var (
	dotfilesRoot  = repoRoot()
	wallpaperDir  = filepath.Join(dotfilesRoot, "wallpapers")
	settingsPath  = filepath.Join(configHome(), "quickshell", "settings.json")
	hyprPaperConf = filepath.Join(dotfilesRoot, "hypr", "hyprpaper.conf")
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
	case "bootstrap":
		bootstrapCmd(args)
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
// qsh panel toggle          — toggle the right panel (reopens last context)
// qsh panel close           — close all panels
// qsh panel left            — expand/collapse the left rail
func panelCmd(args []string) {
	valid := []string{
		"volume", "brightness", "wifi", "bluetooth",
		"power", "notifications", "keybinds", "menu", "theme",
	}

	if len(args) == 0 {
		fatal("usage: qsh panel open <context> | toggle | close | left")
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
	case "toggle":
		mustIPC([]string{target, "toggleRight"})
	case "close":
		mustIPC([]string{target, "closeAll"})
	case "left":
		mustIPC([]string{target, "toggleLeft"})
	default:
		fatal("unknown panel subcommand %q (want open|toggle|close|left)", args[0])
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

// qsh wallpaper <image> [--index N] [--scheme T] [--no-theme] — regenerate the
// theme from an image and apply it. Generation is staged and validated before
// anything is published or the wallpaper changes.
//
//	--no-theme  only change the wallpaper; keep the current preset colours.
func wallpaperCmd(args []string) {
	name, index, scheme, noTheme := parseWallpaperFlags(args)
	file := resolveExisting(name, wallpaperDir, "wallpaper")

	if noTheme {
		if err := applyHyprpaper(file); err != nil {
			fatal("apply wallpaper %s: %v", filepath.Base(file), err)
		}
		saveSetting("theme.wallpaper", file)
		saveSetting("theme.syncedToWallpaper", "false")
		fmt.Printf("wallpaper: %s (preset colours kept)\n", filepath.Base(file))
		return
	}

	staged, err := generateImage(file, scheme, index)
	if err != nil {
		fatal("%v", err)
	}
	published, err := staged.publish()
	staged.discard()
	if err != nil {
		fatal("publish theme: %v", err)
	}
	reloadHyprland()

	if err := applyHyprpaper(file); err != nil {
		published.rollback()
		reloadHyprland()
		fatal("apply wallpaper %s: %v", filepath.Base(file), err)
	}

	if index != "" {
		saveSetting("theme.sourceColorIndex", index)
	}
	if scheme != "" {
		saveSetting("theme.scheme", scheme)
	}
	saveSetting("theme.wallpaper", file)
	saveSetting("theme.syncedToWallpaper", "true")
	fmt.Printf("theme: %s → %s\n", filepath.Base(file), matugenSchemeValue(scheme))
}

// parseWallpaperFlags accepts the wallpaper command's optional flags.
func parseWallpaperFlags(args []string) (name, index, scheme string, noTheme bool) {
	var pos []string
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
		case "--no-theme":
			noTheme = true
		default:
			pos = append(pos, args[i])
		}
	}
	if len(pos) != 1 {
		fatal("expected <image|name> [--index N] [--scheme T] [--no-theme]")
	}
	return pos[0], index, scheme, noTheme
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

// matugenSchemeValue resolves a scheme override or the persisted scheme type.
func matugenSchemeValue(override string) string {
	if override != "" && containsString(schemeTypes, override) {
		return override
	}
	return matugenScheme()
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
//
//	on:  re-derive colours from the current (or last recorded) wallpaper.
//	off: apply the last manually picked preset (falls back to black-white).
func syncCmd(args []string) {
	if len(args) != 1 {
		fatal("usage: qsh sync on|off")
	}
	p := loadSettings()
	switch args[0] {
	case "on":
		w := p["theme.wallpaper"]
		if w == "" {
			w = activeWallpaper()
		}
		if w == "" {
			fatal("no wallpaper recorded; run `qsh wallpaper <name>` first")
		}
		staged, err := generateImage(w, p["theme.scheme"], p["theme.sourceColorIndex"])
		if err != nil {
			fatal("%v", err)
		}
		if _, err := staged.publish(); err != nil {
			staged.discard()
			fatal("publish theme: %v", err)
		}
		staged.discard()
		reloadHyprland()
		saveSetting("theme.wallpaper", w)
		saveSetting("theme.syncedToWallpaper", "true")
		fmt.Printf("sync: on (%s)\n", filepath.Base(w))
	case "off":
		preset := p["theme.preset"]
		if preset == "" || !fileExists(preset) {
			preset = fallbackPreset
		}
		path := resolvePreset(preset)
		staged, err := generatePreset(path, "")
		if err != nil {
			fatal("%v", err)
		}
		if _, err := staged.publish(); err != nil {
			staged.discard()
			fatal("publish theme: %v", err)
		}
		staged.discard()
		reloadHyprland()
		saveSetting("theme.preset", path)
		saveSetting("theme.syncedToWallpaper", "false")
		fmt.Printf("sync: off (%s)\n", filepath.Base(path))
	default:
		fatal("usage: qsh sync on|off (got %q)", args[0])
	}
}

// qsh scheme <type> — persist the matugen material scheme type. Regenerates
// immediately only while colours are synced to the wallpaper.
func schemeCmd(args []string) {
	if len(args) != 1 {
		fatal("usage: qsh scheme <scheme-type>")
	}
	scheme := args[0]
	if !containsString(schemeTypes, scheme) {
		fatal("unknown scheme %q; expected one of: %s", scheme, strings.Join(schemeTypes, ", "))
	}
	p := loadSettings()
	synced := p["theme.syncedToWallpaper"] != "false"
	w := p["theme.wallpaper"]
	if !synced || w == "" {
		saveSetting("theme.scheme", scheme)
		fmt.Printf("scheme: %s stored (applies when sync is on)\n", scheme)
		return
	}
	staged, err := generateImage(w, scheme, p["theme.sourceColorIndex"])
	if err != nil {
		fatal("%v", err)
	}
	if _, err := staged.publish(); err != nil {
		staged.discard()
		fatal("publish theme: %v", err)
	}
	staged.discard()
	reloadHyprland()
	saveSetting("theme.scheme", scheme)
	fmt.Printf("scheme: %s\n", scheme)
}

// qsh bootstrap — create a working default theme and hyprpaper config on a
// fresh checkout without requiring external apps or a live Hyprland session.
func bootstrapCmd(args []string) {
	if len(args) != 0 {
		fatal("usage: qsh bootstrap")
	}
	colors := filepath.Join(dotfilesRoot, "quickshell", "services", "Colors.qml")
	kitty := filepath.Join(dotfilesRoot, "kitty", "matugen.conf")
	chrome := filepath.Join(dotfilesRoot, "chrome", "matugen-chrome.css")
	content := filepath.Join(dotfilesRoot, "chrome", "matugen-content.css")
	hyprColors := filepath.Join(dotfilesRoot, "hypr", "themes", "matugen_colors.lua")

	needsTheme := !hasGeneratedMarker(colors) ||
		isEmptyFile(kitty) || isEmptyFile(chrome) ||
		isEmptyFile(content) || isEmptyFile(hyprColors)

	if needsTheme {
		preset := filepath.Join(configHome(), "matugen", "presets", "default.json")
		cfg := filepath.Join(dotfilesRoot, "matugen", "bootstrap.toml")
		staged, err := generatePreset(preset, cfg)
		if err != nil {
			fatal("bootstrap theme: %v", err)
		}
		if _, err := staged.publish(); err != nil {
			staged.discard()
			fatal("bootstrap theme: %v", err)
		}
		staged.discard()
		reloadHyprland()
	}

	if isEmptyFile(hyprPaperConf) {
		names := listImages(wallpaperDir)
		if len(names) > 0 {
			if err := writeHyprpaperConf(filepath.Join(wallpaperDir, names[0])); err != nil {
				fatal("bootstrap wallpaper: %v", err)
			}
		}
	}

	fmt.Println("bootstrap: ok")
}

// ─── Staged theme generation ─────────────────────────────────────────

type themeTarget struct {
	dest   string
	staged string
}

type stagedTheme struct {
	dir     string
	targets []themeTarget
}

type savedFile struct {
	existed bool
	data    []byte
	mode    os.FileMode
}

type publishedTheme struct {
	saved map[string]savedFile
}

// generateImage stages a palette derived from an image using config.toml.
func generateImage(file, schemeOverride, indexOverride string) (*stagedTheme, error) {
	scheme := matugenSchemeValue(schemeOverride)
	index := indexOverride
	if index == "" {
		index = loadSettings()["theme.sourceColorIndex"]
	}
	if index == "" {
		index = "0"
	}
	cfg := filepath.Join(configHome(), "matugen", "config.toml")
	return runMatugen(cfg, "image", file, scheme, index)
}

// generatePreset stages a fixed preset. An empty cfg uses presets/config.toml.
func generatePreset(preset, cfgOverride string) (*stagedTheme, error) {
	cfg := cfgOverride
	if cfg == "" {
		cfg = filepath.Join(configHome(), "matugen", "presets", "config.toml")
	}
	return runMatugen(cfg, "json", preset, "", "")
}

// runMatugen rewrites output paths into a temp directory, runs matugen, then
// validates every staged output before anything is published.
func runMatugen(cfgPath, mode, input, scheme, index string) (*stagedTheme, error) {
	stageDir, err := os.MkdirTemp("", "qsh-theme-")
	if err != nil {
		return nil, fmt.Errorf("create staging dir: %w", err)
	}
	stageCfg, targets, err := stageConfig(cfgPath, stageDir)
	if err != nil {
		os.RemoveAll(stageDir)
		return nil, err
	}

	var args []string
	if mode == "image" {
		args = []string{"image", "--type", scheme, "--source-color-index", index, "-c", stageCfg, input}
	} else {
		args = []string{"json", input, "-c", stageCfg}
	}
	out, err := exec.Command("matugen", args...).CombinedOutput()
	if err != nil {
		os.RemoveAll(stageDir)
		return nil, fmt.Errorf("matugen %s %s: %v\n%s", mode, input, err, strings.TrimSpace(string(out)))
	}

	for _, t := range targets {
		if err := validateStaged(t.staged); err != nil {
			os.RemoveAll(stageDir)
			return nil, fmt.Errorf("validate %s: %v", t.dest, err)
		}
	}
	return &stagedTheme{dir: stageDir, targets: targets}, nil
}

// stageConfig copies a matugen config and rewrites each output_path to a file
// inside stageDir. The returned targets preserve the real destinations.
func stageConfig(src, stageDir string) (string, []themeTarget, error) {
	data, err := os.ReadFile(expandHome(src))
	if err != nil {
		return "", nil, fmt.Errorf("read matugen config %s: %w", src, err)
	}
	lines := strings.Split(string(data), "\n")
	var targets []themeTarget
	for i, line := range lines {
		trimmed := strings.TrimSpace(line)
		if !strings.HasPrefix(trimmed, "output_path") {
			continue
		}
		eq := strings.Index(line, "=")
		if eq < 0 {
			continue
		}
		raw := strings.TrimSpace(line[eq+1:])
		raw = strings.Trim(raw, `"'`)
		if raw == "" {
			continue
		}
		staged := filepath.Join(stageDir, fmt.Sprintf("out-%d", len(targets)))
		targets = append(targets, themeTarget{dest: expandHome(raw), staged: staged})
		lines[i] = line[:eq+1] + " '" + staged + "'"
	}
	if len(targets) == 0 {
		return "", nil, fmt.Errorf("no output_path entries in %s", src)
	}
	stageCfg := filepath.Join(stageDir, "config.toml")
	if err := os.WriteFile(stageCfg, []byte(strings.Join(lines, "\n")), 0o600); err != nil {
		return "", nil, fmt.Errorf("write staging config: %w", err)
	}
	return stageCfg, targets, nil
}

func validateStaged(path string) error {
	data, err := os.ReadFile(path)
	if err != nil {
		return err
	}
	text := strings.TrimSpace(string(data))
	if text == "" {
		return errors.New("empty output")
	}
	switch strings.ToLower(filepath.Ext(path)) {
	case ".qml":
		if !strings.Contains(text, "readonly property color bg") {
			return errors.New("missing shell palette properties")
		}
	case ".lua":
		if !strings.Contains(text, "return colors") {
			return errors.New("missing Lua colour table")
		}
	case ".json":
		if !json.Valid(data) {
			return errors.New("invalid JSON")
		}
	}
	return nil
}

// publish atomically replaces each destination and remembers the previous
// contents. If any target fails, the targets already written are restored so a
// failed apply never leaves a half-themed system.
func (s *stagedTheme) publish() (*publishedTheme, error) {
	pub := &publishedTheme{saved: map[string]savedFile{}}
	fail := func(err error) (*publishedTheme, error) {
		pub.rollback()
		return nil, err
	}
	for _, t := range s.targets {
		saved, err := snapshotFile(t.dest)
		if err != nil {
			return fail(fmt.Errorf("snapshot %s: %w", t.dest, err))
		}
		pub.saved[t.dest] = saved
		if err := os.MkdirAll(filepath.Dir(t.dest), 0o755); err != nil {
			return fail(fmt.Errorf("create %s: %w", filepath.Dir(t.dest), err))
		}
		tmp := t.dest + ".qsh-tmp"
		if err := copyFile(t.staged, tmp, 0o644); err != nil {
			return fail(fmt.Errorf("write %s: %w", t.dest, err))
		}
		if err := os.Rename(tmp, t.dest); err != nil {
			os.Remove(tmp)
			return fail(fmt.Errorf("publish %s: %w", t.dest, err))
		}
	}
	return pub, nil
}

func (s *stagedTheme) discard() {
	if s != nil && s.dir != "" {
		_ = os.RemoveAll(s.dir)
	}
}

// rollback restores every published file to its previous contents.
func (p *publishedTheme) rollback() {
	if p == nil {
		return
	}
	for dest, saved := range p.saved {
		if saved.existed {
			_ = os.WriteFile(dest, saved.data, saved.mode)
		} else {
			_ = os.Remove(dest)
		}
	}
}

func snapshotFile(path string) (savedFile, error) {
	info, err := os.Stat(path)
	if errors.Is(err, os.ErrNotExist) {
		return savedFile{}, nil
	}
	if err != nil {
		return savedFile{}, err
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return savedFile{}, err
	}
	return savedFile{existed: true, data: data, mode: info.Mode()}, nil
}

func copyFile(src, dst string, mode os.FileMode) error {
	data, err := os.ReadFile(src)
	if err != nil {
		return err
	}
	return os.WriteFile(dst, data, mode)
}

func expandHome(path string) string {
	if path == "~" {
		return userHome()
	}
	if strings.HasPrefix(path, "~/") {
		return filepath.Join(userHome(), path[2:])
	}
	return path
}

func fileExists(path string) bool {
	info, err := os.Stat(expandHome(path))
	return err == nil && !info.IsDir()
}

func isEmptyFile(path string) bool {
	info, err := os.Stat(path)
	return errors.Is(err, os.ErrNotExist) || (err == nil && info.Size() == 0)
}

func hasGeneratedMarker(path string) bool {
	data, err := os.ReadFile(path)
	if err != nil {
		return false
	}
	return strings.Contains(strings.ToLower(string(data)), "generated by matugen")
}

// activeWallpaper reads the active wallpaper from hyprpaper.conf.
func activeWallpaper() string {
	data, err := os.ReadFile(hyprPaperConf)
	if err != nil {
		return ""
	}
	for _, line := range strings.Split(string(data), "\n") {
		l := strings.TrimSpace(line)
		if strings.HasPrefix(l, "preload = ") {
			return expandHome(strings.TrimSpace(strings.TrimPrefix(l, "preload = ")))
		}
	}
	for _, line := range strings.Split(string(data), "\n") {
		l := strings.TrimSpace(line)
		if strings.HasPrefix(l, "path = ") {
			return expandHome(strings.TrimSpace(strings.TrimPrefix(l, "path = ")))
		}
	}
	return ""
}

// reloadHyprland applies generated border colours. It is best-effort: a missing
// Hyprland session must not fail a theme apply.
func reloadHyprland() {
	if out, err := exec.Command("hyprctl", "reload").CombinedOutput(); err != nil {
		fmt.Fprintf(os.Stderr, "qsh: warning: hyprctl reload: %v\n%s", err, strings.TrimSpace(string(out)))
	}
}

// applyHyprpaper switches the live wallpaper: it rewrites hypr/hyprpaper.conf
// to (pre)load every wallpaper plus mark `file` active, then applies it via the
// IPC that this hyprpaper build actually supports. Newly added wallpapers that
// weren't loaded at hyprpaper boot need a restart to take effect; that's done
// automatically here. On failure the previous config is restored.
func applyHyprpaper(file string) error {
	old, err := os.ReadFile(hyprPaperConf)
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return fmt.Errorf("read %s: %w", hyprPaperConf, err)
	}
	restore := func() {
		if old != nil {
			_ = os.WriteFile(hyprPaperConf, old, 0o644)
		} else {
			_ = os.Remove(hyprPaperConf)
		}
	}
	if err := writeHyprpaperConf(file); err != nil {
		return err
	}
	// If the chosen wallpaper wasn't already preloaded in the config hyprpaper
	// started with, the running daemon can't display it yet — bounce it so the
	// regen'd preload list takes effect. Otherwise a live IPC switch suffices.
	if !wasPreloaded(string(old), file) {
		if err := restartHyprpaper(); err != nil {
			restore()
			return err
		}
	}
	// The empty-monitor form (",path") is silently ignored by some hyprpaper
	// builds, so target each active monitor explicitly. Only fall back to the
	// empty-monitor form when no monitors can be enumerated.
	monitors := listMonitors()
	if len(monitors) == 0 {
		monitors = []string{""}
	}
	for _, m := range monitors {
		out, err := exec.Command("hyprctl", "hyprpaper", "wallpaper", m+","+file).CombinedOutput()
		if err != nil {
			restore()
			return fmt.Errorf("hyprctl hyprpaper wallpaper %s: %v\n%s", m, err, strings.TrimSpace(string(out)))
		}
	}
	return nil
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
func writeHyprpaperConf(active string) error {
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
		return fmt.Errorf("write %s: %w", hyprPaperConf, err)
	}
	return nil
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

// restartHyprpaper bounces the daemon so it reloads hypr/hyprpaper.conf. A
// missing process is not an error: `pkill` exits 1 when there is nothing to
// kill. The relaunch is detached with setsid so it survives qsh exiting.
func restartHyprpaper() error {
	_, _ = exec.Command("pkill", "-x", "hyprpaper").CombinedOutput()
	if err := exec.Command("setsid", "hyprpaper").Start(); err != nil {
		return fmt.Errorf("start hyprpaper: %w", err)
	}
	// give it a moment to connect to Hyprland
	time.Sleep(500 * time.Millisecond)
	return nil
}

// shellQuote wraps s in double quotes for use inside hyprpaper.conf keywords
// and shell arguments (hyprpaper paths may contain spaces).
func shellQuote(s string) string {
	return `"` + strings.ReplaceAll(s, `"`, `\"`) + `"`
}

// qsh wallpapers — list available wallpapers (image files only, one per line).
func listWallpapersCmd() {
	for _, n := range listImages(wallpaperDir) {
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
	file := resolveExisting(args[0], wallpaperDir, "wallpaper")
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
			Colors map[string]struct {
				Default struct{ Color string } `json:"default"`
			} `json:"colors"`
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
	names := listDir(filepath.Join(configHome(), "matugen", "presets"))
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
	staged, err := generatePreset(preset, "")
	if err != nil {
		fatal("%v", err)
	}
	if _, err := staged.publish(); err != nil {
		staged.discard()
		fatal("publish theme: %v", err)
	}
	staged.discard()
	reloadHyprland()
	// Store the resolved path so custom presets outside the presets directory
	// can be restored later.
	saveSetting("theme.preset", preset)
	saveSetting("theme.syncedToWallpaper", "false")
	fmt.Printf("theme: %s (preset; wallpaper unchanged)\n", filepath.Base(preset))
}

// resolvePreset returns the full path to a theme preset: either a direct file
// path or a preset name resolved from the matugen presets directory.
func resolvePreset(name string) string {
	name = expandHome(name)
	if _, err := os.Stat(name); err == nil {
		return name
	}
	dir := filepath.Join(configHome(), "matugen", "presets")
	candidate := filepath.Join(dir, name+".json")
	if _, err := os.Stat(candidate); err == nil {
		return candidate
	}
	return resolveExisting(name, dir, "theme")
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
  qsh panel toggle                        toggle the right panel (reopens last context)
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
         [--scheme T] [--no-theme]        --index 0 = most dominant colour;
                                          --scheme e.g. scheme-expressive;
                                          --no-theme changes only the wallpaper
  qsh colors <image|name>                 diagnose: candidate source colours +
                                          resulting palette for each index
                                          (and current scheme)
  qsh sync on|off                         sync colours to wallpaper (or revert preset)
  qsh scheme <type>                       persist matugen scheme type + re-derive
                                          only while sync is on
  qsh themes                              list available theme presets
  qsh theme <preset|json-file>            apply a fixed theme preset
  qsh bootstrap                           generate a default theme (setup only)
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
