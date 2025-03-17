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
@onready var player_turn_label: Label = $PlayerTurnLabel
@onready var question_texts: Label = $Content/QuestionInfo/QuestionText
@onready var question_image: TextureRect = $Content/QuestionInfo/ImageHolder/QuestionImage
@onready var question_video: VideoStreamPlayer = $Content/QuestionInfo/ImageHolder/QuestionVideo
@onready var question_audio: AudioStreamPlayer = $Content/QuestionInfo/ImageHolder/QuestionAudio

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
	
	# Update the player turn display
	update_player_turn_display()
	
	# Load the first quiz question
	load_quiz()

func update_player_turn_display():
	player_turn_label.text = "Player " + str(GameData.current_player_index + 1) + " Turn: " + GameData.get_current_player_name()

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
			
	# No points added since time ran out
	
	next_question()
	await get_tree().create_timer(1).timeout
	load_quiz()

func update_question_display():
	$QuestionTimer/QuestionLabel.text = quiz.theme[index].question_info

func load_quiz() -> void:
	if index >= quiz.theme.size():
		game_over()
		return
	
	# Update question display
	update_question_display()
	$QuestionTimer.start(10.00)
	
	question_texts.text = current_quiz.question_info
	
	var options = current_quiz.options
	for i in buttons.size():
		buttons[i].text = options[i]
		buttons[i].pressed.connect(_buttons_answer.bind(buttons[i]))
		
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

func _process(delta):
	$QuestionTimer/QuestionLabel.text = "%.2f " % $QuestionTimer.time_left

func _buttons_answer(button) -> void:
	$QuestionTimer.stop()
	
	if current_quiz.correct == button.text:
		button.modulate = color_right
		$AudioCorrect.play()
		
		# Add 5 points to the current player's score
		GameData.add_score(5)
		print("Player " + str(GameData.current_player_index + 1) + " score: " + str(GameData.scores[GameData.current_player_index]))
	else:
		button.modulate = color_wrong
		$AudioIncorrect.play()
		for btn in $Content/QuestionHolder.get_children():
			if btn.text == current_quiz.correct:
				btn.modulate = color_right
				break
	
	await get_tree().create_timer(1).timeout
	next_question()

func next_question() -> void:
	for bt in buttons:
		bt.pressed.disconnect(_buttons_answer)
		
	await get_tree().create_timer(1).timeout
	
	for bt in buttons:
		bt.modulate = Color.WHITE
	
	question_audio.stop()
	question_video.stop()
	question_audio.stream = null
	question_video.stream = null  
	
	# Go to next player's turn
	GameData.next_player()
	update_player_turn_display()
	
	# Increment global question index
	GameData.current_question_index += 1
	
	# Increment local index for the question array
	index += 1
	load_quiz() 

func randomize_array(array: Array) -> Array:
	var array_temp := array
	array_temp.shuffle()
	return array_temp

func game_over() -> void:
	print("GAME OVER")
	print("Final Scores:")
	print(GameData.get_score_summary())
	
	# Transition to the rank scene
	get_tree().change_scene_to_file("res://RANKSCENE.tscn")
