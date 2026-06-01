-- █▄▀ █▀▀ █▄█ █▄▄ █ █▄░█ █▀▄ █ █▄░█ █▀▀ █▀
-- █░█ ██▄ ░█░ █▄█ █ █░▀█ █▄▀ █ █░▀█ █▄█ ▄█

local mainMod = "SUPER"

-- Assign apps
local term = "kitty"
local editor = "nvim"
local file = "dolphin"
local browser = "firefox"

-- Window/Session actions
hl.bind(mainMod .. " + W", hl.dsp.window.close())

-- Application shortcuts
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(term))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd(browser))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(file))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.dotfiles/setup.sh"))

-- Rofi menus
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd("rofi -show drun"), { description = "App Launcher" })
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("~/.dotfiles/bin/menu_system.sh"), { description = "Controls menu" })
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("rofi -show system"), { description = "System menu" })
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("rofi -show capture"), { description = "Screen Capture menu" })
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("~/.dotfiles/bin/menu_actions.sh"), { description = "Actions Menu" })

-- Audio control
hl.bind("F10", hl.dsp.exec_cmd("volumecontrol.sh -o m"), { locked = true })
hl.bind("F11", hl.dsp.exec_cmd("volumecontrol.sh -o d"), { locked = true, repeating = true })
hl.bind("F12", hl.dsp.exec_cmd("volumecontrol.sh -o i"), { locked = true, repeating = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("volumecontrol.sh -o m"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("volumecontrol.sh -i m"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("volumecontrol.sh -o d"), { locked = true, repeating = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("volumecontrol.sh -o i"), { locked = true, repeating = true })

-- Media control
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-- Brightness control
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnesscontrol.sh i"), { repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnesscontrol.sh d"), { repeating = true })

-- Move between grouped windows
-- hl.bind(mainMod .. " + Ctrl + H", hl.dsp.changegroupactive("b"))
-- hl.bind(mainMod .. " + Ctrl + L", hl.dsp.changegroupactive("f"))

-- Screenshot/Screencapture
hl.bind("Print", hl.dsp.exec_cmd("~/.dotfiles/bin/capture.sh PrintScreen"), { description = "Print Screen" })
hl.bind(
	mainMod .. " + P",
	hl.dsp.exec_cmd("~/.dotfiles/bin/capture.sh ScreenShot"),
	{ description = "Screenshot Region" }
)

-- Custom scripts
hl.bind(mainMod .. " + ALT + G", hl.dsp.exec_cmd("gamemode.sh"))
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("keyboardswitch.sh"))

-- Move/Change window focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "d" }))

-- Switch workspaces
for i = 1, 9 do
	hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
end
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

-- Switch workspaces to a relative workspace
hl.bind(mainMod .. " + ALT + H", hl.dsp.focus({ workspace = "r+1" }))
hl.bind(mainMod .. " + ALT + L", hl.dsp.focus({ workspace = "r-1" }))

-- Resize windows
hl.bind(mainMod .. " + SHIFT + Right", hl.dsp.window.resize({ x = 30, y = 0 }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Left", hl.dsp.window.resize({ x = -30, y = 0 }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Up", hl.dsp.window.resize({ x = 0, y = -30 }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + Down", hl.dsp.window.resize({ x = 0, y = 30 }), { repeating = true })

-- Move focused window to a workspace
for i = 1, 9 do
	hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Move active window around current workspace
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "d" }))

-- Scroll through existing workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move/Resize focused window
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Toggle focused window split
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
