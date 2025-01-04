# Fuzzy Time

## What is Fuzzy Time?

'Fuzzy time' is a way of describing time that's not directly and unambiguously
translatable to a timestamp. This is the normal way to describe time in English.
For example, if I say 'on Monday' and today is 2024-01-07 (a Tuesday), I could
mean:

- The day before (2024-01-06), as in the sentence: "On Monday I went to the
  store."
- The day after (2024-01-13), as in the sentence: "On Monday I will go to
  school."

This gets worse when we introduce modifiers like 'next', 'this', and 'last',
because it's ambiguous when the week starts.

The `fuzzy-time.lua` module tries to translate dates expressed in normal English
into timestamps which can then be used to create journal entries.

## Grammar Specification

Expressed, roughly, in
[PEG format](https://en.wikipedia.org/wiki/Parsing_expression_grammar).

This grammar aims to be generous rather than accurate: so '2 day ago' and 'this
days` are allowable.

```
date := timestamp | relative_period

-- relative periods need parsing

relative_period :=
"today" |
"yesterday" |
"tomorrow" |
named_period | -- equivalent to "this" ~ named_period
( number ~ period ~ "ago" ) |
( "in" ~ number ~ period ) |
( relative_modifier ~ period ) |
( number ~ named_period ~ "ago" ) |
( "in" ~ number ~ named_period ) |
( relative_modifier ~ named_period ) |
period ~ [+-] ~ number | -- journal.nvim syntax
named_period ~ [+-] ~ number ~ period
relative_modifier ~ named_period ~ [+-] ~ number ~ period

-- named periods contain the most ambiguity and difficult parsing
named_period := weekday | month
relative_modifier := "this" | "next" | "last"
period := "days?" | "weeks?" | "months?" | "years?"
weekday := "monday" | "tuesday" | "wednesday" | "thursday" | "friday" | "saturday" | "sunday"
month := "january" | "february" | "march" | "april" | "may" | "june" | "july" | "august" | "september" | "october" | "november" | "december"

-- timestamps are unambiguous, including years, and should be specified by the user
```

## Parsing Specification

First, timestamp parsing is attempted of the whole string. This will always be
the most efficient method as it's unambiguous. Timestamps can be specified as:

```lua
timestamps = {
    { format = "%Y", period = "year" },
    { format = "%Y-%M", period = "month" },
    { format = "%Y week %a" period = "week" },
    { format = "%Y-%M-%d", period = "day" }
}
```

Next, we attempt to find a match with one of the relative time formats. The
building blocks for this are the _relative modifiers_, the _periods_, the
_weekdays_, and the _months_.

Periods are specified as the amount of time they cover - we try to do this in a
way that's as unambiguous as possible:

```lua
periods = {
    day = { day = 1 },
    week = { day = 7 },
    month = { month = 1 },
    fortnight = { day = 14 },
    quarter = { month = 3 },
    year = { year = 1 }
}
```

Weekdays and months should be provided by the operating system for the sake of
localisation.
