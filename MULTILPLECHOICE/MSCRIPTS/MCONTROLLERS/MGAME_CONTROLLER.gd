extends Node

@export var quiz: MQuizTheme
@export var color_right: Color
@export var color_wrong: Color

var buttons: Array[Button]
var index: int 
var Mcorrect: int
var selected_questions: Array[MQuizQuestion]

var current_quiz: MQuizQuestion:
	get: return quiz.Mtheme[index]


@onready var Mquestion_texts: Label = $Content/MQuestionInfo/MQuestionText
@onready var Mquestion_image: TextureRect = $Content/MQuestionInfo/MImageHolder/MQuestionImage 
@onready var Mquestion_video: VideoStreamPlayer = $Content/MQuestionInfo/MImageHolder/MQuestionVideo
@onready var Mquestion_audio: AudioStreamPlayer = $Content/MQuestionInfo/MImageHolder/MQuestionAudio


func _ready() -> void:
	for button in $Content/MQuestionHolder.get_children():
		buttons.append(button)
		
		randomize_array(quiz.Mtheme)
		quiz.Mtheme = quiz.Mtheme.slice(0, 5)  
		load_quiz()
		
		
func _on_question_timer_timeout() -> void:
	$QuestionTimer.stop()
	
	var Mcorrect: Button = null
	
	for button in buttons:
		if button.text.strip_edges().to_lower() == current_quiz.Mcorrect.strip_edges().to_lower():
			Mcorrect = button
			break
			
	for button in buttons:
		if button == Mcorrect:
			button.modulate = color_right 
			$MAudioIncorrect.play()
		else:
			button.modulate = color_wrong
			$MAudioIncorrect.play()
			print("Correct Answer:", current_quiz.Mcorrect)
			
	_next_question()
	await get_tree().create_timer(1).timeout
	load_quiz()


func update_question_display():
	$QuestionTimer/QuestionLabel.text = quiz.Mtheme[index].Mquestion_info


func load_quiz() -> void:
	if index >= quiz.Mtheme.size():
		_game_over()
		return
		
	update_question_display()
	$QuestionTimer.start(10.00)
	
	Mquestion_texts.text = current_quiz.Mquestion_info
	
	var Moptions = randomize_array(current_quiz.Moptions)
	for i in buttons.size():
		buttons[i].text = Moptions[i]
		buttons[i].pressed.connect(_buttons_answer.bind(buttons[i]))
		
	match current_quiz.Mtype:
		MEnum.MQuestionType.TEXT:
			$Content/MQuestionInfo/MImageHolder.hide()

		MEnum.MQuestionType.IMAGE:
			$Content/MQuestionInfo/MImageHolder.show()
			Mquestion_image.texture = current_quiz.Mquestion_image

		MEnum.MQuestionType.VIDEO:
			$Content/MQuestionInfo/MImageHolder.show()
			Mquestion_video.stream = current_quiz.Mquestion_video
			Mquestion_video.play()

		MEnum.MQuestionType.AUDIO:
			$Content/MQuestionInfo/MImageHolder.show()
			Mquestion_image.texture = current_quiz.Mquestion_image
			Mquestion_audio.stream = current_quiz.Mquestion_audio
			Mquestion_audio.play()


func _process(delta):
	$QuestionTimer/QuestionLabel.text = "%.2f " % $QuestionTimer.time_left


func _buttons_answer(button) -> void:
	$QuestionTimer.stop()
	
	if current_quiz.Mcorrect == button.text:
		button.modulate = color_right
		$MAudioCorrect.play()
	else:
		button.modulate = color_wrong
		$MAudioIncorrect.play()

		for btn in $Content/MQuestionHolder.get_children():
			if btn.text == current_quiz.Mcorrect:
				btn.modulate = color_right
				break
				
	await get_tree().create_timer(1).timeout
	_next_question()


func _next_question() -> void:
	for bt in buttons:
		bt.pressed.disconnect(_buttons_answer)
		
	await get_tree().create_timer(1).timeout
	
	for bt in buttons:
		bt.modulate = Color.WHITE
	
	Mquestion_audio.stop()
	Mquestion_video.stop()
	Mquestion_audio.stream = null
	Mquestion_video.stream = null  
	
	index += 1
	load_quiz() 
	
	
func randomize_array(array: Array) -> Array:
	var array_temp := array
	array_temp.shuffle()
	return array_temp
	
func _game_over() -> void:
	print("DONE")
