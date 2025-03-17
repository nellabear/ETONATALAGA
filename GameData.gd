extends Node

# Player data
var player_count = 1
var player_names = []
var current_player_index = 0

# Game settings
enum Difficulty {EASY, AVERAGE, HARD}
var difficulty = Difficulty.EASY
var question_count = 10

# Game state
var scores = []
var current_question_index = 0

# Initialize player scores
func init_scores():
	scores.clear()
	for i in range(player_count):
		scores.append(0)

# Reset all game data for a new game
func reset_game():
	player_names.clear()
	scores.clear()
	current_player_index = 0
	current_question_index = 0

# Get current player name
func get_current_player_name():
	if player_names.size() <= current_player_index:
		return "Player " + str(current_player_index + 1)
	return player_names[current_player_index]

# Move to next player's turn
func next_player():
	current_player_index = (current_player_index + 1) % player_count
	return current_player_index

# Add points to current player's score
func add_score(points):
	scores[current_player_index] += points

# Get string with all player scores
func get_score_summary():
	var summary = ""
	for i in range(player_count):
		summary += player_names[i] + ": " + str(scores[i]) + "\n"
	return summary
