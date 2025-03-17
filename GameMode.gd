extends Control

signal game_settings_selected(difficulty, question_count)

enum Difficulty {EASY, AVERAGE, HARD}

var selected_difficulty = Difficulty.EASY
var question_count = 5 # Default value

# Called when the node enters the scene tree for the first time.
func _ready():
	# Connect difficulty buttons
	$EASY.connect("pressed", _on_difficulty_button_pressed.bind(Difficulty.EASY))
	$AVERAGE.connect("pressed", _on_difficulty_button_pressed.bind(Difficulty.AVERAGE))
	$HARD.connect("pressed", _on_difficulty_button_pressed.bind(Difficulty.HARD))
	
	# Connect question count spinbox
	$QuestionSpinBox.connect("value_changed", _on_question_spinbox_changed)
	
	# Connect start button
	$StartButton.connect("pressed", _on_start_button_pressed)
   
	# Set initial selection
	_update_difficulty_selection(Difficulty.EASY)
	
	# Set up question spinbox (max 300 as per requirements)
	$QuestionSpinBox.min_value = 5
	$QuestionSpinBox.max_value = 30
	$QuestionSpinBox.value = 5

# Handle difficulty button pressed
func _on_difficulty_button_pressed(difficulty):
	_update_difficulty_selection(difficulty)

# Update the UI to reflect the current difficulty selection
func _update_difficulty_selection(difficulty):
	selected_difficulty = difficulty
	
	# Reset all button colors
	$EASY.modulate = Color.WHITE
	$AVERAGE.modulate = Color.WHITE
	$HARD.modulate = Color.WHITE
	
	# Highlight selected button
	match difficulty:
		Difficulty.EASY:
			$EASY.modulate = Color.WHITE
			$SelectedDifficultyLabel.text = "Selected: Easy Mode"
		Difficulty.AVERAGE:
			$AVERAGE.modulate = Color.WHITE
			$SelectedDifficultyLabel.text = "Selected: Average Mode"
		Difficulty.HARD:
			$HARD.modulate = Color.WHITE
			$SelectedDifficultyLabel.text = "Selected: Hard Mode"

# Handle question spinbox changed
func _on_question_spinbox_changed(value):
	question_count = int(value)

# Handle start button pressed - move to the appropriate quiz scene
func _on_start_button_pressed():
	# Store settings in the GameData singleton
	GameData.difficulty = selected_difficulty
	GameData.question_count = question_count
	
	emit_signal("game_settings_selected", selected_difficulty, question_count)
	
	# Change to the appropriate quiz scene based on difficulty
	var scene_path = ""
	match selected_difficulty:
		Difficulty.EASY:
			scene_path = "res://EASYMODE(TRUEORFALSE).tscn"
		Difficulty.AVERAGE:
			scene_path = "res://AVERAGEMODE(MULTIPLECHOICES).tscn"
		Difficulty.HARD:
			scene_path = "res://HARDMODE(IDENTIFICATION).tscn"
	
	get_tree().change_scene_to_file(scene_path)
