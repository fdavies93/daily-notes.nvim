local M = {}

--- @alias relative_date_mode "forward" | "back" | "closest" | "period"
--- @alias date_offset { year: integer | nil, month: integer | nil, week: integer | nil, day: integer | nil, hour: integer | nil, minute: integer | nil, second: integer | nil }
--- @alias period [ osdate, "day" | "week" | "month" | "year" ]

--- @param day_str string
--- @param mode relative_date_mode
--- @return nil | osdate
M.get_weekday_from_today = function(day_str, mode, opts)
	local dow = M.get_day_of_week(day_str, opts)
	if dow == nil then
		return nil
	end
	local today_dow = M.get_day_of_week(M.get_today_name(opts), opts)
	local today_dt = M.get_today(opts)
	local offset = dow - today_dow
	local forward_offset = 0
	local backward_offset = 0

	if offset > 0 then
		forward_offset = offset
		backward_offset = offset - 7
	elseif offset < 0 then
		forward_offset = offset + 7
		backward_offset = offset
	end
	if forward_offset == 0 then
		return today_dt
	elseif mode == "forward" or (mode == "closest" and math.abs(forward_offset) < math.abs(backward_offset)) then
		offset = forward_offset
	elseif mode == "back" or (mode == "closest" and math.abs(backward_offset) < math.abs(forward_offset)) then
		offset = backward_offset
	elseif mode ~= "period" then
		return nil
	end

	return M.offset_date(today_dt, { day = offset })
end

--- @param month_str string
--- @param mode relative_date_mode
--- @return nil | osdate
M.get_month_from_today = function(month_str, mode, opts)
	local month_num = M.get_month_of_year(month_str, opts)
	if (month_num == nil) then
		return nil
	end
	local today = M.get_today(opts)
	local forward_distance = month_num - today.month
	if forward_distance < 0 then
		forward_distance = forward_distance + 12
	end
	local backward_distance = today.month - month_num
	if backward_distance < 0 then
		backward_distance = backward_distance + 12
	end
	local this_month = M.get_this_month(opts)
	-- will always clamp to the closest inside this year
	local offset = month_num - today.month
	if forward_distance == 0 then
		return this_month
	elseif mode == "forward" or (mode == "closest" and forward_distance < backward_distance) then
		offset = forward_distance
	elseif mode == "back" or (mode == "closest" and backward_distance < forward_distance) then
		offset = -backward_distance
	elseif mode ~= "period" then
		return nil
	end
	return M.offset_date(this_month, { month = offset })
end

---@param date osdate
---@param offset date_offset
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
	local date_table = os.date("*t", timestamp) --[[@as osdate]]

	date_table.month = date_table.month + offset.month
	local cur_month = date_table.month

	while cur_month > 12 do
		cur_month = cur_month - 12
		date_table.year = date_table.year + 1
	end

	date_table.month = cur_month

	date_table.year = date_table.year + offset.year
	return date_table
end

--- @return string[]
M.get_days_of_week = function(opts)
	-- this algorithm doesn't require assumptions about what the basis order
	-- actually is, so we can generate the day names pretty independently
	local basis = {}

	local cur_time = os.time()
	for _ = 0, 6 do
		table.insert(basis, string.lower(os.date("%A", cur_time) --[[@as string]]))
		cur_time = cur_time + (24 * 60 * 60)
	end

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

--- @param day_string string
--- @return integer | nil
M.get_day_of_week = function(day_string, opts)
	local ds = string.lower(day_string)
	local days = M.get_days_of_week(opts)

	for i, day_name in ipairs(days) do
		if day_name == ds or string.sub(day_name, 1, 3) == ds then
			return i
		end
	end
	return nil
end

--- @param week_no integer
--- @param year_no integer
--- @return osdate
M.get_week_of_year_dt = function(week_no, year_no, opts)
	local jan_1 = { day = 1, month = 1, year = year_no, hour = 0, minute = 0, second = 0 }
	local jan_1_ts = os.time(jan_1)
	local jan_1_weekday = os.date("%A", jan_1_ts) --[[@as string]]
	local jan_1_weekday_no = M.get_day_of_week(jan_1_weekday, opts)
	local week_start_dt = M.offset_date(jan_1, { day = (1 - jan_1_weekday_no), week = week_no })
	return week_start_dt
end

--- @param dt osdate
--- @return integer
M.get_week_of_year = function(dt, opts)
	local jan_1 = { year = dt.year, month = 1, day = 1, hour = 0, minute = 0, second = 0 }
	local ts_jan_1 = os.time(jan_1)
	local dow_jan_1 = M.get_day_of_week(os.date("%A", ts_jan_1) --[[@as string]], opts)
	local week_basis = M.offset_date(jan_1, { day = (1 - dow_jan_1) })
	local basis_ts = os.time(week_basis)
	local ts = os.time(dt)
	local dow_1st = M.get_day_of_week(os.date("%A", ts) --[[@as string]], opts)
	local ts_adjusted = os.time(M.offset_date(dt, { day = (1 - dow_1st) }))
	local diff_in_weeks = (ts_adjusted - basis_ts) / (60.0 * 60.0 * 24.0 * 7.0)
	-- if we wanted to start from 0 (and end at 52), don't add 1
	return math.ceil(diff_in_weeks)
end

--- @return osdate
M.get_this_week = function(opts)
	local dt = M.get_today(opts)
	local time = os.time(dt)
	local today_str = string.lower(vim.fn.strftime("%A", time))
	local dow = M.get_day_of_week(today_str, opts)
	dt = M.offset_date(dt, { day = (1 - dow) })
	return dt
end


--- @return osdate
M.get_this_month = function(opts)
	local dt = M.get_today(opts)
	dt.day = 1
	return dt
end

--- @return osdate
M.get_this_year = function(opts)
	local dt = M.get_this_month(opts)
	dt.month = 1
	return dt
end

--- @param period_string "day" | "week" | "month" | "year"
--- @return period
M.get_this_period = function(period_string, opts)
	local map = {
		day = M.get_today,
		week = M.get_this_week,
		month = M.get_this_month,
		year = M.get_this_year
	}
	return { map[period_string](opts), period_string }
end

--- @return string[]
M.get_months_of_year = function(opts)
	local months = {}
	local dt = { day = 1, month = 1, year = 2000 }
	for _ = 0, 11 do
		local time = os.time(dt)
		table.insert(months, string.lower(os.date("%B", time) --[[@as string]]))
		dt.month = dt.month + 1
	end
	return months
end

--- @param month_string string
--- @return integer | nil
M.get_month_of_year = function(month_string, opts)
	local months = M.get_months_of_year(opts)
	for i, month in ipairs(months) do
		local month_short = string.sub(month, 1, 3)
		if string.lower(month_string) == month or string.lower(month_string) == month_short then
			return i
		end
	end
	return nil
end

--- @return string
M.get_today_name = function(opts)
	local dt = M.get_today(opts)
	local time = os.time(dt)
	return string.lower(vim.fn.strftime("%A", time))
end

--- @return osdate
M.get_today = function(opts)
	local date_table = os.date("*t")
	date_table.sec = 0
	date_table.min = 0
	date_table.hour = 0
	return date_table --[[@as osdate]]
end

--- @param format string
--- @param dt osdate
--- @return string
M.strftime = function(format, dt, opts)
	local week_of_year = M.get_week_of_year(dt, opts)
	local timestamp = os.time(dt)
	local day_str = os.date("%A", timestamp) --[[@as string]]
	local day_of_week = M.get_day_of_week(day_str, opts)
	local working_string = string.gsub(format, "%%W", string.format("%02d", week_of_year))
	working_string = string.gsub(working_string, "%%w", string.format("%d", day_of_week))
	working_string = os.date(working_string, timestamp) --[[@as string]]
	return working_string
end

return M
