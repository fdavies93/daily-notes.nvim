local time_plus_days = function(offset)
	return os.time() + (offset * 24 * 60 * 60)
end

local weekdays = {
	"monday",
	"tuesday",
	"wednesday",
	"thursday",
	"friday",
	"saturday",
	"sunday"
}

local relative_days = {
	today = function()
		return { time_plus_days(0), "day" }
	end,
	tomorrow = function()
		return { time_plus_days(1), "day" }
	end,
	yesterday = function()
		return { time_plus_days(-1), "day" }
	end,
}

local get_day_name = function(time)
	return string.lower(vim.fn.strftime("%A", time))
end

local get_this_week = function(week_starts)
	if week_starts == nil then
		return nil -- prevent infinite loop
	end
	local week = {}
	-- add until previous start of week (inclusive)
	local offset = 0
	local time = time_plus_days(offset)
	local day_name = get_day_name(time)
	week[day_name] = time

	while day_name ~= week_starts do
		offset = offset - 1
		time = time_plus_days(offset)
		day_name = get_day_name(time)
		week[day_name] = time
	end
	-- add until next start of week (exclusive)
	offset = 1
	time = time_plus_days(offset)
	day_name = get_day_name(time)

	while day_name ~= week_starts do
		week[day_name] = time
		offset = offset + 1
		time = time_plus_days(offset)
		day_name = get_day_name(time)
	end

	return week
end

local get_this_weekday = function(weekday, week_starts)
	return get_this_week(week_starts)[weekday]
end

local get_relative2 = function(tokens, opts)
	-- periodic dates
	local offset
	if tokens[1] == "next" then
		offset = 1
	elseif tokens[1] == "last" then
		offset = -1
	elseif tokens[1] == "this" then
		offset = 0
	else
		return nil
	end
	local second_is_weekday = false
	for i = 1, #weekdays do
		if tokens[2] == weekdays[i] then
			second_is_weekday = true
			break
		end
	end
	if not second_is_weekday then
		return nil
	end
	local this_weekday = get_this_weekday(tokens[2], opts.week_starts)
	this_weekday = this_weekday + (offset * 7 * 24 * 60 * 60)
	return { this_weekday, "day" }
end

local get_single_token_date = function(token, opts)
	local fn
	if relative_days[token] ~= nil then
		fn = relative_days[token]
		return fn()
	end
	for i = 1, #weekdays do
		if weekdays[i] == token then
			-- could be a configuration option, but probably
			-- not that useful
			return get_relative2({ "this", token }, opts)
		end
	end
	return nil
end


local get_two_token_date = function(tokens, opts)
	if tokens[1] == "next" or tokens[1] == "last" or tokens[1] == "this" then
		return get_relative2(tokens, opts)
	end
end

local get_date = function(input_string, opts)
	local lower = string.lower(input_string)
	local tokens = vim.split(lower, " ")
	local timestamp_periods = opts.timestamp_formats
	local timestamp = nil
	if #tokens == 1 then
		timestamp = get_single_token_date(tokens[1], opts)
	elseif #tokens == 2 then
		timestamp = get_two_token_date(tokens, opts)
	end

	if timestamp ~= nil then
		return timestamp
	end

	-- we use the whole string to allow for multi-word date formats
	for period, formats in pairs(timestamp_periods) do
		for format = 1, #formats do
			timestamp = vim.fn.strptime(timestamp_periods[period][format], input_string)
			if timestamp ~= 0 then
				return { timestamp, period }
			end
		end
	end
	return nil
end

return {
	get_date = get_date,
	get_this_week = get_this_week,
	get_this_weekday = get_this_weekday
}
