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


@onready var Iquestion_texts: Label = $Content/IQuestionInfo/IQuestionText
@onready var Iquestion_image: TextureRect = $Content/IQuestionInfo/DImageHolder/IQuestionImage
@onready var Iquestion_video: VideoStreamPlayer = $Content/IQuestionInfo/DImageHolder/IQuestionVideo
@onready var Iquestion_audio: AudioStreamPlayer = $Content/IQuestionInfo/DImageHolder/IQuestionAudio
@onready var answer_input: LineEdit = $Content/IQuestionHolder/AnswerInput
@onready var correct_answer_label: Label = $Content/IQuestionHolder/AnswerInput/CorrectAnswerLabel

func _ready() -> void:
	for button in $Content/IQuestionInfo/DImageHolder.get_children():
		buttons.append(button)
		
		selected_questions = randomize_array(quiz.Itheme).slice(0, 5) 
		load_quiz()
		
		
func _on_button_pressed() -> void:
	_check_answer(answer_input.text)


func _on_question_timer_timeout() -> void:
	$QuestionTimer.stop()
	
	var Icorrect_text = selected_questions[index].Icorrect
	$Content/IQuestionHolder/AnswerInput.text = "" + Icorrect_text
	$Content/IQuestionHolder/AnswerInput.modulate = color_right
	$IAudioIncorrect.play()
	
	var Icorrect: Button = null
	
	for btn in buttons:
		if btn.text == Icorrect_text:
			Icorrect = btn
			$IAudioIncorrect.play()
			break
	
	if Icorrect:
		for i in 3:
			Icorrect.modulate = color_right
			$IAudioCorrect.play()
			await get_tree().create_timer(0.3).timeout
			Icorrect.modulate = Color.WHITE
			await get_tree().create_timer(0.3).timeout 
			
	await get_tree().create_timer(1).timeout
	
	$Content/IQuestionHolder/AnswerInput.text = ""
	$Content/IQuestionHolder/AnswerInput.modulate = Color.WHITE
	
	index += 1
	load_quiz()


func _check_answer(answer: String) -> void:
	$QuestionTimer.stop()
	
	var Icorrect_text = selected_questions[index].Icorrect
	
	if answer.strip_edges().to_lower() == Icorrect_text.to_lower():
		answer_input.modulate = color_right
		$IAudioCorrect.play()
		Icorrect += 1
	else:
		answer_input.modulate = color_wrong
		$IAudioIncorrect.play()
		
		$Content/IQuestionHolder/AnswerInput/CorrectAnswerLabel.text = "" + Icorrect_text
		$Content/IQuestionHolder/AnswerInput/CorrectAnswerLabel.modulate = color_right
		
		var correct_button: Button = null	
		for btn in buttons: 
			if btn.text == Icorrect_text:
				correct_button = btn
				break
				
		if correct_button:
			for i in range(3):
				correct_button.modulate = color_right
				$IAudioCorrect.play()
				await get_tree().create_timer(0.3).timeout
				correct_button.modulate = Color.WHITE
				await get_tree().create_timer(0.3).timeout
				
	await get_tree().create_timer(1).timeout
	answer_input.text = ""
	answer_input.modulate = Color.WHITE
	$Content/IQuestionHolder/AnswerInput/CorrectAnswerLabel.text = ""
	
	index += 1
	load_quiz()


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
	$QuestionTimer/QuestionLabel.text = selected_questions[index].Iquestion_info
	$Content/IQuestionHolder/AnswerInput/CorrectAnswerLabel.text = ""
	$Content/IQuestionHolder/AnswerInput.text = ""

func load_quiz() -> void:	
	if index >= quiz.Itheme.size():
		_game_over()
		return
		
	update_question_display()
	$QuestionTimer.start(20.00)
	
	Iquestion_texts.text = current_quiz.Iquestion_info
	
	var Ioptions = randomize_array(current_quiz.Ioptions)
	for i in buttons.size():
		buttons[i].text = Ioptions[i]
		buttons[i].pressed.connect(_buttons_answer.bind(buttons[i]))
		
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

func _buttons_answer(button) -> void:
	if current_quiz.Icorrect == button.text:
		button.modulate = color_right
		$IAudioCorrect.play()
	else:
		button.modulate = color_wrong
		$IAudioIncorrect.play()

	_next_question()


func _next_question() -> void:
	for bt in buttons:
		bt.pressed.disconnect(_buttons_answer)
		
	await get_tree().create_timer(1).timeout
	
	for bt in buttons:
		bt.modulate = Color.WHITE
	
	Iquestion_audio.stop()
	Iquestion_video.stop()
	Iquestion_audio.stream = null
	Iquestion_video.stream = null  
	
	index += 1
	load_quiz() 
	
	
func randomize_array(array: Array) -> Array:
	var array_temp := array
	array_temp.shuffle()
	return array_temp
	
func _game_over() -> void:
	print("DONE")
