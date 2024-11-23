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

	it('get_this_week should have 7 days', function()
		local this_week = fuzzy_time.get_this_week(opts.week_starts)
		assert.not_equal(this_week, nil)
		local this_week_days = {}
		for k, _ in pairs(this_week) do
			table.insert(this_week_days, k)
		end
		assert.same(7, #this_week_days)
	end)

	it('get_this_weekday should be correct date', function()
		local this_sunday = fuzzy_time.get_this_weekday("sunday", opts.week_starts)
		local time = os.time()
		while vim.fn.strftime("%A", time) ~= "Sunday" do
			time = time + (24 * 60 * 60)
		end
		assert.same(
			vim.fn.strftime("%Y-%m-%d", this_sunday),
			vim.fn.strftime("%Y-%m-%d", time)
		)
	end)

	it('Should return correct date for a weekday', function()
		local this_sunday = fuzzy_time.get_date("this sunday", opts)
		local time = os.time()
		while vim.fn.strftime("%A", time) ~= "Sunday" do
			time = time + (24 * 60 * 60)
		end
		assert.same(
			vim.fn.strftime("%Y-%m-%d", this_sunday[1]),
			vim.fn.strftime("%Y-%m-%d", time)
		)
	end)

	it('Should return correct date for a one-day weekday', function()
		local this_sunday = fuzzy_time.get_date("sunday", opts)
		local time = os.time()
		while vim.fn.strftime("%A", time) ~= "Sunday" do
			time = time + (24 * 60 * 60)
		end
		assert.same(
			vim.fn.strftime("%Y-%m-%d", this_sunday[1]),
			vim.fn.strftime("%Y-%m-%d", time)
		)
	end)



	it('Should return correct date for an offset weekday', function()
		local next_sunday = fuzzy_time.get_date("next sunday", opts)
		local time = os.time()
		while vim.fn.strftime("%A", time) ~= "Sunday" do
			time = time + (24 * 60 * 60)
		end
		time = time + (7 * 24 * 60 * 60)
		assert.same(
			vim.fn.strftime("%Y-%m-%d", next_sunday[1]),
			vim.fn.strftime("%Y-%m-%d", time)
		)
	end)
end)
