extends Node

@export var quiz: QuizTheme
@export var color_right: Color
@export var color_wrong: Color

var buttons: Array[Button]
var index: int
var correct: int
var selected_questions: Array[QuizQuestion]
var current_quiz: QuizQuestion:
	get: return quiz.theme[index]

# Player turn variables
@onready var player_turn_label: Label = $Content/PlayerTurnLabel
@onready var question_texts: Label = $Content/QuestionInfo/QuestionText
@onready var question_image: TextureRect = $Content/QuestionInfo/ImageHolder/QuestionImage
@onready var question_video: VideoStreamPlayer = $Content/QuestionInfo/ImageHolder/QuestionVideo
@onready var question_audio: AudioStreamPlayer = $Content/QuestionInfo/ImageHolder/QuestionAudio
@onready var score_container: HBoxContainer = $Content/ScoreContainer
@onready var score_label: Label = $Content/ScoreContainer/ScoreLabel
@onready var response_times_container: VBoxContainer = $Content/ResponseTimesContainer
@onready var response_time_label: Label = $Content/ResponseTimesContainer/ResponseTimeLabel

var power_up_chance = 0.3  # 30% chance to get a power-up
enum PowerUpType {SKIP_QUESTION, EXTRA_TIME, DOUBLE_POINTS, ELIMINATE_OPTION}
var active_power_up = null

# Timer variables
var start_time: int
var question_start_time: int

func _ready() -> void:
	# Set up buttons
	for button in $Content/QuestionHolder.get_children():
		buttons.append(button)
	
	# Initialize scores in GameData
	GameData.init_scores()
	GameData.current_question_index = 0
	GameData.current_player_index = 0
	
	# Use only the specified number of questions
	randomize_array(quiz.theme)
	quiz.theme = quiz.theme.slice(0, GameData.question_count - 1)
	
	# Set up player score display
	setup_player_scores()
	
	# Set up response time display container
	setup_response_times_container()
	
	# Update the player turn display
	update_player_turn_display()
	
	# Load the first quiz question
	load_quiz()
	
func setup_player_scores():
	# Create score labels for each player
	for i in range(GameData.player_count):
		var score_row = HBoxContainer.new()
		score_row.name = "PlayerRow" + str(i)
		
		var name_label = Label.new()
		name_label.text = GameData.player_names[i]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.name = ""
		
		var score_label = Label.new()
		score_label.text = "0"
		score_label.name = "ScoreLabel" 
		
		score_row.add_child(name_label)
		score_row.add_child(score_label)
		score_container.add_child(score_row)

func setup_response_times_container():
	# Create response time container if it doesn't exist
	if not has_node("Content/ResponseTimesContainer"):
		var container = VBoxContainer.new()
		container.name = "ResponseTimesContainer"
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.visible = false
		$Content.add_child(container)
		
		var title_label = Label.new()
		title_label.text = "Response Times:"
		title_label.name = "ResponseTimeLabel"
		container.add_child(title_label)
		
		response_times_container = container
		response_time_label = title_label
	
func update_player_scores():
	# Update score display for all players
	for i in range(GameData.player_count):
		var score_row = score_container.get_node("PlayerRow" + str(i))
		if score_row:
			var score_label = score_row.get_node("ScoreLabel")
			if score_label:
				score_label.text = str(GameData.scores[i])
	
func update_player_turn_display():
	player_turn_label.text = "Player " + str(GameData.current_player_index + 1) + " Turn: " + GameData.get_current_player_name()

func display_response_times():
	# Clear previous response time labels
	for child in response_times_container.get_children():
		if child != response_time_label:
			child.queue_free()
	
	# Get response times from GameData
	var times = GameData.question_response_times.duplicate()
	var correctness = GameData.question_correctness.duplicate()
	
	# Create labels for each player's response time
	for i in range(GameData.player_count):
		var time_label = Label.new()
		var player_name = GameData.player_names[i] if i < GameData.player_names.size() else "Player " + str(i + 1)
		
		if times[i] != null:
			# Convert response time from milliseconds to seconds with 2 decimal places
			var response_time = times[i] / 1000.0
			time_label.text = player_name + ": " + ("%.2f" % response_time) + "s" + (" ✓" if correctness[i] else " ✗")
		else:
			time_label.text = player_name + ": No answer "
		
		response_times_container.add_child(time_label)
	
	# Show the response times container
	response_times_container.visible = true

func on_question_timer_timeout() -> void:
	$QuestionTimer.stop()
	
	var correct_button: Button = null
	
	for button in buttons:
		if button.text.strip_edges().to_lower() == current_quiz.correct.strip_edges().to_lower():
			correct_button = button
			break
			
	for button in buttons:
		if button == correct_button:
			button.modulate = color_right 
		else:
			button.modulate = color_wrong 
	
	$AudioIncorrect.play()
	print("Correct Answer:", current_quiz.correct)
	
	# Record that the player didn't answer in time (incorrect)
	GameData.add_score(false)
	update_player_scores()
	
	# Delay before moving to next player
	await get_tree().create_timer(1).timeout
	next_player()

func update_question_display():
	$QuestionTimer/QuestionLabel.text = quiz.theme[index].question_info

func load_quiz() -> void:
	if index >= quiz.theme.size():
		game_over()
		return
	
	# Update question display
	update_question_display()
	
	# Hide response times from previous question when loading a new question
	if response_times_container:
		response_times_container.visible = false
	
	# Store the time when question starts
	question_start_time = Time.get_ticks_msec()
	
	# Start the timer
	$QuestionTimer.start(10.00)
	# Make sure the timeout signal is connected (fix for timer issue)
	if not $QuestionTimer.timeout.is_connected(on_question_timer_timeout):
		$QuestionTimer.timeout.connect(on_question_timer_timeout)
	
	question_texts.text = current_quiz.question_info
	
	var options = current_quiz.options.duplicate()  # Use duplicate to avoid modifying original
	
	if has_power_up(PowerUpType.ELIMINATE_OPTION):
		show_power_up_options()
		
	if options.size() > 2:
		options = randomize_array(options)
		
	# Disconnect previous signals first to avoid duplicates
	for bt in buttons:
		if bt.pressed.is_connected(_buttons_answer):
			bt.pressed.disconnect(_buttons_answer)
	
	for i in buttons.size():
		if i < options.size():
			buttons[i].text = options[i]
			buttons[i].visible = true
			buttons[i].pressed.connect(_buttons_answer.bind(buttons[i]))
		else:
			buttons[i].visible = false
			
	match current_quiz.type:
		Enum.QuestionType.TEXT:
			$Content/QuestionInfo/ImageHolder.hide()
		Enum.QuestionType.IMAGE:
			$Content/QuestionInfo/ImageHolder.show()
			question_image.texture = current_quiz.question_image
		Enum.QuestionType.VIDEO:
			$Content/QuestionInfo/ImageHolder.show()
			question_video.stream = current_quiz.question_video
			question_video.play()
		Enum.QuestionType.AUDIO:
			$Content/QuestionInfo/ImageHolder.show()
			question_image.texture = current_quiz.question_image
			question_audio.stream = current_quiz.question_audio
			question_audio.play()
			
func has_power_up(power_up_type):
	var player_power_ups = GameData.power_ups[GameData.current_player_index]
	return power_up_type in player_power_ups
	
func show_power_up_options():
	# Show a UI to let the player select which power-up to use
	var power_up_panel = $Content/PowerUpPanel
	power_up_panel.visible = true
	
	for child in power_up_panel.get_node("VBoxContainer").get_children():
		child.queue_free()
	
	var player_power_ups = GameData.power_ups[GameData.current_player_index]
	for i in range(player_power_ups.size()):
		var power_up_button = Button.new()
		var power_up_type = player_power_ups[i]
		power_up_button.text = get_power_up_name(power_up_type)
		power_up_button.pressed.connect(_on_power_up_selected.bind(i))
		power_up_panel.get_node("VBoxContainer").add_child(power_up_button)
		
	var no_power_up_button = Button.new()
	no_power_up_button.text = "Don't use a power-up"
	no_power_up_button.pressed.connect(_on_no_power_up)
	power_up_panel.get_node("VBoxContainer").add_child(no_power_up_button)
	
func get_power_up_name(power_up_type):
	match power_up_type:
		PowerUpType.SKIP_QUESTION:
			return "Skip Question"
		PowerUpType.EXTRA_TIME:
			return "Extra Time (+5s)"
		PowerUpType.DOUBLE_POINTS:
			return "Double Points"
		PowerUpType.ELIMINATE_OPTION:
			return "Eliminate Wrong Option"
	return "Unknown Power-up"
	
func _on_power_up_selected(power_up_index):
	# Use the selected power-up
	var power_up = GameData.use_power_up(power_up_index)
	active_power_up = power_up
	apply_power_up(power_up)
	$Content/PowerUpPanel.visible = false
	
func _on_no_power_up():
	# Don't use a power-up
	$Content/PowerUpPanel.visible = false
	
func apply_power_up(power_up_type):
	match power_up_type:
		PowerUpType.SKIP_QUESTION:
			# Skip to the next question
			next_player()
			index += 1
			load_quiz()
		PowerUpType.EXTRA_TIME:
			# Add 5 seconds to the timer
			$QuestionTimer.start($QuestionTimer.time_left + 5.0)
		PowerUpType.DOUBLE_POINTS:
			# Double points will be applied when scoring
			pass
		PowerUpType.ELIMINATE_OPTION:
			# Eliminate a wrong option
			eliminate_wrong_option()
	
func eliminate_wrong_option():
	# Find a wrong option to eliminate
	var correct_answer = current_quiz.correct
	var wrong_buttons = []
	
	for button in buttons:
		if button.text != correct_answer and button.visible:
			wrong_buttons.append(button)
	
	if wrong_buttons.size() > 0:
		# Randomly select one wrong option to eliminate
		var random_index = randi() % wrong_buttons.size()
		wrong_buttons[random_index].visible = false

func _process(delta):
	$QuestionTimer/QuestionLabel.text = "%.2f " % $QuestionTimer.time_left

func _buttons_answer(button) -> void:
	$QuestionTimer.stop()
	
	var is_correct = current_quiz.correct == button.text
	var current_time = Time.get_ticks_msec()
	var response_time = current_time - question_start_time
	
	if is_correct:
		button.modulate = color_right
		$AudioCorrect.play()
		
		# Record that the answer was correct with response time
		GameData.add_score(true)
		update_player_scores()
		
		# Check if we should award a power-up (only for correct answers)
		if randf() < power_up_chance:
			# Randomly select a power-up type
			var power_up_type = randi() % PowerUpType.size()
			GameData.add_power_up(power_up_type)
			
			# Show notification that player got a power-up
			$Content/PowerUpNotification.text = "You got a " + get_power_up_name(power_up_type) + "!"
			$Content/PowerUpNotification.visible = true
			await get_tree().create_timer(1.5).timeout
			$Content/PowerUpNotification.visible = false
	else:
		button.modulate = color_wrong
		$AudioIncorrect.play()
		
		# Record that the answer was incorrect
		GameData.add_score(false)
		
		# Highlight correct answer
		for btn in buttons:
			if btn.text == current_quiz.correct:
				btn.modulate = color_right
				break
	
	# Delay before moving to next player
	await get_tree().create_timer(1).timeout
	next_player()

func next_player() -> void:
	# Clean up button connections
	for bt in buttons:
		if bt.pressed.is_connected(_buttons_answer):
			bt.pressed.disconnect(_buttons_answer)
	
	# Reset UI elements
	for bt in buttons:
		bt.modulate = Color.WHITE
	
	question_audio.stop()
	question_video.stop()
	question_audio.stream = null
	question_video.stream = null
	
	# Move to next player
	GameData.next_player()
	update_player_turn_display()
	
	# If we've gone through all players for this question
	if GameData.current_player_index == 0:
		# Display response times for all players before moving to next question
		display_response_times()
		
		# Wait a bit to show the response times
		await get_tree().create_timer(3.0).timeout
		response_times_container.visible = false
		
		# Move to next question
		GameData.current_question_index += 1
		index += 1
	
	# Load the same question for the next player
	load_quiz()
	
func randomize_array(array: Array) -> Array:
	var array_temp := array
	array_temp.shuffle()
	return array_temp

func game_over() -> void:
	print("GAME OVER")
	print("Final Scores:")
	print(GameData.get_score_summary())
	
