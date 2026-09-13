local terminal = "kitty"
local fileManager = "dolphin"
local launcher = "~/.config/rofi/launchers/type-6/./launcher.sh"

---------------------
---- KEYBINDINGS ----
---------------------

local mainMod = "SUPER"

-- Apps

hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(launcher))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd(fileManager))

-- Waybar restart

hl.bind(mainMod .. " + DELETE", hl.dsp.exec_cmd("killall waybar && waybar"))

-- Screenshots

hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m output -o active"))
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("slurp | grim -g - - | wl-copy -t image/png"))

-- Window navigation
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + O", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.workspace.swap_monitors({ monitor1 = "HDMI-A-1", monitor2 = "DP-1" }))

-- Move focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }), { repeating = true })
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }), { repeating = true })
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }), { repeating = true })
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }), { repeating = true })

-- Move windows
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }), { repeating = true })
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }), { repeating = true })

-- Move windows with mainMod + LMB
-- Resize with mainMod + RMB
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Switch workspaces with mainMod + [0-9]
-- Move active window to a workspace with mainMod + ALT + [0-9]
for i = 1, 9 do
	local key = i % 10 -- 10 maps to key 0
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + ALT + " .. key, hl.dsp.window.move({ workspace = i }))
end

-- Example special workspace (scratchpad)
hl.bind(mainMod .. " + 0", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + ALT + 0", hl.dsp.window.move({ workspace = "special:magic" }))

-- Scroll through existing workspaces with mainMod + scroll
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Multimedia keys for volume and LCD brightness
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind(
	"XF86AudioMicMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
	{ locked = true, repeating = true }
)
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })

-- Player controls
-- Requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
