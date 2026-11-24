@tool
class_name ResourceSpawnEntry
extends Resource

## Satu jenis resource yang boleh muncul di dalam ResourceArea.

@export var definition: ResourceNodeDefinition
## Jumlah yang diminta; hasil bisa lebih sedikit (lihat get_shortfalls()).
@export var count: int = 1
## Hari terakhir node masih respawn (0 = tidak pernah hilang sendiri).
@export var last_respawn_day: int = 0
