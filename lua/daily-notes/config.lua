local utils = require("daily-notes.utils")

local M = {}

local default = {
	parsing = {
		-- The default string to send to fuzzy_time for parsing
		-- if nothing
		default = "today",
		-- Needed to iterate correctly through formats
		timestamp_order = { "day", "month", "year" },
		timestamp_formats = {
			-- ISO date format is preferred (it's unambiguous)
			-- 4-digit years are preferred over 2-digit years for
			-- the same reason as ISO dates.
			-- If you'd like to change the precedence and formats
			-- try changing this in your config.
			day = {
				"%x", -- timezone native format
				"%Y-%m-%d",
				"%Y/%m/%d",
				"%d/%m/%Y",
				"%m/%d/%Y",
				"%A, %B %d %Y",
				"%a, %B %d %Y",
			},
			-- Weeks do not appear to be supported (on Arch Linux)
			-- therefore custom parsing is implemented for them.
			month = {
				"%Y-%m",
				"%Y/%m",
				"%B %Y",
				"%b %Y",
				"%B, %Y",
				"%b, %Y"
			},
			year = {
				"%Y"
			}
		},
		week_starts = 2, -- i.e Monday
	},
	writing = {
		-- recommended to change this
		root = "~/daily-notes",
		filetype = "md",
		write_on_open = true,
		day = {
			directory = "daily",
			filename = "%Y-%m-%d",
			template = "# %A, %B %d %Y\n\n"
		},
		week = {
			directory = "weekly",
			filename = "%Y-week-%W",
			template = "# Week %W, %Y\n\n"
		},
		month = {
			directory = "monthly",
			filename = "%Y-%m",
			template = "# %B %Y\n\n"
		},
	}
}

M.setup = function(opts)
	local src = {}
	if opts ~= nil then
		src = opts
	end
	utils.merge_table_to_target(src, default)
end

M.get = function()
	return default
end

return M
