local default = {
	-- recommended to change this
	root = "~/daily-notes",
	parsing = {
		timestamp_formats = {
			-- ISO date format is preferred (it's unambiguous)
			-- 4-digit years are preferred over 2-digit years for
			-- the same reason as ISO dates.
			-- If you'd like to change the precedence and formats
			-- try changing this in your config.
			day = {
				"%Y-%m-%d",
				"%Y/%m/%d",
				"%d/%m/%Y",
				"%m/%d/%Y",
				"%y/%m/%d",
				"%d/%m/%y",
				"%m/%d/%y",
				"%A, %B %d %Y"
			},
			week = {
				"%Y Week %W",
				"Week %W, %Y"
			}
		},
		week_starts = "monday",
	},
	writing = {
		filetype = "md",
		daily = {
			directory = "daily",
			filename = "%Y-%m-%d",
			template = "%A, %B %d %Y\n\n"
		},
		weekly = {
			directory = "weekly",
			filename = "%Y-week-%W",
			template = "Week %W, %Y\n\n"
		}
	}
}
