#HARDGAMEMODE
extends Node

@export var quiz: IQuizTheme
@export var color_right: Color
@export var color_wrong: Color

var buttons: Array[Button]
var index: int 
var Icorrect: int
var selected_questions: Array[IQuizQuestion]

var current_quiz: IQuizQuestion:
	get: return quiz.Itheme[index]

@onready var player_turn_label: Label = $Content/PlayerTurnLabel
@onready var Iquestion_texts: Label = $Content/IQuestionInfo/IQuestionText
@onready var Iquestion_image: TextureRect = $Content/IQuestionInfo/DImageHolder/IQuestionImage
@onready var Iquestion_video: VideoStreamPlayer = $Content/IQuestionInfo/DImageHolder/IQuestionVideo
@onready var Iquestion_audio: AudioStreamPlayer = $Content/IQuestionInfo/DImageHolder/IQuestionAudio
@onready var answer_input: LineEdit = $Content/IQuestionHolder/AnswerInput
@onready var correct_answer_label: Label = $Content/IQuestionHolder/AnswerInput/CorrectAnswerLabel
@onready var score_container: VBoxContainer = $Content/ScoreContainer
@onready var score_label: Label = $Content/ScoreContainer/ScoreLabel
@onready var hint_label: Button = $Content/IQuestionHolder/HintLabel

var power_up_chance = 0.3  # 30% chance to get a power-up
enum PowerUpType {SKIP_QUESTION, EXTRA_TIME, DOUBLE_POINTS, ELIMINATE_OPTION}
var active_power_up = null

func _ready() -> void:
	for button in $Content/IQuestionInfo/DImageHolder.get_children():
		buttons.append(button)
		
	GameData.init_scores()
	GameData.current_question_index = 0
	GameData.current_player_index = 0
		
	randomize_array(quiz.Itheme)
	quiz.Itheme = quiz.Itheme.slice(0, GameData.question_count - 1)
	
	setup_player_scores()
	
	update_player_turn_display()
	
	load_quiz()


func setup_player_scores():
	# Create score labels for each player
	for i in range(GameData.player_count):
		var score_row = VBoxContainer.new()
		score_row.name = "PlayerRow" + str(i)
		
		var name_label = Label.new()
		name_label.text = GameData.player_names[i]
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.name = "NameLabel"
		
		var score_label = Label.new()
		score_label.text = "0"
		score_label.name = "ScoreLabel" 
		
		score_row.add_child(name_label)
		score_row.add_child(score_label)
		score_container.add_child(score_row)
		
		
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
	
	
func _on_button_pressed() -> void:
	_check_answer(answer_input.text)


func _on_question_timer_timeout() -> void:
	$QuestionTimer.stop()
	
	var Icorrect_text = current_quiz.Icorrect
	answer_input.text = "" + Icorrect_text
	answer_input.modulate = color_wrong  # Changed to wrong color since they didn't answer in time
	$IAudioIncorrect.play()
	
	correct_answer_label.text = "Time's up! Correct: " + Icorrect_text
	correct_answer_label.modulate = color_right
	
	update_player_scores()
	
	next_player()
	await get_tree().create_timer(1.5).timeout
	load_quiz()


func _check_answer(answer: String) -> void:
	$QuestionTimer.stop()
	
	var Icorrect_text = current_quiz.Icorrect
	var time_left = $QuestionTimer.time_left
	var max_points = 5 
	
	if answer.strip_edges().to_lower() == Icorrect_text.to_lower():
		answer_input.modulate = color_right
		$IAudioCorrect.play()
		
		var points = int(max_points * (time_left / 20.0))  # 20 seconds total time
		points = max(1, points)  # Ensure at least 1 point
		
		if active_power_up == PowerUpType.DOUBLE_POINTS:
			points *= 2
		
		# Add points to current player's score
		GameData.add_score(points)
		update_player_scores()
		
		# Check if we should award a power-up (only for correct answers)
		if randf() < power_up_chance:
			# Randomly select a power-up type
			var power_up_type = randi() % PowerUpType.size()
			GameData.add_power_up(power_up_type)
			
			# Show notification that player got a power-up
			var notification = $Content/PowerUpNotification
			if notification:
				notification.text = "You got a " + get_power_up_name(power_up_type) + "!"
				notification.visible = true
				await get_tree().create_timer(1.5).timeout
				notification.visible = false
	else:
		answer_input.modulate = color_wrong
		$IAudioIncorrect.play()
		
		correct_answer_label.text = "Correct: " + Icorrect_text
		correct_answer_label.modulate = color_right
		
	await get_tree().create_timer(1.5).timeout
	
	answer_input.text = ""
	answer_input.modulate = Color.WHITE
	correct_answer_label.text = ""
	
	next_player()
	load_quiz()


func next_player() -> void:
	# Reset UI elements
	answer_input.text = ""
	answer_input.modulate = Color.WHITE
	correct_answer_label.text = ""
	
	# Stop any media
	Iquestion_audio.stop()
	Iquestion_video.stop()
	
	# Reset active power-up
	active_power_up = null
	
	# Move to next player
	GameData.next_player()
	update_player_turn_display()
	
	# If we've gone through all players, move to the next question
	if GameData.current_player_index == 0:
		GameData.current_question_index += 1
		index += 1


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
			# For identification mode, maybe give a hint
			var hint_label = $Content/IQuestionHolder/HintLabel
			if hint_label:
				hint_label.text = "First letter: " + current_quiz.Icorrect.substr(0, 1)
				hint_label.visible = true


func _on_AnswerInput_text_submitted(answer: String) -> void:
	if answer.strip_edges().to_lower() == selected_questions[index].correct.to_lower():
		answer_input.modulate = color_right
		$IAudioCorrect.play()
		index += 1
	else:
			answer_input.modulate = color_wrong
			$IAudioIncorrect.play()

	await get_tree().create_timer(1).timeout
	_check_answer(answer)
	index += 1
	load_quiz()


func update_question_display():
	$Content/IQuestionHolder/AnswerInput/CorrectAnswerLabel.text = ""
	$Content/IQuestionHolder/AnswerInput.text = ""

func load_quiz() -> void:	
	if index >= quiz.Itheme.size() || GameData.current_question_index >= GameData.question_count:
		_game_over()
		return
		
	update_question_display()
	$QuestionTimer.start(20.00)
	
	Iquestion_texts.text = current_quiz.Iquestion_info
	
	var player_power_ups = GameData.power_ups[GameData.current_player_index]
	if player_power_ups.size() > 0:
		show_power_up_options()
		
	match current_quiz.Itype:
		IEnum.IQuestionType.TEXT:
			$Content/IQuestionInfo/DImageHolder.hide()

		IEnum.IQuestionType.IMAGE:
			$Content/IQuestionInfo/DImageHolder.show()
			Iquestion_image.texture = current_quiz.Iquestion_image

		IEnum.IQuestionType.VIDEO:
			$Content/IQuestionInfo/DImageHolder.show()
			Iquestion_video.stream = current_quiz.Iquestion_video
			Iquestion_video.play()

		IEnum.IQuestionType.AUDIO:
			$Content/IQuestionInfo/DImageHolder.show()
			Iquestion_image.texture = current_quiz.Iquestion_image
			Iquestion_audio.stream = current_quiz.Iquestion_audio
			Iquestion_audio.play()


func _process(delta):
	$QuestionTimer/QuestionLabel.text = "%.2f " % $QuestionTimer.time_left
	
	
func randomize_array(array: Array) -> Array:
	var array_temp := array.duplicate()
	array_temp.shuffle()
	return array_temp
	
func _game_over() -> void:
	print("GAME OVER")
	print("Final Scores:")
	print(GameData.get_score_summary())
	
	# Transition to the rank scene
	get_tree().change_scene_to_file("res://RANKING(ENDGAME).tscn")
