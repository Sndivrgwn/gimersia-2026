class_name BodyProfileApplier
extends RefCounted

## Mission 10 Phase 4: satu baris di _ready entity memasang profil massa.
## Tidak mengubah API publik body: hanya layer/mask dan meta profil.

const META := &"body_profile"


## apply_layers=false: hanya pasang profil (layer/mask scene tetap dipakai,
## supaya perilaku fisika lama tidak berubah tanpa playtest). True = terapkan
## layer/mask dari profil (dipakai tes matriks).
static func apply(body: Node, profile: BodyProfile, apply_layers: bool = false) -> void:
	if body == null or profile == null or not is_instance_valid(body):
		return
	if apply_layers and body is CharacterBody2D:
		(body as CharacterBody2D).collision_layer = profile.collision_layer
		(body as CharacterBody2D).collision_mask = profile.collision_mask
	body.set_meta(META, profile)


static func profile_of(body: Node) -> BodyProfile:
	if body == null or not is_instance_valid(body):
		return null
	if not body.has_meta(META):
		return null
	return body.get_meta(META) as BodyProfile


## Pengali perpindahan knockback yang diterima body ini.
static func knockback_multiplier(body: Node, fallback: float = 1.0) -> float:
	var profile := profile_of(body)
	return profile.knockback_taken_multiplier if profile != null else fallback
