class_name DailyGoalConfig
extends Resource

## Fase 1A: daftar tujuan harian. Diisi `tools/generate_daily_goals.gd`
## (`src/data/configs/daily_goals.tres`), jadi desainer cukup mengubah .tres
## atau generatornya tanpa menyentuh HUD.

@export var goals: Array[DailyGoal] = []


func get_goals_for_day(day: int) -> Array[DailyGoal]:
	var result: Array[DailyGoal] = []
	for goal in goals:
		if goal != null and goal.day == day:
			result.append(goal)
	return result


func get_goal_count() -> int:
	return goals.size()
