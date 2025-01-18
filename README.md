# daily-notes.nvim

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

An nvim plugin to enable creating periodic notes for journals and planning.
Inspired by the Obsidian feature of the same name and
[Journal.nvim](https://github.com/jakobkhansen/journal.nvim).

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

`:FuzzyTime` gives a timestamp and period for the given input and can be used
programatically or as a way to do a 'dry run' of `:DailyNote`

## Parsed Date Formats

daily-notes.nvim implements a
[recursive descent parser](https://en.wikipedia.org/wiki/Recursive_descent_parser)
to resolve dates in English into timestamps and create files.

Dates are parsed in the following order:

1. Timestamps
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
[+/-]NUM PERIOD
PERIOD [+/-]NUM
PERIOD -- the same as 'this PERIOD'
this PERIOD
next PERIOD
(last | previous | prev) PERIOD
in [+/-]NUM PERIOD
[+/-]NUM PERIOD ago

-- Ambiguous semantic dates

-- WEEKDAY is ("monday" | "tuesday" | "wednesday" | "thursday" | "friday"
-- | "saturday" | "sunday" ) - and their 3-letter prefixes e.g. "tue"

-- the meaning of this / next / last is determined by config
WEEKDAY
this WEEKDAY
next WEEKDAY
(last | previous | prev) WEEKDAY
-- these always use the current week +/- weeks
[+/-]NUM WEEKDAY
WEEKDAY [+/-]NUM

```

For the details of date parsing
[see the fuzzy time module](./lua/daily-notes/fuzzy-time.lua).

For all timestamp formats [see default config](./lua/daily-notes/config.lua).
Timestamps for weeks are currently not implemented.

## Formatting Date Formats

Currently we just use the default `vim.fn.strftime` function for rendering
filenames and templates, but this may be replaced in the future.
