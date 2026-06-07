-- ___________      _________                        __
-- \__    ___/      \_   ___ \_______ ___.__._______/  |_
--  |    |  ______ /    \  \/\_  __ <   |  |\____ \   __\
--  |    | /_____/ \     \____|  | \/\___  ||  |_> >  |
--  |____|          \______  /|__|   / ____||   __/|__|
--                         \/        \/     |__|

hl.exec_cmd("gsettings set org.gnome.desktop.interface icon-theme 'Nordzy'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme 'Nordic-Blue'")
hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'")

hl.config({
	general = {
		gaps_in = 0,
		gaps_out = 0,
		border_size = 1,
		col = {
			active_border = { colors = { "rgba(F9CE73ee)" }, angle = 45 },
			-- inactive_border = { colors = { "rgba(2A142Cbb)" } },
		},
		layout = "dwindle",
		resize_on_border = true,
	},
	group = {
		col = {
			border_active = { colors = { "rgba(ca9ee6ff)", "rgba(f2d5cfff)" }, angle = 45 },
		},
	},
	decoration = {
		rounding = 0,
		shadow = {
			enabled = false,
		},
		dim_inactive = true,
		dim_strength = 0.25,
		blur = {
			enabled = false,
			size = 5,
			passes = 3,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
			-- blurls = "waybar",
		},
	},
})
