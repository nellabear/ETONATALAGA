extends Control

@onready var rank_container = $RankContainer
@onready var back_button = $BackButton

func _ready():
	# Connect back button
	back_button.connect("pressed", _on_back_button_pressed)
	
	# Display the final rankings
	display_rankings()

func display_rankings():
	# Sort players by score (highest first)
	var player_data = []
	for i in range(GameData.player_count):
		player_data.append({
			"name": GameData.player_names[i],
			"score": GameData.scores[i]
		})
	
	# Sort by score (descending)
	player_data.sort_custom(func(a, b): return a.score > b.score)
	
	# Display rankings
	var rank_text = ""
	for i in range(player_data.size()):
		rank_text += str(i + 1) + ". " + player_data[i].name + ": " + str(player_data[i].score) + " points\n"
	
	$RankContainer/RankText.text = rank_text
	
	# Show winner announcement
	if player_data.size() > 0:
		$WinnerLabel.text = "Winner: " + player_data[0].name + "!"

func _on_back_button_pressed():
	# Return to game selection scene
	get_tree().change_scene_to_file("res://HOST.tscn")
