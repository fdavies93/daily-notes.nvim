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
		return vim.fn.strftime("%Y-%m-%d", time_plus_days(0))
	end,
	tomorrow = function()
		return vim.fn.strftime("%Y-%m-%d", time_plus_days(1))
	end,
	yesterday = function()
		return vim.fn.strftime("%Y-%m-%d", time_plus_days(-1))
	end,
}

local get_single_token_date = function(token)
	local fn
	if relative_days[token] ~= nil then
		fn = relative_days[token]
	end
	-- timestamp
	return fn()
end

local get_date = function(input_string)
	local tokens = vim.split(input_string, " ")
	if #tokens == 1 then
		return get_single_token_date(tokens[1])
	end
end

return {
	get_date = get_date
}
