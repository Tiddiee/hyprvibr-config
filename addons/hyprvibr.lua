--- VibranceGUI for Linux Hyprland
--- This (hl.exec.cmd) checks if the app hpyrvibr is isntalled and running, if it isnt then it restarts and reloads it
--- to add more apps to this, use the following command to get the class (initialClass)
--- hyprctl -j clients | jq '.[] | {title, class, initialClass}'

-- Hyprvibr app saturation settings
-- Rules are loaded from hyprvibr-app-rules.lua.conf

local rules_file = os.getenv("HOME") .. "/.config/hypr/addons/hyprvibr-app-rules.lua.conf"

if hl.plugin.hyprvibr ~= nil then
	local file, err = io.open(rules_file, "r")
	if file then
		for raw_line in file:lines() do
			-- Ignore comments and blank lines
			local line = raw_line:match("^(.-)#") or raw_line
			line = line:match("^%s*(.-)%s*$")

			if line ~= "" and not line:match("^#") then
				local class, sat = line:match("^([^|]+)|([^|]+)$")

				if class and sat then
					class = class:match("^%s*(.-)%s*$")
					sat = tonumber(sat:match("^%s*(.-)%s*$"))

					if class ~= "" and sat then
						hl.plugin.hyprvibr.hyprvibr_app({
							class = class,
							sat = sat,
						})
					else
						print("[hyprvibr] Invalid rule: " .. line)
					end
				else
					print("[hyprvibr] Invalid rule: " .. line)
				end
			end
		end

		file:close()
	else
		print("[hyprvibr] Could not open rules file: " .. tostring(err))
	end
else
	-- Preserve the existing plugin reload fallback
	hl.exec_cmd(
		"sh -c 'hyprpm reload -n; sleep 1; "
			.. "if hyprctl plugin list 2>/dev/null | grep -q hyprvibr; "
			.. "then hyprctl reload; fi'"
	)
end
