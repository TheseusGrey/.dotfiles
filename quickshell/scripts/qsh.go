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
	"strconv"
	"strings"
)

const socketPath = "/tmp/qs-finder.sock"

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
	case "theme":
		themeCmd(args)
	case "call":
		if len(args) < 2 {
			fatal("usage: qsh call <target> <method> [args...]")
		}
		mustIPC(args)
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
		"power", "notifications", "keybinds", "menu",
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
			fatal("unknown context %q (want volume|brightness|wifi|bluetooth|power|notifications|keybinds|menu)", args[1])
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

// qsh wallpaper <image> — regenerate the theme from an image.
// Runs matugen (sets the wallpaper via hyprpaper and regenerates
// Colors.qml / hypr / waybar from the config.toml templates).
func wallpaperCmd(args []string) {
	if len(args) != 1 {
		fatal("usage: qsh wallpaper <image>")
	}
	if info, err := os.Stat(args[0]); err != nil || info.IsDir() {
		fatal("not an image file: %s", args[0])
	}
	out, err := exec.Command("matugen", "image", "--type", "scheme-expressive", args[0]).CombinedOutput()
	if err != nil {
		fatal("matugen image %s: %v\n%s", args[0], err, strings.TrimSpace(string(out)))
	}
	if len(out) > 0 {
		fmt.Print(string(out))
	}
}

// qsh theme <preset> — apply a fixed theme preset (not tied to the wallpaper).
// Presets: default | catppuccin (or path to a matugen colors .json).
// Renders through the raw (unclamped) templates in matugen/presets/config.toml.
func themeCmd(args []string) {
	if len(args) != 1 {
		fatal("usage: qsh theme <preset|json-file> (presets: default, catppuccin)")
	}
	file := args[0]
	if _, err := os.Stat(file); err != nil {
		home, herr := os.UserHomeDir()
		if herr != nil {
			fatal("couldn't resolve home: %v", herr)
		}
		file = home + "/.config/matugen/presets/" + file + ".json"
		if _, err := os.Stat(file); err != nil {
			fatal("unknown theme preset %q: %v", args[0], err)
		}
	}
	cfg := os.Getenv("HOME") + "/.config/matugen/presets/config.toml"
	out, err := exec.Command("matugen", "json", file, "-c", cfg).CombinedOutput()
	if err != nil {
		fatal("matugen json %s: %v\n%s", file, err, strings.TrimSpace(string(out)))
	}
	if len(out) > 0 {
		fmt.Print(string(out))
	}
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
                                          bluetooth|power|notifications|keybinds|menu)
  qsh panel left                          expand/collapse the left rail
  qsh panel close                         close all panels
  qsh osd volume <0-1> [muted]            show volume OSD
  qsh osd brightness <0-1>                show brightness OSD
  qsh notify clear                        clear notifications
  qsh lock                                show the lock screen
  qsh pick [--items a,b,c] [--prompt t]   interactive picker (items from stdin
                                          unless --items is given); prints selection
  qsh wallpaper <image>                   regenerate theme from a wallpaper image
  qsh theme <preset|json-file>            apply a fixed theme preset (default, catppuccin)
  qsh call <target> <method> [args...]    raw IPC call
  qsh help                                show this help
  qsh version                             show version

Examples:
  qsh panel open volume
  qsh osd volume 0.75 true
  qsh pick --prompt "checkout branch" < <(git branch --format='%(refname:short)')
  qsh call tui.shell toggleWifi
`)
}
