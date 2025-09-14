<!-- prettier-ignore -->
> [!IMPORTANT]
> The canonical repository for this project is [on Codeberg](https://codeberg.org/fd93/daily-notes.nvim).
> Please file any issues at that URL.

# daily-notes.nvim

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

An nvim plugin to enable creating periodic notes for journals and planning.
Inspired by the Obsidian feature of the same name and
[Journal.nvim](https://github.com/jakobkhansen/journal.nvim).

I use this as part of my personal
[Zettelkasten](https://zettelkasten.de/introduction/).

## Installation

### Lazy.nvim

```lua
-- install from local repo
-- this is just an example; you can just as well use empty opts {}
{
    dir = "~/daily-notes.nvim",
    opts = {
        writing = {
            root = "~/zettelkasten/daily-notes"
        }
    }
}
-- install from github repo
{ "fdavies93/daily-notes.nvim", opts = {} }
```

Note that this plugin is only tested on my personal Arch Linux for now. It
_should_ work on other UNIX systems (i.e. WSL, MacOS, BSD), but this isn't
guaranteed. Windows probably won't work due to differences in file and date
handling.

## Configuration

The most important option is `writing.root`. This controls where
daily-notes.nvim tries to put new notes and open existing notes. This should
integrate with existing setups if you set the `writing.day` and other options to
match your current filename formats.

It's also worth setting `writing.day.template` to your preferred format for that
type of note, e.g:

```lua
{
    writing = {
        day = {
            template = "# %A, %B %d %Y\n\n## Notes\n\n## Tasks\n\n## Timebox"
        }
    }
}
```

If your locale is not English you will need to set `parsing.week_starts` to be a
string in your locale's language. This is because locale strings are used
internally for parsing to avoid mixing calls to `os.time` with baked-in strings.

If you prefer weekly notes to daily ones, you can change `parsing.default` to be
`this week`.

For a full list of config options,
[see the default config here](./lua/daily-notes/config.lua).

## Usage

Setup your configuration so the directories and templates follow your preferred
date format.

```vim
:DailyNote day +1
:DailyNote next week
:DailyNote tuesday
:FuzzyTime 2025
```

daily-notes.nvim exports `:DailyNote` and `:FuzzyTime` user commands.

`:DailyNote` creates a new note or opens a note if one already exists.

`:FuzzyTime` gives time information for the given input and can be used as a way
to do a 'dry run' of `:DailyNote` or to play with the date parser.

## Parsed Date Formats

daily-notes.nvim implements a
[recursive descent parser](https://en.wikipedia.org/wiki/Recursive_descent_parser)
to resolve dates in English into timestamps and create files.

Dates are parsed in the following order:

1. [Timestamps](./lua/daily-notes/config.lua)
2. Unambiguous semantic dates (e.g. 'today')
3. Ambiguous semantic dates (e.g. 'this Tuesday')

The different algorithms for resolving ambiguous dates can be selected in the
config at `parsing.resolve_strategy`.

```
-- PERIOD is ("day" | "week" | "month" | "year") ~ "s"?

-- Unambiguous semantic dates
today
tomorrow
yesterday
YEAR[,] week NUM
-- if year isn't defined, we just use the current year
week NUM[,] [YEAR]
[+/-]NUM PERIOD
PERIOD [+/-]NUM
PERIOD -- the same as 'this PERIOD'
this PERIOD
next PERIOD
(last | previous | prev) PERIOD
in [+/-]NUM PERIOD
[+/-]NUM PERIOD ago

-- Ambiguous semantic dates

-- WEEKDAY is generated from the locale names for the weekdays, e.g. "tuesday"
-- and their 3-letter prefixes e.g. "tue"

-- the meaning of this / next / last is determined by config
WEEKDAY
this WEEKDAY
next WEEKDAY
(last | previous | prev) WEEKDAY
-- these always use the current week +/- weeks
[+/-]NUM WEEKDAY
WEEKDAY [+/-]NUM

-- MONTH is generated from the locale names for the months, e.g. "january"
-- and their 3-letter prefixes e.g. "jan"

-- the meaning of this / next / last is determined by config
MONTH
this MONTH
next MONTH
(last | previous | prev) MONTH
DAY MONTH
MONTH DAY
[+/-]NUM MONTH
MONTH [+/-]NUM
```

For the details of date parsing
[see the fuzzy time module](./lua/daily-notes/fuzzy-time.lua).

For all timestamp formats [see default config](./lua/daily-notes/config.lua).

## Formatting Date Formats

We use the default strftime for rendering dates, but `%W` (week number) and `%w`
(numerical day of week) are replaced by bespoke logic so that alternate week
starts are possible.

## Plugins that work well with this

I prefer plugins that do one job, rather than all-in-one tools.

- [telescope-file-browser](https://github.com/nvim-telescope/telescope-file-browser.nvim)
- [zen-mode](https://github.com/folke/zen-mode.nvim)
- [render-markdown](https://github.com/MeanderingProgrammer/render-markdown.nvim)
