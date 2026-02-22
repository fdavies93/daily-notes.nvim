local datetime = require("daily-notes.datetime")
local utils = require("daily-notes.utils")
local config = require("daily-notes.config")

local M = {}

--- @alias period_str "day" | "week" | "month" | "year"
--- @alias period_no_timestamp_token { str: string, period: period_str , type: "period_no_timestamp" }
--- @alias period_token { str: string, period: period, type: "period" }
--- @alias number_token { str: string, number: integer, type: "number" }
--- @alias offset_token { str: string, offset: integer, type: "offset" }
---
--- @alias token period_no_timestamp_token | period_token | number_token | offset_token

--- @param date_string string
--- @return period_token | nil
M.get_timestamp = function(date_string, opts)
	local order = opts.parsing.timestamp_order
	local timestamp_formats = opts.parsing.timestamp_formats
	for i = 1, #order do
		local period = order[i]
		for format_i = 1, #timestamp_formats[period] do
			local format = timestamp_formats[period][format_i]
			-- Might be worth replacing strptime with a less temperamental
			-- alternative later.
			local timestamp = datetime.strptime(format, date_string, opts)
			if timestamp ~= 0 then
				-- force full, zero-padded representation of year
				if period == "year" and string.len(date_string) ~= 4 then
					return nil
				end
				local date_table = os.date("*t", timestamp)
				-- let awkward dates like Feb 21 be interpreted as days, not months
				if period == "month" and (format == "%B %Y" or format == "%b %Y") and date_table.year <= 31 then
					return nil
				end
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

--- @param date_string string
--- @return period_token | nil
M.today = function(date_string, opts)
	if date_string == "today" then
		return { str = "", period = { datetime.get_today(), "day" }, type = "period" }
	end
	return nil
end

--- @param date_string string
--- @return period_token | nil
M.tomorrow = function(date_string, opts)
	if date_string == "tomorrow" then
		local period = { datetime.offset_date(datetime.get_today(), { day = 1 }), "day" }
		return { str = "", period = period, type = "period" }
	end
	return nil
end

--- @param date_string string
--- @return period_token | nil
M.yesterday = function(date_string, opts)
	if date_string == "yesterday" then
		local period = { datetime.offset_date(datetime.get_today(), { day = -1 }), "day" }
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
			type = "match",
		}
	end
	return closure
end

--- @param date_string string
--- @return period_no_timestamp_token | nil
M.period = function(date_string, opts)
	local parser = M.select({
		M.match("days?%s*"),
		M.match("weeks?%s*"),
		M.match("months?%s*"),
		M.match("years?%s*"),
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

--- @param date_string string
--- @return period_token | nil
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
		period = datetime.get_this_period(period_no_timestamp.period, opts),
	}
end

--- @param date_string string
--- @param opts any
--- @return period_token | nil
M.weekstamp = function(date_string, opts)
	local joiner = function(tokens)
		if string.match(tokens[2].captured, "week%s+") then
			local year_str = string.gsub(tokens[1].captured, "%s", "")
			year_str = string.gsub(year_str, ",", "")
			local year = tonumber(year_str)
			local week_num_str = string.gsub(tokens[3].captured, "%s", "")
			local week_num = tonumber(week_num_str)
			local dt = datetime.get_week_of_year_dt(week_num, year, opts)
			return { type = "period", period = { dt, "week" }, str = tokens[3].str }
		elseif string.match(tokens[1].captured, "week%s+") then
			local year_str = string.gsub(tokens[3].captured, "%s", "")
			local year = tonumber(year_str)
			if year == nil then
				year = tonumber(datetime.get_today(opts).year)
			end
			local week_num_str = string.gsub(tokens[2].captured, "%s", "")
			week_num_str = string.gsub(week_num_str, ",", "")
			local week_num = tonumber(week_num_str)
			local dt = datetime.get_week_of_year_dt(week_num, year, opts)
			return { type = "period", period = { dt, "week" }, str = tokens[3].str }
		end
		return nil
	end

	local parser = M.select({
		-- 2024, week 10
		-- 2024 week 10
		M.join({
			M.match("%d+,?%s+"),
			M.match("week%s+"),
			M.match("%d+%s*"),
		}, joiner),
		-- week 10, 2024
		-- week 10
		-- week 10 2024
		M.join({
			M.match("week%s+"),
			M.match("%d+,?%s*"),
			M.match("%d*%s*"),
		}, joiner),
	})
	local token = parser(date_string, opts)
	return token
end

--- @param min_digits integer
--- @param max_digits integer
--- @return fun(date_string: string, opts: any): number_token
M.number = function(min_digits, max_digits)
	local closure = function(date_string, opts)
		local digit_part = ""
		if max_digits <= 0 then
			digit_part = "%d+"
		else
			for i = 1, max_digits do
				if i <= min_digits then
					digit_part = digit_part .. "%d"
				else
					digit_part = digit_part .. "%d?"
				end
			end
		end
		local matched = M.match(digit_part .. "%s*")(date_string)
		if matched == nil then
			return nil
		end
		local stripped = string.gsub(matched.captured, "%s", "")
		local num = tonumber(stripped)
		return { type = "number", number = num, str = matched.str }
	end
	return closure
end

--- @param inverse boolean
--- @return fun(date_string: string, opts: any): offset_token | nil
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
			M.match("%d+%s*"),
		}, joiner)
		local token = parser(date_string, opts)
		return token
	end
	return closure
end

--- @param date_string string
--- @param opts any
--- @return offset_token | nil
M.word_offset = function(date_string, opts)
	local parser = M.select({
		M.match("next%s*"),
		M.match("last%s*"),
		M.match("previous%s*"),
		M.match("prev%s*"),
		M.match("this%s*"),
	})
	local token = parser(date_string, opts)
	if token == nil then
		return nil
	end
	local stripped = string.gsub(token.captured, "%s+", "")
	local offset_val = 0
	if stripped == "next" then
		offset_val = 1
	end
	if stripped == "last" or stripped == "previous" or stripped == "prev" then
		offset_val = -1
	end
	return { type = "offset", offset = offset_val, str = token.str }
end

--- @return period_token | nil
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

	local dt = datetime.get_this_period(period_str, opts)
	local offset_obj = {}
	local last_str = tokens[#tokens].str
	offset_obj[period_str] = offset

	dt = datetime.offset_date(dt[1], offset_obj)

	return {
		type = "period",
		period = { dt, period_str },
		str = last_str,
	}
end

M.fixed_period_offset = function(date_string, opts)
	local parser = M.select({
		M.join({
			M.number_offset(false),
			M.period,
		}, M.join_fixed_period),
		M.join({
			M.period,
			M.number_offset(false),
		}, M.join_fixed_period),
		M.join({
			M.match("in%s*"),
			M.number_offset(false),
			M.period,
		}, M.join_fixed_period),
		M.join({
			M.number_offset(true),
			M.period,
			M.match("ago%s*"),
		}, M.join_fixed_period),
		M.join({
			M.word_offset,
			M.period,
		}, M.join_fixed_period),
	})
	local token = parser(date_string, opts)
	return token
end

--- @param tokens token[]
--- @param opts { [string]: any }
--- @return period_token | nil
M.join_file_relative_period = function(tokens, opts)
	-- get the current filename (no extensions)
	local file_path = vim.api.nvim_buf_get_name(0)

	-- Impossible to return a valid file-relative date from an empty buffer
	if file_path == "" then
		return nil
	end

	local path_split = utils.split(file_path, "[^/]+")
	-- use for interpreting writable filenames
	local file_name = path_split[#path_split]
	-- use for generic timestamps
	local file_stem = utils.split(file_name, "[^.]+")[1]
	-- parse it - try using write formats first, then timestamp parser
	local writable_timestamps = config.get_writable_timestamps(opts)

	local timestamp = 0
	--- @type period | nil
	local file_period = nil
	local format = ""
	for _, period in ipairs({ "day", "week", "month", "year" }) do
		format = writable_timestamps[period]
		timestamp = datetime.strptime(format, file_stem, opts)
		if timestamp ~= 0 then
			local date = os.date("*t", timestamp) --[[ @as osdate ]]
			if period == "month" or period == "year" then
				-- deal with strptime offset issues
				date = datetime.offset_date(date, { day = 1 })
			end
			file_period = { date, period }
			break
		end
	end
	if timestamp == 0 then
		local period_token = M.get_timestamp(file_stem, opts)
		if period_token == nil then
			return nil
		end
		file_period = period_token.period
	end
	if file_period == nil then
		return nil
	end

	-- Set default behaviour for cases where offset and/or period type are
	-- absent.
	local verb = tokens[1].captured
	--- @type period_str
	local offset_period = file_period[2]
	--- @type integer
	local offset_amount = 1

	if string.gsub(verb, "\\s+", "") == "back" then
		offset_amount = -1
	end
	-- get offset and period token from input str if possible
	for _, token in ipairs(tokens) do
		if token.type == "period_no_timestamp" then
			--- @cast token period_no_timestamp_token
			offset_period = token.period
		elseif token.type == "offset" then
			--- @cast token offset_token
			offset_amount = token.offset
		end
	end
	local offset_compound = {}
	offset_compound[offset_period] = offset_amount
	-- offset it by the appropriate amount
	file_period = {
		datetime.offset_date(file_period[1], offset_compound),
		file_period[2],
	}
	-- return period token
	local period_token = { str = "", period = file_period, type = "period" }
	return period_token
end

M.file_relative_period = function(date_string, opts)
	local parser = M.select({
		M.join({
			M.match("forward%s*"),
			M.number_offset(false),
			M.period,
		}, M.join_file_relative_period),
		M.join({
			M.match("forward%s*"),
			M.period,
		}, M.join_file_relative_period),
		M.join({
			M.match("forward%s*"),
		}, M.join_file_relative_period),
		M.join({
			M.match("back%s*"),
			M.number_offset(true),
			M.period,
		}, M.join_file_relative_period),
		M.join({
			M.match("back%s*"),
			M.period,
		}, M.join_file_relative_period),
		M.join({
			M.match("back%s*"),
		}, M.join_file_relative_period),
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
		M.weekstamp,
		M.single_token_fixed_period,
		M.fixed_period_offset,
		M.file_relative_period,
	})
	return parser(date_string, opts)
end

M.match_weekday = function(date_string, opts)
	local valid_names = {}
	local day_names = datetime.get_days_of_week(opts)
	for _, v in pairs(day_names) do
		table.insert(valid_names, M.match(v .. "%s*"))
		table.insert(valid_names, M.match(string.sub(v, 1, 3) .. "%s*"))
	end
	return M.select(valid_names)(date_string, opts)
end

M.match_month = function(date_string, opts)
	local valid_names = {}
	local month_names = datetime.get_months_of_year(opts)
	for _, v in pairs(month_names) do
		table.insert(valid_names, M.match(v .. "%s"))
		table.insert(valid_names, M.match(string.sub(v, 1, 3) .. "%s*"))
	end
	return M.select(valid_names)(date_string, opts)
end

M.single_token_weekday = function(date_string, opts)
	local mode = opts.parsing.resolve_strategy.weekday.this
	local date = datetime.get_weekday_from_today(date_string, mode, opts)
	if date == nil then
		return nil
	end
	return { type = "period", period = { date, "day" }, str = "" }
end

M.join_weekday_verbal = function(tokens, opts)
	local day_name = tokens[2].captured
	local offset = tokens[1].offset

	local this_dt = datetime.get_weekday_from_today(day_name, opts.parsing.resolve_strategy.weekday.this, opts)
	local period_dt = datetime.get_weekday_from_today(day_name, "period", opts)

	local token = { type = "period", period = { this_dt, "day" }, str = tokens[2].str }

	if offset == 1 then
		local next_mode = opts.parsing.resolve_strategy.weekday.next
		if next_mode == "closest" then
			token.period[1] = datetime.get_weekday_from_today(day_name, "forward", opts)
		elseif next_mode == "adjust_this" then
			token.period[1] = datetime.offset_date(this_dt, { day = 7 })
		elseif next_mode == "period" then
			token.period[1] = datetime.offset_date(period_dt, { day = 7 })
		end
	elseif offset == -1 then
		local prev_mode = opts.parsing.resolve_strategy.weekday.prev
		if prev_mode == "closest" then
			token.period[1] = datetime.get_weekday_from_today(day_name, "back", opts)
		elseif prev_mode == "adjust_this" then
			token.period[1] = datetime.offset_date(this_dt, { day = -7 })
		elseif prev_mode == "period" then
			token.period[1] = datetime.offset_date(period_dt, { day = -7 })
		end
	end
	return token
end

M.join_weekday_numerical = function(tokens, opts)
	local day_name = nil
	for _, token in pairs(tokens) do
		if token.type == "match" then
			day_name = string.gsub(token.captured, "%s", "")
			break
		end
	end
	if day_name == nil then
		return nil
	end
	local offset = 0
	for _, token in pairs(tokens) do
		if token.type == "offset" then
			offset = token.offset * 7
			break
		end
	end
	local this_dt = datetime.get_weekday_from_today(day_name, opts.parsing.resolve_strategy.weekday.this, opts)
	return {
		type = "period",
		period = { datetime.offset_date(this_dt, { day = offset }), "day" },
		str = tokens[2].str,
	}
end

M.weekday_verbal_offset = function(date_string, opts)
	local parser = M.join({
		M.word_offset,
		M.match_weekday,
	}, M.join_weekday_verbal)

	return parser(date_string, opts)
end

M.weekday_number_offset = function(date_string, opts)
	local parser = M.select({
		M.join({ M.number_offset(false), M.match_weekday }, M.join_weekday_numerical),
		M.join({ M.match_weekday, M.number_offset(false) }, M.join_weekday_numerical),
	})
	return parser(date_string, opts)
end

M.join_day_of_month = function(tokens, opts)
	local month_name = nil
	for _, token in pairs(tokens) do
		if token.type == "match" then
			month_name = string.gsub(token.captured, "%s", "")
			break
		end
	end
	if month_name == nil then
		return nil
	end
	local day_num = 0
	for _, token in pairs(tokens) do
		if token.type == "number" then
			day_num = token.number
		end
	end
	if day_num > 31 or day_num < 1 then
		return nil
	end
	local this_dt = datetime.get_month_from_today(month_name, opts.parsing.resolve_strategy.month.this, opts)
	if this_dt == nil then
		return nil
	end
	this_dt.day = day_num
	-- check that this isn't a nonsense date e.g. "Feb 31"
	local normalised = os.date("*t", os.time(this_dt))
	if normalised.day ~= this_dt.day then
		return nil
	end
	return {
		type = "period",
		period = { this_dt, "day" },
		str = tokens[#tokens].str,
	}
end

M.join_month_numerical = function(tokens, opts)
	local month_name = nil
	for _, token in pairs(tokens) do
		if token.type == "match" then
			month_name = string.gsub(token.captured, "%s", "")
			break
		end
	end
	if month_name == nil then
		return nil
	end
	local offset = 0
	for _, token in pairs(tokens) do
		if token.type == "offset" then
			offset = token.offset * 12
			break
		end
	end
	local this_dt = datetime.get_month_from_today(month_name, opts.parsing.resolve_strategy.month.this, opts)
	return {
		type = "period",
		period = { datetime.offset_date(this_dt, { month = offset }), "month" },
		str = tokens[2].str,
	}
end

M.join_month_verbal = function(tokens, opts)
	local month_name = tokens[2].captured
	local offset = tokens[1].offset

	local this_dt = datetime.get_month_from_today(month_name, opts.parsing.resolve_strategy.month.this, opts)
	local period_dt = datetime.get_month_from_today(month_name, "period", opts)

	local token = { type = "period", period = { this_dt, "month" }, str = tokens[2].str }

	if offset == 1 then
		local next_mode = opts.parsing.resolve_strategy.month.next
		if next_mode == "closest" then
			token.period[1] = datetime.get_month_from_today(month_name, "forward", opts)
		elseif next_mode == "adjust_this" then
			token.period[1] = datetime.offset_date(this_dt, { month = 12 })
		elseif next_mode == "period" then
			token.period[1] = datetime.offset_date(period_dt, { month = 12 })
		end
	elseif offset == -1 then
		local prev_mode = opts.parsing.resolve_strategy.month.prev
		if prev_mode == "closest" then
			token.period[1] = datetime.get_month_from_today(month_name, "back", opts)
		elseif prev_mode == "adjust_this" then
			token.period[1] = datetime.offset_date(this_dt, { month = -12 })
		elseif prev_mode == "period" then
			token.period[1] = datetime.offset_date(period_dt, { month = -12 })
		end
	end
	return token
end

M.single_token_month = function(date_string, opts)
	local mode = opts.parsing.resolve_strategy.month.this
	local dt = datetime.get_month_from_today(date_string, mode, opts)
	if dt == nil then
		return nil
	end
	return { type = "period", period = { dt, "month" }, str = "" }
end

M.day_of_month = function(date_string, opts)
	local parser = M.select({
		M.join({ M.number(1, 2), M.match_month }, M.join_day_of_month),
		M.join({ M.match_month, M.number(1, 2) }, M.join_day_of_month),
	})
	return parser(date_string, opts)
end

M.month_verbal_offset = function(date_string, opts)
	local parser = M.join({
		M.word_offset,
		M.match_month,
	}, M.join_month_verbal)
	return parser(date_string, opts)
end

M.month_number_offset = function(date_string, opts)
	local parser = M.select({
		M.join({ M.number_offset(false), M.match_month }, M.join_month_numerical),
		M.join({ M.match_month, M.number_offset(false) }, M.join_month_numerical),
	})
	return parser(date_string, opts)
end

M.get_ambiguous_period = function(date_string, opts)
	local parser = M.select({
		M.single_token_weekday,
		M.weekday_verbal_offset,
		M.weekday_number_offset,
		M.single_token_month,
		M.day_of_month,
		M.month_verbal_offset,
		M.month_number_offset,
	})
	return parser(date_string, opts)
end

M.get_relative_period = function(date_string, opts)
	local parser = M.select({
		M.get_relative_fixed_period,
		M.get_ambiguous_period,
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
		M.get_relative_period,
	})

	local token = parser(lower, opts)
	if token ~= nil then
		return token.period
	end
end
return M
