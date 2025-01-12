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

return M
