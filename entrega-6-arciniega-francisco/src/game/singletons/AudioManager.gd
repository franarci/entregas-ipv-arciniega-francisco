extends Node

const UI_SOUNDS: Array[AudioStream] = [
	preload("res://assets/sound/UI/Minimalist1.ogg"),
	preload("res://assets/sound/UI/Minimalist2.ogg"),
	preload("res://assets/sound/UI/Minimalist3.ogg"),
	preload("res://assets/sound/UI/Minimalist4.ogg"),
	preload("res://assets/sound/UI/Minimalist5.ogg"),
	preload("res://assets/sound/UI/Minimalist6.ogg"),
	preload("res://assets/sound/UI/Minimalist7.ogg"),
	preload("res://assets/sound/UI/Minimalist8.ogg"),
	preload("res://assets/sound/UI/Minimalist9.ogg"),
	preload("res://assets/sound/UI/Minimalist10.ogg"),
	preload("res://assets/sound/UI/Minimalist11.ogg"),
	preload("res://assets/sound/UI/Minimalist12.ogg"),
	preload("res://assets/sound/UI/Minimalist13.ogg"),
]

const AUDIO_BUSES: Array[StringName] = [&"Master", &"Music", &"SFX", &"UI", &"Ambience"]
const SETTINGS_PATH: String = "user://audio_settings.cfg"
const END_MUSIC_PATH: String = "res://assets/sound/bgm/gameOver.ogg"
const DESERT_AMBIENCE_PATH: String = "res://assets/sound/textures/desert-ambient.wav"

var _volume_settings: Dictionary = {}
var _combat_sources: Dictionary[int, bool] = {}
var _combat_active: bool = false
var _music_tween: Tween
var _music_a: AudioStreamPlayer
var _music_b: AudioStreamPlayer
var _ending_music: AudioStreamPlayer
var _ambience: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _save_timer: Timer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music_a = _make_player("MusicA", &"Music")
	_music_b = _make_player("MusicB", &"Music")
	_ending_music = _make_player("EndingMusic", &"Music")
	_ambience = _make_player("WorldAmbience", &"Ambience")
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = 0.35
	_save_timer.timeout.connect(_save_volume_settings)
	add_child(_save_timer)
	_load_volume_settings()
	get_tree().node_added.connect(_on_node_added)
	for button: Button in get_tree().root.find_children("*", "Button", true, false):
		_wire_button(button)


func _make_player(player_name: String, bus_name: StringName) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = bus_name
	add_child(player)
	return player


func _load_volume_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	for bus_name: StringName in AUDIO_BUSES:
		var value: float = float(config.get_value("audio", String(bus_name), 1.0))
		_set_bus_volume(bus_name, value)


func _save_volume_settings() -> void:
	var config := ConfigFile.new()
	for bus_name: StringName in AUDIO_BUSES:
		config.set_value("audio", String(bus_name), float(_volume_settings.get(bus_name, 1.0)))
	config.save(SETTINGS_PATH)


func get_bus_volume(bus_name: StringName) -> float:
	return float(_volume_settings.get(bus_name, 1.0))


func set_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	_set_bus_volume(bus_name, linear_volume)
	if is_instance_valid(_save_timer):
		_save_timer.start()


func _set_bus_volume(bus_name: StringName, linear_volume: float) -> void:
	var value: float = clampf(linear_volume, 0.0, 1.0)
	_volume_settings[bus_name] = value
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(value) if value > 0.0 else -80.0)


func play_sfx(stream: AudioStream, bus_name: StringName = &"SFX") -> AudioStreamPlayer:
	if stream == null:
		return null
	var player := AudioStreamPlayer.new()
	player.stream = _make_one_shot(stream)
	player.bus = bus_name
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player


func play_sfx_at(stream: AudioStream, world_position: Vector2, bus_name: StringName = &"SFX") -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = _make_one_shot(stream)
	player.bus = bus_name
	add_child(player)
	player.global_position = world_position
	player.finished.connect(player.queue_free)
	player.play()


func _make_one_shot(stream: AudioStream) -> AudioStream:
	var one_shot := stream.duplicate() as AudioStream
	if one_shot is AudioStreamOggVorbis:
		(one_shot as AudioStreamOggVorbis).loop = false
	elif one_shot is AudioStreamWAV:
		(one_shot as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED
	return one_shot


func play_random_sfx(streams: Array[AudioStream], bus_name: StringName = &"SFX") -> void:
	if not streams.is_empty():
		play_sfx(streams.pick_random(), bus_name)


func play_random_sfx_at(
	streams: Array[AudioStream], world_position: Vector2, bus_name: StringName = &"SFX"
) -> void:
	if not streams.is_empty():
		play_sfx_at(streams.pick_random(), world_position, bus_name)


func start_menu_music() -> void:
	_combat_sources.clear()
	_combat_active = false
	var menu_track: String = _random_track("Ambient", 10)
	_start_music(menu_track, menu_track)


func start_level_audio() -> void:
	_combat_sources.clear()
	_combat_active = false
	_start_music(_random_track("Ambience", 5), _random_track("Action", 5))
	var ambience_stream := load(DESERT_AMBIENCE_PATH) as AudioStreamWAV
	if ambience_stream != null:
		ambience_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_ambience.stream = ambience_stream
		_ambience.volume_db = -8.0
		_ambience.play()


func _start_music(calm_path: String, combat_path: String) -> void:
	if _music_tween and _music_tween.is_running():
		_music_tween.kill()
	_ending_music.stop()
	_music_a.stop()
	_music_b.stop()
	_music_a.stream = _looping_ogg(calm_path)
	_music_b.stream = _looping_ogg(combat_path)
	_music_a.volume_db = 0.0
	_music_b.volume_db = -80.0
	_music_a.play()
	_music_b.play()
	_ambience.stop()


func _looping_ogg(path: String) -> AudioStreamOggVorbis:
	var stream := load(path) as AudioStreamOggVorbis
	if stream != null:
		stream.loop = true
	return stream


func _random_track(category: String, track_count: int) -> String:
	return "res://assets/sound/bgm/Tracks/%s %d.ogg" % [category, randi_range(1, track_count)]


func set_combat_active(source: Object, active: bool) -> void:
	if not is_instance_valid(source):
		return
	var source_id: int = source.get_instance_id()
	if active:
		_combat_sources[source_id] = true
	else:
		_combat_sources.erase(source_id)
	var should_use_combat_music: bool = not _combat_sources.is_empty()
	if should_use_combat_music == _combat_active:
		return
	_combat_active = should_use_combat_music
	_fade_to_combat_music(_combat_active)


func _fade_to_combat_music(use_combat_music: bool) -> void:
	if _music_tween and _music_tween.is_running():
		_music_tween.kill()
	var combat_volume: float = 0.0 if use_combat_music else -80.0
	var calm_volume: float = -80.0 if use_combat_music else 0.0
	if use_combat_music and not _music_b.playing:
		_music_b.play()
	if not use_combat_music and not _music_a.playing:
		_music_a.play()
	_music_tween = create_tween().set_parallel(true)
	_music_tween.tween_property(_music_a, "volume_db", calm_volume, 1.0)
	_music_tween.tween_property(_music_b, "volume_db", combat_volume, 1.0)


func play_ending_music() -> void:
	if _music_tween and _music_tween.is_running():
		_music_tween.kill()
	_music_a.stop()
	_music_b.stop()
	_ending_music.stream = load(END_MUSIC_PATH)
	_ending_music.volume_db = 0.0
	_ending_music.play()
	_ambience.stop()
	_combat_sources.clear()
	_combat_active = false


func _on_node_added(node: Node) -> void:
	if node is Button:
		_wire_button(node)


func _wire_button(button: Button) -> void:
	if button.has_meta(&"audio_manager_wired"):
		return
	button.set_meta(&"audio_manager_wired", true)
	button.mouse_entered.connect(_play_ui_sound)
	button.pressed.connect(_play_ui_sound)


func _play_ui_sound() -> void:
	if is_instance_valid(_ui_player):
		_ui_player.stop()
		_ui_player.queue_free()
	_ui_player = play_sfx(UI_SOUNDS.pick_random(), &"UI")
