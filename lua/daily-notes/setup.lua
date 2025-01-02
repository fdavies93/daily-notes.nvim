local commands = require("daily-notes.commands")

return {
	setup = function(opts)
		vim.api.nvim_create_user_command("FuzzyTime", commands.fuzzy_time, { nargs = "+" })
	end
}
