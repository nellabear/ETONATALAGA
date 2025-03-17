extends Node

var master_bus_index = AudioServer.get_bus_index("Master")
var sfx_bus_index = AudioServer.get_bus_index("sfx")
var master_volume = 1.0
var sfx_volume = 1.0
var is_muted = false

func _ready():
	print("🔊 AudioManager Loaded. Master bus index:", master_bus_index)
	load_volume()

func set_master_volume(value: float):
	if not is_muted:
		AudioServer.set_bus_volume_db(master_bus_index, linear_to_db(value))
		master_volume = value
	print("🎚️ Master volume set to:", value)

func set_sfx_volume(value: float):
	if not is_muted:
		AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(value))
		sfx_volume = value
	print("🎚️ SFX volume set to:", value)
	
func _on_master_value_changed(value: float) -> void:
	set_master_volume(value)

func _on_sfx_value_changed(value: float) -> void:
	set_sfx_volume(value) 
	
func get_master_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(master_bus_index))
	
func get_sfx_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(sfx_bus_index))
	
func save_volume():
	var file = FileAccess.open("user://audio_settings.cfg", FileAccess.WRITE)
	file.store_line(str(master_volume))
	file.store_line(str(sfx_volume))
	file.store_line(str(is_muted))

func load_volume():
	if FileAccess.file_exists("user://audio_settings.cfg"):
		var file = FileAccess.open("user://audio_settings.cfg", FileAccess.READ)
		master_volume = float(file.get_line())
		sfx_volume = float(file.get_line())
		is_muted = file.get_line().to_lower() == "true"
		set_master_volume(master_volume)
		set_sfx_volume(sfx_volume)
		if is_muted:
			mute_audio(true)
			
func mute_audio(mute: bool):
	is_muted = mute
	if mute:
		AudioServer.set_bus_volume_db(master_bus_index, -80)
		AudioServer.set_bus_volume_db(sfx_bus_index, -80)
		print("🔇 Audio Muted")
	else:
		set_master_volume(master_volume)
		set_sfx_volume(sfx_volume)
		print("🔊 Audio Unmuted")

func _on_mute_toggled(button_pressed: bool) -> void:
	mute_audio(button_pressed)
	save_volume()
