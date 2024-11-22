# daily-notes.nvim

[![License: AGPL v3](https://img.shields.io/badge/License-AGPL_v3-blue.svg)](https://www.gnu.org/licenses/agpl-3.0)

> [!warning]
>
> This plugin isn't ready yet. Don't try to install it with lazy etc.

An nvim plugin to enable creating daily and weekly notes. Inspired by the
Obsidian feature of the same name and
[Journal.nvim](https://github.com/jakobkhansen/journal.nvim).

It _only_ supports this feature, in line with the UNIX philosophy that programs
should try to do one thing and do it well.

## Modules

### fuzzy-time.lua

This resolves strings in plain English into timestamps. It's used to implement
date parsing for creating new notes.
