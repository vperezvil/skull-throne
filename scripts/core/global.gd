extends Node

var total_deaths: int = 0

const SETTINGS_PATH := "user://settings.cfg"

const DEBUG := false

var master_volume: float = 1.0
var music_volume: float = 0.85
var sfx_volume: float = 1.0
var ui_text_scale: float = 1.0
var high_contrast_bars: bool = false
var screen_shake_enabled: bool = true

func _ready() -> void:
	_setup_audio_buses()
	_setup_movement_input()
	_load_settings()
	apply_audio_volumes()
	_fanfare_player = AudioStreamPlayer.new()
	_fanfare_player.name = "VictoryFanfare"
	add_child(_fanfare_player)
	assign_sfx_bus(_fanfare_player)

var _fanfare_player: AudioStreamPlayer

func _setup_movement_input() -> void:
	_bind_move_key("move_up", [KEY_W, KEY_UP])
	_bind_move_key("move_down", [KEY_S, KEY_DOWN])
	_bind_move_key("move_left", [KEY_A, KEY_LEFT])
	_bind_move_key("move_right", [KEY_D, KEY_RIGHT])

func _bind_move_key(action: String, keys: Array) -> void:
	if !InputMap.has_action(action):
		InputMap.add_action(action, 0.15)
	for existing in InputMap.action_get_events(action):
		InputMap.action_erase_event(action, existing)
	for keycode in keys:
		var ev := InputEventKey.new()
		ev.keycode = keycode
		ev.physical_keycode = keycode
		InputMap.action_add_event(action, ev)

func increment_death_count() -> void:
	if MetaProgress:
		MetaProgress.add_skull_to_throne()
	else:
		total_deaths += 1

func get_skull_count() -> int:
	if MetaProgress:
		return MetaProgress.get_skull_count()
	return total_deaths

func _setup_audio_buses() -> void:
	if AudioServer.get_bus_count() < 2:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, "Music")
	if AudioServer.get_bus_count() < 3:
		AudioServer.add_bus(2)
		AudioServer.set_bus_name(2, "SFX")
	AudioServer.set_bus_send(1, "Master")
	AudioServer.set_bus_send(2, "Master")

func apply_audio_volumes() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))
	var music_idx := AudioServer.get_bus_index("Music")
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))

func set_master_volume(linear: float) -> void:
	master_volume = clampf(linear, 0.0, 1.0)
	apply_audio_volumes()
	_save_settings()

func set_music_volume(linear: float) -> void:
	music_volume = clampf(linear, 0.0, 1.0)
	apply_audio_volumes()
	_save_settings()

func set_sfx_volume(linear: float) -> void:
	sfx_volume = clampf(linear, 0.0, 1.0)
	apply_audio_volumes()
	_save_settings()

func assign_music_bus(player: AudioStreamPlayer) -> void:
	if player:
		player.bus = "Music"

func assign_sfx_bus(player: AudioStreamPlayer) -> void:
	if player:
		player.bus = "SFX"

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	master_volume = cfg.get_value("audio", "master", master_volume)
	music_volume = cfg.get_value("audio", "music", music_volume)
	sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	ui_text_scale = cfg.get_value("accessibility", "ui_text_scale", ui_text_scale)
	high_contrast_bars = cfg.get_value("accessibility", "high_contrast_bars", high_contrast_bars)
	screen_shake_enabled = cfg.get_value("accessibility", "screen_shake", screen_shake_enabled)
	_load_movement_bindings(cfg)

func _load_movement_bindings(cfg: ConfigFile) -> void:
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		var code := int(cfg.get_value("input", action, 0))
		if code > 0:
			_bind_single_key(action, code as Key)

func _bind_single_key(action: String, keycode: Key) -> void:
	if !InputMap.has_action(action):
		InputMap.add_action(action, 0.15)
	for existing in InputMap.action_get_events(action):
		InputMap.action_erase_event(action, existing)
	var ev := InputEventKey.new()
	ev.keycode = keycode
	ev.physical_keycode = keycode
	InputMap.action_add_event(action, ev)

func save_movement_binding(action: String, keycode: Key) -> void:
	_bind_single_key(action, keycode)
	_save_settings()

func get_ui_font_size(base: int) -> int:
	return int(round(base * ui_text_scale))

func set_ui_text_scale(scale: float) -> void:
	ui_text_scale = clampf(scale, 0.85, 1.35)
	_save_settings()

func set_high_contrast_bars(enabled: bool) -> void:
	high_contrast_bars = enabled
	_save_settings()

func set_screen_shake_enabled(enabled: bool) -> void:
	screen_shake_enabled = enabled
	_save_settings()

func play_skull_fanfare_if_enabled() -> void:
	if _fanfare_player == null:
		return
	var stream: AudioStream = load("res://assets/music/win music 3.wav")
	if stream == null:
		return
	_fanfare_player.stream = stream
	_fanfare_player.volume_db = -4.0
	_fanfare_player.play()

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.set_value("accessibility", "ui_text_scale", ui_text_scale)
	cfg.set_value("accessibility", "high_contrast_bars", high_contrast_bars)
	cfg.set_value("accessibility", "screen_shake", screen_shake_enabled)
	for action in ["move_up", "move_down", "move_left", "move_right"]:
		var events := InputMap.action_get_events(action)
		if events.size() > 0 and events[0] is InputEventKey:
			cfg.set_value("input", action, int((events[0] as InputEventKey).physical_keycode))
	cfg.save(SETTINGS_PATH)
