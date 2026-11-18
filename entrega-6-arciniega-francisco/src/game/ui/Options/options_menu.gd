extends Control

@onready var key_mapping: VBoxContainer = $MainPanel/ScrollContainer/KeyMapping

func _ready() -> void:
	_add_audio_controls()


func _add_audio_controls() -> void:
	var heading := Label.new()
	heading.text = "Audio Volume (0 = mute)"
	key_mapping.add_child(heading)
	for bus_name: StringName in AudioManager.AUDIO_BUSES:
		var row := HBoxContainer.new()
		var bus_label := Label.new()
		bus_label.text = String(bus_name)
		bus_label.custom_minimum_size.x = 54.0
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 100.0
		slider.step = 1.0
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var percent_label := Label.new()
		percent_label.custom_minimum_size.x = 35.0
		slider.value = AudioManager.get_bus_volume(bus_name) * 100.0
		percent_label.text = _volume_text(slider.value)
		slider.value_changed.connect(_on_audio_volume_changed.bind(bus_name, percent_label))
		row.add_child(bus_label)
		row.add_child(slider)
		row.add_child(percent_label)
		key_mapping.add_child(row)


func _volume_text(value: float) -> String:
	return "Mute" if value <= 0.0 else "%d%%" % roundi(value)


func _on_audio_volume_changed(value: float, bus_name: StringName, percent_label: Label) -> void:
	AudioManager.set_bus_volume(bus_name, value / 100.0)
	percent_label.text = _volume_text(value)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("pause_menu") && visible:
		hide()

func _on_return_pressed() -> void:
	hide()
