-- █░█░█ █ █▄░█ █▀▄ █▀█ █░█░█   █▀█ █░█ █░░ █▀▀ █▀
-- ▀▄▀▄▀ █ █░▀█ █▄▀ █▄█ ▀▄▀▄▀   █▀▄ █▄█ █▄▄ ██▄ ▄█

-- Workspace assignments
hl.window_rule({ name = "Zen", match = { class = "^(zen)$" }, workspace = "2 silent" })
hl.window_rule({ name = "Alacritty", match = { class = "^(Alacritty)$" }, workspace = "1 silent" })
hl.window_rule({ name = "Kitty", match = { class = "^(kitty)$" }, workspace = "1 silent" })
hl.window_rule({ name = "Obsidian", match = { class = "^(obsidian)$" }, workspace = "1 silent" })
hl.window_rule({ name = "Firefox", match = { class = "^(firefox)$" }, workspace = "2 silent" })
hl.window_rule({ name = "Steam", match = { class = "^(steam)$" }, workspace = "3 silent" })
hl.window_rule({ name = "CurseForge", match = { class = "^(CurseForge)$" }, workspace = "3 silent" })


-- Floating Windows
hl.window_rule({ name = "Progress Dialog — Dolphin", match = { class = "^(org.kde.dolphin)$", title = "^(Progress Dialog — Dolphin)$" }, float = true })
hl.window_rule({ name = "Copying — Dolphin", match = { class = "^(org.kde.dolphin)$", title = "^(Copying — Dolphin)$" }, float = true })
hl.window_rule({ name = "About Mozilla Firefox", match = { title = "^(About Mozilla Firefox)$" }, float = true })
hl.window_rule({ name = "firefox", match = { class = "^(firefox)$" }, float = true })
hl.window_rule({ name = "Library", match = { class = "^(firefox)$", title = "^(Library)$" }, float = true })
hl.window_rule({ name = "top", match = { class = "^(kitty)$", title = "^(top)$" }, float = true })
hl.window_rule({ name = "btop", match = { class = "^(kitty)$", title = "^(btop)$" }, float = true })
hl.window_rule({ name = "htop", match = { class = "^(kitty)$", title = "^(htop)$" }, float = true })
hl.window_rule({ name = "vlc", match = { class = "^(vlc)$" }, float = true })
hl.window_rule({ name = "kvantummanager", match = { class = "^(kvantummanager)$" }, float = true })
hl.window_rule({ name = "qt5ct", match = { class = "^(qt5ct)$" }, float = true })
hl.window_rule({ name = "qt6ct", match = { class = "^(qt6ct)$" }, float = true })
hl.window_rule({ name = "nwg-look", match = { class = "^(nwg-look)$" }, float = true })
hl.window_rule({ name = "org.kde.ark", match = { class = "^(org.kde.ark)$" } })
hl.window_rule({ name = "org.pulseaudio.pavucontrol", match = { class = "^(org.pulseaudio.pavucontrol)$" }, float = true })
hl.window_rule({ name = "blueman-manager", match = { class = "^(blueman-manager)$" }, float = true })
hl.window_rule({ name = "nm-applet", match = { class = "^(nm-applet)$" }, float = true })
hl.window_rule({ name = "nm-connection-editor", match = { class = "^(nm-connection-editor)$" }, float = true })
hl.window_rule({ name = "org.kde.polkit-kde-authentication-agent-1", match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, float = true })
hl.window_rule({ name = "Signal", match = { class = "^(Signal)$" }, float = true })
hl.window_rule({ name = "com.github.rafostar.Clapper", match = { class = "^(com.github.rafostar.Clapper)$" }, float = true })
hl.window_rule({ name = "app.drey.Warp", match = { class = "^(app.drey.Warp)$" }, float = true })
hl.window_rule({ name = "net.davidotek.pupgui2", match = { class = "^(net.davidotek.pupgui2)$" }, float = true })
hl.window_rule({ name = "yad", match = { class = "^(yad)$" }, float = true })
hl.window_rule({ name = "eog", match = { class = "^(eog)$" }, float = true })
hl.window_rule({ name = "io.github.alainm23.planify", match = { class = "^(io.github.alainm23.planify)$" }, float = true })
hl.window_rule({ name = "io.gitlab.theevilskeleton.Upscaler", match = { class = "^(io.gitlab.theevilskeleton.Upscaler)$" }, float = true })
hl.window_rule({ name = "com.github.unrud.VideoDownloader", match = { class = "^(com.github.unrud.VideoDownloader)$" }, float = true })
hl.window_rule({ name = "io.gitlab.adhami3310.Impression", match = { class = "^(io.gitlab.adhami3310.Impression)$" }, float = true })
hl.window_rule({ name = "io.missioncenter.MissionCenter", match = { class = "^(io.missioncenter.MissionCenter)$" }, float = true })


-- █░░ ▄▀█ █▄█ █▀▀ █▀█   █▀█ █░█ █░░ █▀▀ █▀
-- █▄▄ █▀█ ░█░ ██▄ █▀▄   █▀▄ █▄█ █▄▄ ██▄ ▄█

hl.layer_rule({ name = "rofi", match = { namespace = "rofi" }, no_anim = true })

hl.layer_rule({ name = "notifications-blur", match = { namespace = "notifications" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "swaync-notification-blur", match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "swaync-control-blur", match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = 0 })
hl.layer_rule({ name = "logout-dialog-blur", match = { namespace = "logout_dialog" }, blur = true })
