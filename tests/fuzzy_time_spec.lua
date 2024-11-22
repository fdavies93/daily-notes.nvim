require("daily-notes").setup()
local fuzzy_time = require("daily-notes.fuzzy-time")

describe('Fuzzy Time', function()
	it('Should return the correct date for today', function()
		assert.equals(
			fuzzy_time.get_date("today"),
			vim.fn.strftime("%Y-%m-%d")
		)
	end)
	it('Should return the correct date for tomorrow', function()
		assert.equals(
			fuzzy_time.get_date("tomorrow"),
			vim.fn.strftime(
				"%Y-%m-%d", os.time() + (24 * 60 * 60)
			)
		)
	end)
	it('Should return the correct date for yesterday', function()
		assert.equals(
			fuzzy_time.get_date("yesterday"),
			vim.fn.strftime(
				"%Y-%m-%d", os.time() - (24 * 60 * 60)
			)
		)
	end)
end)
