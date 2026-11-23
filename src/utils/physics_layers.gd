class_name PhysicsLayers
extends RefCounted

## Bit fisik yang dipakai proyek. Tidak mengubah project.godot.
## Bit 0 (nilai 1) = dunia/pemain (layer_0 default). Bit 3 (nilai 8) dipilih
## sebagai layer pagar: bit terendah >= 3 yang belum dipakai siapa pun.
## Mission 9: bit 1 (2) = badan fauna yang memblokir pemain, bit 2 (4) = badan
## pemain. Keduanya bit bebas terendah setelah WORLD dan sebelum FENCE_LAYER.

const WORLD := 1
const FAUNA_BODY := 2
const PLAYER_BODY := 4
const FENCE_LAYER := 8
