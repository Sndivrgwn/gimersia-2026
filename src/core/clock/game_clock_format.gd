class_name GameClockFormat
extends RefCounted

## Mission 12: fungsi murni jam dunia nyata (tanpa akses scene/waktu nyata).
##
## Pemetaan fase -> jam:
##   DAY   : day_start_hour  -> night_start_hour   (bawaan 06:00 -> 18:00)
##   NIGHT : night_start_hour -> day_start_hour+24 (bawaan 18:00 -> 06:00 besok)
## Kecepatan jarum jam mengikuti panjang fase hari itu, jadi 06:00 dan 18:00
## selalu tepat di batas fase.

const DEFAULT_DAY_START := 6.0
const DEFAULT_NIGHT_START := 18.0


## Jam dinding [0, 24) untuk fase + progress 0..1.
static func hour_of(is_day: bool, progress: float, config: ClockFormatConfig) -> float:
	var day_start := DEFAULT_DAY_START
	var night_start := DEFAULT_NIGHT_START
	if config != null:
		day_start = fposmod(config.day_start_hour, 24.0)
		night_start = fposmod(config.night_start_hour, 24.0)
	var t := clampf(progress, 0.0, 1.0)
	var span := fposmod(night_start - day_start, 24.0)
	if not is_day:
		span = fposmod(day_start - night_start, 24.0)
	if span <= 0.0:
		span = 24.0
	var start := day_start if is_day else night_start
	return fposmod(start + t * span, 24.0)


## Jam dinding (0..24) yang harus ditempuh satu fase penuh.
static func hours_in_phase(is_day: bool, config: ClockFormatConfig) -> float:
	if config == null:
		return 12.0
	return config.day_hours() if is_day else config.night_hours()


## "18:05" (24 jam) atau "06:05 PM" (12 jam). Menit dibulatkan ke bawah ke
## kelipatan `minute_step`.
static func text(hour: float, use_24h: bool, minute_step: int) -> String:
	var step := maxi(minute_step, 1)
	var minutes := int(floor(fposmod(hour, 24.0) * 60.0 + 0.0001))
	minutes -= minutes % step
	var hours := minutes / 60
	var rest := minutes % 60
	if use_24h:
		return "%02d:%02d" % [hours, rest]
	var suffix := "AM" if hours < 12 else "PM"
	var hours12 := hours % 12
	if hours12 == 0:
		hours12 = 12
	return "%02d:%02d %s" % [hours12, rest, suffix]


## Nama periode: periode dengan jam mulai terdekat ke belakang dari `hour`.
## Malam (18) otomatis mencakup 00:00-05:00 karena jaraknya memutar.
static func period_of(hour: float, config: ClockFormatConfig) -> String:
	if config == null or config.period_names.is_empty():
		return ""
	var h := fposmod(hour, 24.0)
	var count := mini(config.period_names.size(), config.period_start_hours.size())
	var best := ""
	var best_distance := 25.0
	for index in count:
		var start := fposmod(config.period_start_hours[index], 24.0)
		var distance := fposmod(h - start, 24.0)
		if distance < best_distance:
			best_distance = distance
			best = config.period_names[index]
	return best


## Selisih jam dari `from_hour` ke `to_hour`, memutar lewat tengah malam.
static func hours_between(from_hour: float, to_hour: float) -> float:
	return fposmod(fposmod(to_hour, 24.0) - fposmod(from_hour, 24.0), 24.0)


## Detik game sampai jam dinding mencapai `target_hour` bila kecepatan fase
## sekarang dipakai terus. Dipakai debug jump; pemanggil mengulang setelah
## batas fase karena fase berikutnya punya kecepatan lain.
static func seconds_until_hour(target_hour: float, is_day: bool, progress: float,
		phase_seconds: float, config: ClockFormatConfig) -> float:
	var phase_len := maxf(phase_seconds, 0.0)
	var phase_hours := hours_in_phase(is_day, config)
	if phase_len <= 0.0 or phase_hours <= 0.0:
		return 0.0
	var current := hour_of(is_day, progress, config)
	var ahead := hours_between(current, target_hour)
	return ahead * (phase_len / phase_hours)


## Awal periode jam berikutnya setelah `current_hour` (Pagi memakai jam
## terbit, bukan label 05:00). Dipakai debug jump.
static func next_period_start_hour(current_hour: float, config: ClockFormatConfig) -> float:
	if config == null:
		return 0.0
	var day_start := fposmod(config.day_start_hour, 24.0)
	var best := day_start
	var best_distance := 25.0
	for start in config.period_start_hours:
		var target := fposmod(start, 24.0)
		if target < day_start:
			target = day_start
		var distance := hours_between(current_hour, target)
		if distance <= 0.001:
			distance = 24.0
		if distance < best_distance:
			best_distance = distance
			best = target
	return best


## Teks toast tidur: "Tidur: 22:10 -> 05:20".
static func sleep_toast_text(from_hour: float, to_hour: float, config: ClockFormatConfig) -> String:
	var use_24h := true if config == null else config.use_24h
	var step := 1 if config == null else config.minute_step
	return "Tidur: %s -> %s" % [text(from_hour, use_24h, step), text(to_hour, use_24h, step)]


## Detik game per satu jam dinding pada fase ini (dipakai tes/kecepatan).
static func seconds_per_hour(is_day: bool, phase_seconds: float, config: ClockFormatConfig) -> float:
	var phase_hours := hours_in_phase(is_day, config)
	if phase_hours <= 0.0:
		return 0.0
	return maxf(phase_seconds, 0.0) / phase_hours
