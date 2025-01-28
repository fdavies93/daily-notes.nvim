local datetime = require('daily-notes.datetime')
local M = {}

local build_file_path = function(period, opts)
	local p_type = period[2]

	if opts.writing.root == nil or opts.writing.filetype == nil then
		return nil
	end
	if opts.writing[p_type] == nil or opts.writing[p_type].filename == nil then
		return nil
	end

	-- render filename; for now we just use strftime
	-- later we can perhaps use a fancier method from date module
	local timestamp = os.time(period[1])
	local filename = datetime.strftime(opts.writing[p_type].filename, period[1], opts)

	local path = opts.writing.root .. '/' .. filename

	path = path .. '.' .. opts.writing.filetype
	return path
end

local render_template = function(period, opts)
	local p_type = period[2]
	if opts.writing == nil then
		return nil
	end
	if opts.writing[p_type] == nil or opts.writing[p_type].template == nil then
		return nil
	end
	local template = opts.writing[p_type].template
	local lines = {}
	local rendered = {}

	if type(template) == "string" then
		lines = vim.split(template, "\n")
	end

	if type(template) == "table" then
		lines = template
	end

	for i = 1, #lines do
		table.insert(rendered, datetime.strftime(lines[i], period[1], opts))
	end
	return rendered
end

local make_directories = function(path)
	local dirs = vim.fn.split(path, "/")
	local cur_dir = dirs[1]
	for dir_i = 2, #dirs - 1 do
		cur_dir = cur_dir .. '/' .. dirs[dir_i]
		-- We don't care if this succeeds or fails for now
		os.execute("mkdir " .. cur_dir .. " 2> /dev/null")
	end
end

M.file_exists = function(path)
	local exit_code = os.execute("test -f " .. path)
	return exit_code == 0
end

M.open_note = function(period, opts)
	local file_path = build_file_path(period, opts)

	if file_path == nil then
		print("Failed to build file path, exiting...")
	end
	make_directories(file_path)
	vim.cmd('e' .. file_path)

	if M.file_exists(file_path) then
		return
	end

	local template = render_template(period, opts)
	if template ~= nil then
		vim.api.nvim_put(template, "", false, false)
	end
	if opts.writing.write_on_open then
		vim.cmd('w')
	end
end

return M
