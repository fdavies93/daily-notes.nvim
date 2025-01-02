return {
	setup = function(opts)
		vim.api.nvim_create_user_command("Test", 'echo "It works!"', {})
	end
}
