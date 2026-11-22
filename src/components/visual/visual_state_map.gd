class_name VisualStateMap
extends RefCounted

## Pemetaan state gameplay -> nama state animasi. Semua fungsi murni supaya
## bisa dites tanpa scene.

const PLAYER := "player"
const WILD_BOAR := "wild_boar"
const ISLAND_DEER := "island_deer"


static func player_state(dead: bool, hurt: bool, attacking: bool, moving: bool, sprinting: bool) -> StringName:
	if dead:
		return &"death"
	if hurt:
		return &"hurt"
	if attacking:
		return &"attack"
	if not moving:
		return &"idle"
	return &"sprint" if sprinting else &"walk"


## WildBoar.State: 0 WANDER, 1 CHASE, 2 BITE, 3 DASH_TELEGRAPH, 4 DASH,
## 5 RECOVER, 6 FLEE.
static func boar_state(value: int, moving: bool) -> StringName:
	match value:
		1, 5, 6:
			return &"walk"
		2:
			return &"bite"
		3:
			return &"telegraph"
		4:
			return &"dash"
		_:
			return &"walk" if moving else &"idle"


## IslandDeer.State: 0 WANDER, 1 FLEE.
static func deer_state(value: int, moving: bool) -> StringName:
	match value:
		1:
			return &"flee"
		_:
			return &"walk" if moving else &"idle"


static func fauna_state(key: String, value: int, moving: bool) -> StringName:
	if key == WILD_BOAR:
		return boar_state(value, moving)
	if key == ISLAND_DEER:
		return deer_state(value, moving)
	return &"walk" if moving else &"idle"


static func resource_state(depleted: bool) -> StringName:
	return &"depleted" if depleted else &"full"


static func campfire_state(lit: bool, cold: bool) -> StringName:
	if lit:
		return &"lit"
	return &"cold" if cold else &"ember"


static func chest_state(open: bool) -> StringName:
	return &"open" if open else &"closed"


static func tent_state(sleeping: bool) -> StringName:
	return &"sleeping" if sleeping else &"default"


static func beacon_state(rescue_active: bool) -> StringName:
	return &"active" if rescue_active else &"idle"
