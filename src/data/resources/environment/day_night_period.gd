@tool
class_name DayNightPeriod
extends Resource

## A contiguous range of in-game days that share the same day/night ratio.
## Used by DayNightConfig to derive phase durations without hardcoding them
## inside the day/night manager.

@export_range(1, 365, 1) var first_day: int = 1
@export_range(1, 365, 1) var last_day: int = 3

## Portion of the full cycle spent in daylight (0.0 = all night, 1.0 = all day).
@export_range(0.0, 1.0, 0.01) var day_ratio: float = 0.5

func covers_day(day: int) -> bool:
	return day >= first_day and day <= last_day
