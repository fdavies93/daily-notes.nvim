local utils = require("daily-notes.utils")

local M = {}

local default = {
	parsing = {
		-- The default string to send to fuzzy_time for parsing
		-- if nothing else is entered
		default = "today",
		-- This is localised so needs changing if you're not using
		-- English
		week_starts = "monday",
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
				"%d %B, %Y",
				"%d %b, %Y",
				"%B %d, %Y",
				"%b %d, %y",
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
		resolve_strategy = {
			weekday = {
				-- closest: the shortest number of days to match
				-- the name of the weekday / month
				-- for next this always goes forward
				-- for prev this always goes back
				-- for this it checks both directions
				-- forward: count forwards for match
				-- back: count backwards for match
				-- adjust_this: use the same algorithm as this,
				-- then add / subtract weeks
				-- period: use dates in the same period
				-- (week / year)
				-- this := closest | forward | back | period
				-- next := closest | adjust_this | period
				-- prev := closest | adjust_this | period
				-- numerical offsets always use adjust_this
				this = "period",
				next = "adjust_this",
				prev = "adjust_this"
			},
			month = {
				this = "period",
				next = "adjust_this",
				prev = "adjust_this"
			}
		},
	},
	writing = {
		-- recommended to change this
		root = "~/daily-notes",
		filetype = "md",
		write_on_open = true,
		-- templates can be a string or a lua integer table of strings
		day = {
			filename = "daily/%Y-%m-%d",
			template = "# %A, %B %d %Y\n\n"
		},
		week = {
			filename = "weekly/%Y-week-%W",
			template = "# Week %W, %Y\n\n"
		},
		month = {
			filename = "monthly/%Y-%m",
			template = "# %B %Y\n\n"
		},
		year = {
			filename = "%Y",
			template = "# %Y\n\n"
		}
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
