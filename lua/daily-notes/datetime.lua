local M = {}

-- returns a date table or nil
-- modes:
-- forward / back / closest / period
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

	if mode == "forward" or (mode == "closest" and math.abs(forward_offset) < math.abs(backward_offset)) then
		offset = forward_offset
	elseif mode == "back" or (mode == "closest" and math.abs(backward_offset) < math.abs(forward_offset)) then
		offset = backward_offset
	elseif mode ~= "period" then
		return nil
	end

	return M.offset_date(today_dt, { day = offset })
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
		date_table.month = (date_table.month % 12)
		date_table.year = date_table.year + 1
	end

	date_table.year = date_table.year + offset.year

	return date_table
end

M.get_days_of_week = function(opts)
	-- this algorithm doesn't require assumptions about what the basis order
	-- actually is, so we can generate the day names pretty independently
	local basis = {}

	local cur_time = os.time()
	for _ = 0, 6 do
		table.insert(basis, string.lower(os.date("%A", cur_time)))
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

M.get_day_of_week = function(day_string, opts)
	local days = M.get_days_of_week(opts)

	for i, day_name in ipairs(days) do
		if day_name == day_string or string.sub(day_name, 1, 3) == day_string then
			return i
		end
	end
	return nil
end

M.get_week_of_year = function(dt, opts)
	local jan_1 = { year = dt.year, month = 1, day = 1 }
	local dow_jan_1 = M.get_day_of_week(os.date("%A"), opts)
	local week_basis = M.offset_date(jan_1, { day = (1 - dow_jan_1) })
	local basis_ts = os.time(week_basis)
	local ts = os.time(dt)
	local diff_in_weeks = (ts - basis_ts) / (60 * 60 * 24 * 7)
	-- if we wanted to start from 0 (and end at 52) we'd use floor
	return math.ceil(diff_in_weeks)
end

M.get_this_week = function(opts)
	local dt = M.get_today(opts)
	local time = os.time(dt)
	local today_str = string.lower(vim.fn.strftime("%A", time))
	local dow = M.get_day_of_week(today_str, opts)
	dt = M.offset_date(dt, { day = (-dow + 1) })
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
	return dt
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

M.get_months_of_year = function(opts)
	local months = {}
	local dt = { day = 1, month = 1, year = 2000 }
	for _ = 0, 11 do
		local time = os.time(dt)
		table.insert(months, string.lower(os.date("%B", time)))
		dt.month = dt.month + 1
	end
	return months
end

M.get_month_of_year = function(month_string, opts)
	local months = M.get_months_of_year(opts)
	for i, month in ipairs(months) do
		if string.lower(month_string) == month then
			return i
		end
	end
	return nil
end



M.get_today_name = function(opts)
	local dt = M.get_today(opts)
	local time = os.time(dt)
	return string.lower(vim.fn.strftime("%A", time))
end

M.get_today = function(opts)
	local date_table = os.date("*t")
	date_table.sec = 0
	date_table.min = 0
	date_table.hour = 0
	return date_table
end



return M
