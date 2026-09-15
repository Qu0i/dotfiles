------------------------
------- MONITORS -------
------------------------

hl.monitor({
	output = "HDMI-A-1",
	mode = "1920x1080@59.94",
	position = "0x0",
	scale = 1,
})

hl.monitor({
	output = "DP-1",
	mode = "1920x1080@60",
	position = "-1920x0",
	scale = 1,
})

for i = 1, 4 do
	hl.workspace_rule({
		workspace = tostring(i),
		monitor = "HDMI-A-1",
	})
end

for i = 5, 8 do
	hl.workspace_rule({
		workspace = tostring(i),
		monitor = "DP-1",
	})
end
