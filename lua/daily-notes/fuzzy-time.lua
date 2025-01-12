local M = {}

M.get_timestamp = function(date_string, timestamp_formats, order)
	for i = 1, #order do
		local period = order[i]
		for format_i = 1, #timestamp_formats[period] do
			local format = timestamp_formats[period][format_i]
			-- Might be worth replacing strptime with a less temperamental
			-- alternative later.
			local timestamp = vim.fn.strptime(format, date_string)
			if timestamp ~= 0 then
				local date_table = os.date("*t", timestamp)
				if (period == "month" or period == "year") and date_table.day ~= 1 then
					-- correct strange off-by-one error from strptime
					timestamp = timestamp + (24 * 60 * 60)
					date_table = os.date("*t", timestamp)
				end
				return { date_table, period }
			end
		end
	end
	return nil
end

M.get_today = function()
	local date_table = os.date("*t")
	date_table.sec = 0
	date_table.min = 0
	date_table.hour = 0
	return date_table
end

M.offset_date = function(date, offset)
	local timestamp = os.time(date)

	for _, tag in ipairs({ "second", "minute", "hour", "day", "week", "month", "year" }) do
		if offset[tag] == nil then
			offset[tag] = 0
		end
	end

	timestamp = timestamp + offset.second
	timestamp = timestamp + (offset.minute * 60)
	timestamp = timestamp + (offset.hour * 60 * 60)
	timestamp = timestamp + (offset.day * 24 * 60 * 60)
	timestamp = timestamp + (offset.week * 24 * 60 * 60 * 7)

	local date_table = os.date("*t", timestamp)

	date_table.month = date_table.month + offset.month
	if date_table.month > 12 then
		date_table.month = 1
		date_table.year = date_table.year + 1
	end

	date_table.year = date_table.year + offset.year

	return date_table
end

M.today = function(date_string, opts)
	if date_string == "today" then
		return { M.get_today(), "day" }
	end
	return nil
end

M.tomorrow = function(date_string, opts)
	if date_string == "tomorrow" then
		return { M.offset_date(
			M.get_today(),
			{ day = 1 }
		), "day" }
	end
	return nil
end

M.yesterday = function(date_string, opts)
	if date_string == "yesterday" then
		return { M.offset_date(
			M.get_today(),
			{ day = -1 }
		), "day" }
	end
	return nil
end

-- equivalent to the | operator in something like a PEG
M.select = function(sub_functions)
	local closure = function(date_string, opts)
		local period = nil
		for _, fn in ipairs(sub_functions) do
			period = fn(date_string, opts)
			if period ~= nil then
				return period
			end
		end
		return nil
	end
	return closure
end

-- relative_fixed_period := today | tomorrow | yesterday
M.get_relative_fixed_period = function(date_string, opts)
	local parser = M.select({
		M.today,
		M.tomorrow,
		M.yesterday
	})
	return parser(date_string, opts)
end

M.get_relative_period = function(date_string, opts)
	local parser = M.select({
		M.get_relative_fixed_period
	})
	return parser(date_string, opts)
end

-- A period represents a length of time from its beginning moment,
-- as a lua date table. For example:
-- { { year = 2024, month = 1, day = 1 }, "day" }
M.get_period = function(date_string, opts)
	local lower = string.lower(date_string)

	local period = M.get_timestamp(lower, opts.timestamp_formats, opts.timestamp_order)

	if period ~= nil then
		return period
	end

	period = M.get_relative_period(lower, opts)

	if period ~= nil then
		return period
	end
end

return M
