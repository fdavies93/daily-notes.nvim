local M = {}

M.get_timestamp = function(date_string, opts)
	local order = opts.parsing.timestamp_order
	local timestamp_formats = opts.parsing.timestamp_formats
	for i = 1, #order do
		local period = order[i]
		for format_i = 1, #timestamp_formats[period] do
			local format = timestamp_formats[period][format_i]
			-- Might be worth replacing strptime with a less temperamental
			-- alternative later.
			local timestamp = vim.fn.strptime(format, date_string)
			if timestamp ~= 0 then
				-- force full, zero-padded representation of year
				if period == "year" and string.len(date_string) ~= 4 then
					return nil
				end
				local date_table = os.date("*t", timestamp)
				if (period == "month" or period == "year") and date_table.day ~= 1 then
					-- correct strange off-by-one error from strptime
					timestamp = timestamp + (24 * 60 * 60)
					date_table = os.date("*t", timestamp)
				end
				return { str = "", period = { date_table, period } }
			end
		end
	end
	return nil
end

M.get_days_of_week = function(opts)
	local basis = { "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday" }
	local days = {}

	local first_day_i = 1
	-- find index of first day
	for i, day in ipairs(basis) do
		if day == opts.parsing.week_starts then
			first_day_i = i
			break
		end
	end

	local i = 0
	while i < 7 do
		local index = first_day_i + i
		if index > 7 then
			index = index - 7
		end
		local day_name = basis[index]
		table.insert(days, day_name)
		i = i + 1
	end

	return days
end

M.get_day_of_week = function(day_string, opts)
	local days = M.get_days_of_week(opts)

	for i, day_name in ipairs(days) do
		if day_name == day_string then
			return i
		end
	end
	return nil
end

M.get_today = function(opts)
	local date_table = os.date("*t")
	date_table.sec = 0
	date_table.min = 0
	date_table.hour = 0
	return date_table
end

M.get_this_week = function(opts)
	local dt = M.get_today(opts)
	local time = os.time(dt)
	local today_str = string.lower(vim.fn.strftime("%A", time))
	local dow = M.get_day_of_week(today_str, opts)
	dt = M.offset_date(dt, { days = (-dow + 1) })
	return dt
end

M.get_this_month = function(opts)
	local dt = M.get_today(opts)
	dt.day = 1
	return dt
end

M.get_this_year = function(opts)
	local dt = M.get_this_month(opts)
	dt.month = 1
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
		return { str = "", period = { M.get_today(), "day" }, type = "period" }
	end
	return nil
end

M.tomorrow = function(date_string, opts)
	if date_string == "tomorrow" then
		local period = { M.offset_date(
			M.get_today(),
			{ day = 1 }
		), "day" }
		return { str = "", period = period, type = "period" }
	end
	return nil
end

M.yesterday = function(date_string, opts)
	if date_string == "yesterday" then
		local period = { M.offset_date(
			M.get_today(),
			{ day = -1 }
		), "day" }
		return { str = "", period = period, type = "period" }
	end
	return nil
end

-- equivalent to the | 'or' operator in a PEG
M.select = function(sub_functions)
	local closure = function(date_string, opts)
		local token = nil
		for _, fn in ipairs(sub_functions) do
			token = fn(date_string, opts)
			if token ~= nil then
				return token
			end
		end
		return nil
	end
	return closure
end

-- equivalent to the ~ operator in some PEGs; the 'sequence' operator
-- joiner is a function which combines all tokens found into a proper
-- period token - by waiting until the end we can deal with out-of-order
-- expressions like "in 2 weeks"
M.join = function(sub_functions, joiner_fn)
	local closure = function(date_string, opts)
		local token = nil
		local tokens = {}
		local cur_string = date_string
		for _, fn in ipairs(sub_functions) do
			token = fn(cur_string, opts)
			-- part of the expression failed
			if token == nil then
				return nil
			end
			table.insert(tokens, token)
			cur_string = token.str
		end
		return joiner_fn(tokens, opts)
	end
	return closure
end

M.match = function(pattern)
	local closure = function(input, _)
		local s, e = string.find(input, "^" .. pattern)
		if s == nil or e == nil then
			return nil
		end
		return {
			str = string.sub(input, e + 1),
			captured = string.sub(input, s, e),
			type = "match"
		}
	end
	return closure
end

M.get_this_period = function(period, opts)
	local map = {
		day = M.get_today,
		week = M.get_this_week,
		month = M.get_this_month,
		year = M.get_this_year
	}
	return { map[period](opts), period }
end

M.period = function(date_string, opts)
	local parser = M.select({
		M.match("days?%s*"),
		M.match("weeks?%s*"),
		M.match("months?%s*"),
		M.match("years?%s*")
	})
	local token = parser(date_string, opts)
	if token == nil then
		return nil
	end
	local period_str = string.gsub(token.captured, "%s", "")
	if string.sub(period_str, -1) == "s" then
		period_str = string.sub(period_str, 1, string.len(period_str) - 1)
	end
	return { type = "period_no_timestamp", period = period_str, str = token.str }
end

M.single_token_fixed_period = function(date_string, opts)
	local period_no_timestamp = M.period(date_string, opts)
	if period_no_timestamp == nil then
		return nil
	end
	-- We couldn't consume the whole input, which means
	-- it's some other type of period-based string
	if period_no_timestamp.str ~= "" then
		return nil
	end
	return {
		str = "",
		type = "period",
		period = M.get_this_period(period_no_timestamp.period, opts)
	}
end

M.number_offset = function(inverse)
	local closure = function(date_string, opts)
		local joiner = function(tokens)
			local sign = string.gsub(tokens[1].captured, "%s+", "")
			local digits = string.gsub(tokens[2].captured, "%s+", "")
			local offset = tonumber(digits)
			if (sign == "-" and not inverse) or (sign ~= "-" and inverse) then
				offset = -offset
			end
			return { type = "offset", offset = offset, str = tokens[2].str }
		end
		local parser = M.join({
			M.match("[+-]?%s*"),
			M.match("%d+%s*")
		}, joiner)
		local token = parser(date_string, opts)
		return token
	end
	return closure
end

M.join_fixed_period = function(tokens, opts)
	-- otherwise "2 days ago" will be rejected in favor of "2 days"
	if string.len(tokens[#tokens].str) > 0 then
		return nil
	end
	local offset = 0
	local period_str = ""
	for _, token in ipairs(tokens) do
		if token.type == "offset" then
			offset = token.offset
		elseif token.type == "period_no_timestamp" then
			period_str = token.period
		end
	end

	local dt = M.get_this_period(period_str, opts)
	local offset_obj = {}
	local last_str = tokens[#tokens].str
	offset_obj[period_str] = offset

	dt = M.offset_date(dt[1], offset_obj)

	return {
		type = "period",
		period = { dt, period_str },
		str = last_str
	}
end

M.fixed_period_offset = function(date_string, opts)
	local parser = M.select({
		M.join({
			M.number_offset(false),
			M.period
		}, M.join_fixed_period),
		M.join({
			M.period,
			M.number_offset(false)
		}, M.join_fixed_period),
		M.join({
			M.match("in%s*"),
			M.number_offset(false),
			M.period
		}, M.join_fixed_period),
		M.join({
			M.number_offset(true),
			M.period,
			M.match("ago%s*")
		}, M.join_fixed_period)
	})
	local token = parser(date_string, opts)
	return token
end

-- relative_fixed_period := today | tomorrow | yesterday
M.get_relative_fixed_period = function(date_string, opts)
	local parser = M.select({
		M.today,
		M.tomorrow,
		M.yesterday,
		M.single_token_fixed_period,
		M.fixed_period_offset,
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
	local parser = M.select({
		M.get_timestamp,
		M.get_relative_period
	})

	local token = parser(lower, opts)
	if token ~= nil then
		return token.period
	end
end

return M
