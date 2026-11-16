@tool
class_name DayNightVisualConfig
extends Resource

## Visual configuration for the day/night cycle.
##
## Gameplay only has DAY and NIGHT phases. These four entries describe the
## visual keyframes used while those phases change:
##   NIGHT -> MORNING -> DAY   (dawn, spread over transition_duration)
##   DAY   -> EVENING -> NIGHT (dusk, spread over transition_duration)
##
## Light intensity is folded into the CanvasModulate tint, so there is a single
## authority writing the world color. This works with the project's 2D GL
## Compatibility renderer, which has no 3D lighting pipeline.

enum Atmosphere { MORNING, DAY, EVENING, NIGHT }

@export_group("Transition")

## How long the world tint takes to blend through a full dawn/dusk sequence.
@export_range(0.0, 120.0, 0.5, "suffix:s") var transition_duration: float = 30.0

@export_group("Atmosphere Colors")

@export var morning_color: Color = Color(0.95, 0.8, 0.68, 1.0)
@export var day_color: Color = Color(1.0, 0.96, 0.88, 1.0)
@export var evening_color: Color = Color(1.0, 0.68, 0.45, 1.0)
@export var night_color: Color = Color(0.34, 0.42, 0.66, 1.0)

@export_group("Light Intensity")

## Multipliers applied on top of the atmosphere colors above.
@export_range(0.0, 2.0, 0.01) var morning_light_intensity: float = 0.82
@export_range(0.0, 2.0, 0.01) var day_light_intensity: float = 1.0
@export_range(0.0, 2.0, 0.01) var evening_light_intensity: float = 0.75
@export_range(0.0, 2.0, 0.01) var night_light_intensity: float = 0.62

@export_group("Environment Effects")

## Global switch for every optional particle effect.
@export var enable_environment_effects: bool = true

@export var enable_fireflies: bool = true
@export_range(0, 128, 1) var firefly_amount: int = 24
@export var firefly_color: Color = Color(0.85, 1.0, 0.6, 1.0)

@export var enable_day_motes: bool = true
@export_range(0, 128, 1) var day_mote_amount: int = 12
@export var day_mote_color: Color = Color(1.0, 0.95, 0.82, 0.55)


func get_color_for_atmosphere(atmosphere: int) -> Color:
	match atmosphere:
		Atmosphere.MORNING:
			return morning_color
		Atmosphere.EVENING:
			return evening_color
		Atmosphere.NIGHT:
			return night_color
		_:
			return day_color


func get_light_intensity_for_atmosphere(atmosphere: int) -> float:
	match atmosphere:
		Atmosphere.MORNING:
			return morning_light_intensity
		Atmosphere.EVENING:
			return evening_light_intensity
		Atmosphere.NIGHT:
			return night_light_intensity
		_:
			return day_light_intensity


## Color after the atmosphere's light intensity has been applied.
func get_effective_color(atmosphere: int) -> Color:
	var base := get_color_for_atmosphere(atmosphere)
	var intensity := maxf(get_light_intensity_for_atmosphere(atmosphere), 0.0)
	return Color(base.r * intensity, base.g * intensity, base.b * intensity, 1.0)


## Kept for callers that only know the gameplay phase.
func get_color_for_phase(is_night: bool) -> Color:
	return get_effective_color(Atmosphere.NIGHT if is_night else Atmosphere.DAY)


func get_transition_duration() -> float:
	return maxf(transition_duration, 0.0)
