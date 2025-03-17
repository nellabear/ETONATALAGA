extends Control

signal players_selected(player_count)

# Number of players selected (1-4)
var selected_players = 1

# Called when the node enters the scene tree for the first time
func _ready():
	# Connect signals for player selection buttons
	$VBoxContainer/PlayerButtons/Player1Button.pressed.connect(_on_player_button_pressed.bind(1))
	$VBoxContainer/PlayerButtons/Player2Button.pressed.connect(_on_player_button_pressed.bind(2))
	$VBoxContainer/PlayerButtons/Player3Button.pressed.connect(_on_player_button_pressed.bind(3))
	$VBoxContainer/PlayerButtons/Player4Button.pressed.connect(_on_player_button_pressed.bind(4))
	
	# Connect continue button
	
	# Set initial selection
	_update_selection(1)

# Handle player count button pressed
func _on_player_button_pressed(count):
	_update_selection(count)

# Update the UI to reflect the current selection
func _update_selection(count):
	selected_players = count
	
	# Update button appearances
	$VBoxContainer/PlayerButtons/Player1Button.modulate = Color.WHITE
	$VBoxContainer/PlayerButtons/Player2Button.modulate = Color.WHITE
	$VBoxContainer/PlayerButtons/Player3Button.modulate = Color.WHITE
	$VBoxContainer/PlayerButtons/Player4Button.modulate = Color.WHITE
	
	# Highlight selected button
	match count:
		1: $VBoxContainer/PlayerButtons/Player1Button.modulate = Color.GREEN
		2: $VBoxContainer/PlayerButtons/Player2Button.modulate = Color.GREEN
		3: $VBoxContainer/PlayerButtons/Player3Button.modulate = Color.GREEN
		4: $VBoxContainer/PlayerButtons/Player4Button.modulate = Color.GREEN
	
	# Update label
	$SelectedLabel.text = "Selected: " + str(count) + " player" + ("s" if count > 1 else "")

# Handle continue button pressed - move to name input scene
func _on_continue_button_pressed():
	# Save player count to GameData
	GameData.player_count = selected_players
	GameData.reset_game()
	
	emit_signal("players_selected", selected_players)
	
	# Change to name input scene
	get_tree().change_scene_to_file("res://NAMESELECTION.tscn")
