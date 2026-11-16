@tool
class_name DayNightConfig
extends Resource

## Gameplay configuration for the day/night cycle.
## One cycle always lasts cycle_duration seconds and is split into one day
## phase and one night phase. The split is defined per day range by
## DayNightPeriod resources, so no ratios live in the manager code.

@export_range(1, 365, 1) var max_days: int = 7

## Total length of one full day + night cycle, in seconds.
@export_range(1.0, 3600.0, 1.0, "suffix:s") var cycle_duration: float = 600.0

## Multiplier applied to the gameplay clock only (1.0 = real time).
## Useful for debugging; it does not affect Engine.time_scale.
@export_range(0.01, 100.0, 0.01) var time_scale: float = 1.0

## Ordered list of day ranges. The first period covering a day wins.
@export var periods: Array[DayNightPeriod] = []


func get_period_for_day(day: int) -> DayNightPeriod:
	for period in periods:
		if period != null and period.covers_day(day):
			return period
	return null


func get_day_ratio(day: int) -> float:
	var period := get_period_for_day(day)
	if period == null:
		push_warning("DayNightConfig: no period configured for day %d, falling back to 0.5." % day)
		return 0.5
	return clampf(period.day_ratio, 0.0, 1.0)


func get_day_duration(day: int) -> float:
	return maxf(cycle_duration, 0.0) * get_day_ratio(day)


func get_night_duration(day: int) -> float:
	return maxf(maxf(cycle_duration, 0.0) - get_day_duration(day), 0.0)
