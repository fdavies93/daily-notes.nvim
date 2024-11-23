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

local periods = {
	"day",
	"week"
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


local get_single_token_date = function(token, opts)
	local fn
	if relative_days[token] ~= nil then
		fn = relative_days[token]
		return fn()
	end
	return nil
end

local get_relative2 = function(tokens, opts)
	local offset
	if tokens[1] == "this" then
		offset = 0
	elseif tokens[1] == "next" then
		offset = 1
	elseif tokens[1] == "last" then
		offset = -1
	end

	-- weekdays
	for i = 1, #weekdays do

	end
end

local get_two_token_date = function(tokens, opts)
	if tokens[1] == "next" or tokens[1] == "last" or tokens[1] == "this" then
		for i = 1, #periods do
			if periods[i] == tokens[2] then
				return get_relative2(tokens, opts)
			end
		end
	end
end

local get_date = function(input_string, opts)
	local tokens = vim.split(input_string, " ")
	local timestamp_periods = opts.timestamp_formats
	local timestamp = nil
	if #tokens == 1 then
		timestamp = get_single_token_date(tokens[1], opts)
	elseif #tokens == 2 then
		timestamp = get_two_token_date(tokens[2], opts)
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
	get_date = get_date
}
