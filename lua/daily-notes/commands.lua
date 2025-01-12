local M = {}

local config = require("daily-notes.config")
local fuzzy_time = require("daily-notes.fuzzy-time")
local files = require("daily-notes.files")

M.fuzzy_time = function(opts)
	local as_str = table.concat(opts.fargs, ' ')
	local c = config.get()
	local date = fuzzy_time.get_period(as_str, c.parsing)
	if date == nil then
		print("Couldn't parse date \"" .. as_str .. "\"!")
		return
	end
	local timestamp = os.time(date[1]) -- ignore linter error here
	local time_string = os.date("%Y-%m-%d", timestamp)
	print(time_string .. " - " .. date[2])
end

M.daily_note = function(opts)
	local as_str = table.concat(opts.fargs, ' ')
	local c = config.get()

	if string.len(as_str) == 0 then
		as_str = c.parsing.default
	end
	local period = fuzzy_time.get_period(as_str, c.parsing)
	if period == nil then
		print("Couldn't parse date \"" .. as_str .. "\"!")
		return
	end
	files.open_note(period, c)
end

return M
