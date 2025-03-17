extends Control

func _ready():
	# Get ranked player indices
	var ranked_indices = GameData.get_ranked_players()
	
	# Hide all rank containers initially
	for i in range(1, 5):
		var rank_container = $BACKGROUND/RankingsContainer.get_node("Rank" + str(i) + "Container")
		if rank_container:
			rank_container.visible = false
	
	# Show and populate rank containers based on actual player count
	for i in range(ranked_indices.size()):
		var player_idx = ranked_indices[i]
		var rank_container = $BACKGROUND/RankingsContainer.get_node("Rank" + str(i+1) + "Container")
		
		if rank_container:
			rank_container.visible = true
			
			# Set player name and score
			var name_label = rank_container.get_node("Player" + str(i+1) + "Name")
			var score_label = rank_container.get_node("Player" + str(i+1) + "Score")
			
			if name_label and score_label:
				name_label.text = GameData.player_names[player_idx]
				score_label.text = str(GameData.scores[player_idx])
	
	# Connect button signals
	$PlayAgainButton.connect("pressed", _on_play_again_pressed)
	$MainMenuButton.connect("pressed", _on_main_menu_pressed)

func _on_play_again_pressed():
	# Reset game with same settings and players
	GameData.reset_game()
	
	# Return to the game selection scene
	get_tree().change_scene_to_file("res://HOST.tscn")

func _on_main_menu_pressed():
	# Reset everything and return to main menu
	GameData.reset_game()
	get_tree().change_scene_to_file("res://MAIN MENU.tscn")
