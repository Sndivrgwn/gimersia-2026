class_name PhysicsLayers
extends RefCounted

## Bit fisik yang dipakai proyek. Tidak mengubah project.godot.
## Bit 0 (nilai 1) = dunia/pemain (layer_0 default). Bit 3 (nilai 8) dipilih
## sebagai layer pagar: bit terendah >= 3 yang belum dipakai siapa pun.

const WORLD := 1
const FENCE_LAYER := 8
