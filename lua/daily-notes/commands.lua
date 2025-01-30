local M = {}

local config = require("daily-notes.config")
local fuzzy_time = require("daily-notes.fuzzy-time")
local datetime = require("daily-notes.datetime")
local files = require("daily-notes.files")

M.fuzzy_time = function(opts)
	local as_str = table.concat(opts.fargs, ' ')
	local c = config.get()
	local date = fuzzy_time.get_period(as_str, c)
	if date == nil then
		print("Couldn't parse date \"" .. as_str .. "\"!")
		return
	end
	local timestamp = os.time(date[1]) -- ignore linter error here
	local time_string = os.date("%Y-%m-%d", timestamp)
	local weekday = os.date("%A", timestamp)
	local dow = datetime.get_day_of_week(weekday, c)
	local woy = datetime.get_week_of_year(date[1], c)
	print("Date: " .. time_string)
	print("Period: " .. date[2])
	print("Weekday: " .. weekday .. " (" .. dow .. ")")
	print("Week of year: " .. woy)
end

M.daily_note = function(opts)
	local as_str = table.concat(opts.fargs, ' ')
	local c = config.get()

	if string.len(as_str) == 0 then
		as_str = c.parsing.default
	end
	local period = fuzzy_time.get_period(as_str, c)
	if period == nil then
		print("Couldn't parse date \"" .. as_str .. "\"!")
		return
	end
	files.open_note(period, c)
end

return M
