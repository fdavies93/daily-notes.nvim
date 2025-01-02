local M = {}

local config = require("daily-notes.config")
local fuzzy_time = require("daily-notes.fuzzy-time")

M.fuzzy_time = function(opts)
	local as_str = table.concat(opts.fargs, ' ')
	local c = config.get()
	local date = fuzzy_time.get_date(as_str, config.get().parsing)
	if date == nil then
		print("Couldn't parse date \"" .. as_str .. "\"!")
		return
	end
	local timestamp = date[1]
	local time_string = vim.fn.strftime("%Y-%m-%d %H:%M:%S", timestamp)
	print(time_string)
end

return M
