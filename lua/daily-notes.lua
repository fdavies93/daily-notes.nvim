local public = {
	setup = function(opts)
		require("daily-notes.config").setup(opts)
		require("daily-notes.setup").setup(opts)
	end,
}
return public
