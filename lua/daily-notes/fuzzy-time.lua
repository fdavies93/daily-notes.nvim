local M = {}

M.get_timestamp = function(date_string, timestamp_formats, order)
	for i = 1, #order do
		local period = order[i]
		for format_i = 1, #timestamp_formats[period] do
			local format = timestamp_formats[period][format_i]
			local timestamp = vim.fn.strptime(format, date_string)
			if timestamp ~= 0 then
				local date_table = os.date("*t", timestamp)
				if (period == "month" or period == "year") and date_table.day ~= 1 then
					-- correct strange off-by-one error from
					-- strptime
					timestamp = timestamp + (24 * 60 * 60)
					date_table = os.date("*t", timestamp)
				end
				return { date_table, period }
			end
		end
	end
	return nil
end

-- A period represents a length of time from its beginning moment,
-- as a lua date table. For example:
-- { { year = 2024, month = 1, day = 1 }, "day" }
M.get_period = function(date_string, opts)
	local period = M.get_timestamp(date_string, opts.timestamp_formats, opts.timestamp_order)
	if period ~= nil then
		return period
	end
end

return M
