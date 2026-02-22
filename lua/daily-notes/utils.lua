local M = {}

M.merge_table_to_target = function(source, target)
	for key, value in pairs(source) do
		if type(value) == "table" and type(key) ~= "number" then
			M.merge_table_to_target(value, target[key])
		else
			target[key] = value
		end
	end
end

--- @param input_str string
--- @param pattern string
--- @return string[]
M.split = function(input_str, pattern)
	local str_table = {}
	for part in string.gmatch(input_str, pattern) do
		table.insert(str_table, part)
	end
	return str_table
end

return M
