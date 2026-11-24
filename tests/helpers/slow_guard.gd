class_name SlowGuard
extends RefCounted

## Mission 10 (owner rule): tes berat hanya berjalan dengan GIMERSIA_SLOW=1.
## Pakai di baris pertama tes yang butuh > 15 s:
##   if SlowGuard.skip_unless_slow(self): return
static func skip_unless_slow(test: Node) -> bool:
	if OS.get_environment("GIMERSIA_SLOW") == "1":
		return false
	if test != null and test.has_method(&"pending"):
		test.call(&"pending", "slow-only: jalankan dengan GIMERSIA_SLOW=1")
	return true
