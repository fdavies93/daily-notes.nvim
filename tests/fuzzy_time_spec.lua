require("daily-notes").setup()
local fuzzy_time = require("daily-notes.fuzzy-time")
local opts = {
	timestamp_formats = {
		day = {
			"%Y-%m-%d",
			"%A, %B %d %Y"
		},
		week = {
			"%Y Week %W"
		}
	},
	week_starts = "monday",
}

describe('Fuzzy Time:', function()
	it('Should return the correct date for today', function()
		assert.same(
			fuzzy_time.get_date("today", opts),
			{
				os.time(),
				"day"
			}
		)
	end)
	it('Should return the correct date for tomorrow', function()
		assert.same(
			fuzzy_time.get_date("tomorrow", opts),
			{
				os.time() + (24 * 60 * 60),
				"day"
			}
		)
	end)
	it('Should return the correct date for yesterday', function()
		assert.same(
			fuzzy_time.get_date("yesterday", opts),
			{
				os.time() - (24 * 60 * 60),
				"day"
			}
		)
	end)
	it('Should return the correct date from timestamp', function()
		assert.same(
			fuzzy_time.get_date("2024-10-01", opts),
			{
				vim.fn.strptime("%Y-%m-%d", "2024-10-01"),
				"day"
			}
		)
	end)
	it('Should return the correct date from multi-word timestamp', function()
		assert.same(
			fuzzy_time.get_date("Friday, November 01 2024", opts),
			{
				vim.fn.strptime("%A, %B %d %Y", "Friday, November 01 2024"),
				"day"
			}
		)
	end)
	it('Should return a week type from a week format', function()
		assert.same(
			fuzzy_time.get_date("2024 Week 24", opts),
			{
				vim.fn.strptime("%Y Week %W", "2024 Week 24"),
				"week"
			}
		)
	end)

	it('Should return nil from incorrect timestamp', function()
		assert.same(
			fuzzy_time.get_date("2024/10/01", opts),
			nil
		)
	end)
end)
