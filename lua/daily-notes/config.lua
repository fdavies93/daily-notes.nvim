local M = {}

local default = {
	parsing = {
		-- Needed to iterate correctly through formats
		timestamp_order = { "day", "week", "month", "year" },
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
			-- In rare cases, weeks might need offsetting based on
			-- the first day of the week.
			week = {
				"%Y Week %W",
				"Week %W, %Y"
			},
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
		week_starts = "monday",
	},
	writing = {
		-- recommended to change this
		root = "~/daily-notes",
		filetype = "md",
		day = {
			directory = "daily",
			filename = "%Y-%m-%d",
			template = "%A, %B %d %Y\n\n"
		},
		week = {
			directory = "weekly",
			filename = "%Y-week-%W",
			template = "Week %W, %Y\n\n"
		}
	}
}

M.get = function()
	return default
end

return M
