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

-- TODO: Make this a config option
local timestamp_formats = {
	"%Y-%m-%d",
}

local relative_days = {
	today = function()
		return time_plus_days(0)
	end,
	tomorrow = function()
		return time_plus_days(1)
	end,
	yesterday = function()
		return time_plus_days(-1)
	end,
}

local get_single_token_date = function(token)
	local fn
	if relative_days[token] ~= nil then
		fn = relative_days[token]
		return fn()
	end
	for i = 1, #timestamp_formats do
		local timestamp = vim.fn.strptime(timestamp_formats[i], token)
		if timestamp ~= 0 then
			return timestamp
		end
	end
	return nil
end

local get_date = function(input_string)
	local tokens = vim.split(input_string, " ")
	if #tokens == 1 then
		return get_single_token_date(tokens[1])
	end
	return nil
end

return {
	get_date = get_date
}
