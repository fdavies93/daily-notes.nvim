# daily-notes.nvim

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

> [!warning]
>
> This plugin isn't ready yet, but it works. At the moment it supports basic
> timestamps and templating; this is so I can begin
> [dogfooding](https://en.wikipedia.org/wiki/Eating_your_own_dog_food) it.
>
> If you want to try it out, clone the repo and use the lazy.nvim instruction
> below to run locally.

An nvim plugin to enable creating daily and weekly notes. Inspired by the
Obsidian feature of the same name and
[Journal.nvim](https://github.com/jakobkhansen/journal.nvim).

It _only_ supports this feature, in line with the UNIX philosophy that programs
should try to do one thing and do it well.

## Installation

### Lazy.nvim

```lua
-- install from local repo
{ dir = "~/daily-notes.nvim", opts = {} }
-- install from github repo
{ "fdavies93/daily-notes.nvim", opts = {} }
```

## Modules

### fuzzy-time.lua

This resolves strings in plain English into UNIX timestamps. It's used to
implement date parsing for creating new notes.
