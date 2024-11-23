require("daily-notes").setup()
local fuzzy_time = require("daily-notes.fuzzy-time")

describe('Fuzzy Time', function()
	it('Should return the correct date for today', function()
		assert.equals(
			fuzzy_time.get_date("today"),
			os.time()
		)
	end)
	it('Should return the correct date for tomorrow', function()
		assert.equals(
			fuzzy_time.get_date("tomorrow"),
			os.time() + (24 * 60 * 60)
		)
	end)
	it('Should return the correct date for yesterday', function()
		assert.equals(
			fuzzy_time.get_date("yesterday"),
			os.time() - (24 * 60 * 60)
		)
	end)
	it('Should return the correct date from timestamp', function()
		assert.equals(
			fuzzy_time.get_date("2024-10-01"),
			vim.fn.strptime("%Y-%m-%d", "2024-10-01")
		)
	end)
end)
