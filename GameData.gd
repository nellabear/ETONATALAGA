extends Node

# Player management
var player_count = 1
var player_names = []
var scores = []
var current_player_index = 0
var current_question_index = 0

# Question tracking
var question_response_times = []  # Track response times for current question
var question_correctness = []     # Track if answers are correct

# Game settings
enum Difficulty {EASY, AVERAGE, HARD}
var difficulty = Difficulty.EASY
var question_count = 10

# Power-ups for each player
var power_ups = []  # Array of arrays, one array per player
var active_power_up = null

func _ready():
	# Initialize with default values
	reset_game()

func reset_game():
	# Reset scores and power-ups
	scores = []
	power_ups = []
	current_player_index = 0
	current_question_index = 0
	question_response_times = []
	question_correctness = []
	
	# Initialize arrays based on player count
	for i in range(player_count):
		scores.append(0)
		power_ups.append([])

func init_scores():
	# Make sure we have the right number of score entries
	scores.clear()
	for i in range(player_count):
		scores.append(0)
	
	# Initialize question response times and correctness arrays
	question_response_times = []
	question_correctness = []
	for i in range(player_count):
		question_response_times.append(null)
		question_correctness.append(false)
		
func add_score(is_correct):
	# Record if the answer was correct
	question_correctness[current_player_index] = is_correct
	
	# Record response time (only if there was an answer)
	if is_correct:
		question_response_times[current_player_index] = Time.get_ticks_msec()
	else:
		# For wrong answers, we still record the time but mark as incorrect
		question_response_times[current_player_index] = Time.get_ticks_msec()
	
	# Add points based on correctness
	if is_correct:
		scores[current_player_index] += 1

func adjust_scores_based_on_speed():
	# This is called when all players have answered the current question
	var player_speeds = []
	
	# First, collect all players who answered correctly
	for i in range(player_count):
		if question_correctness[i] and question_response_times[i] != null:
			# [player_index, response_time]
			player_speeds.append([i, question_response_times[i]])
	
	# If no players answered correctly, no points awarded
	if player_speeds.size() == 0:
		# Reset tracking arrays for next question
		reset_question_tracking()
		return
		
	# Sort by speed (lower time = faster)
	player_speeds.sort_custom(func(a, b): return a[1] < b[1])
	
	# Assign points based on ranking
	for rank in range(player_speeds.size()):
		var player_idx = player_speeds[rank][0]
		var points = 0
		
		# Award points based on rank
		match rank:
			0: points = 5  # Fastest
			1: points = 4  # Second fastest
			2: points = 3  # Third fastest
			3: points = 2  # Fourth fastest
			_: points = 1  # Fifth or more
		
		# Add points to score
		scores[player_idx] += points
	
	# Reset tracking arrays for next question
	reset_question_tracking()

# Helper function to reset tracking arrays
func reset_question_tracking():
	question_response_times = []
	question_correctness = []
	for i in range(player_count):
		question_response_times.append(null)
		question_correctness.append(false)
		
func get_current_player_name():
	if current_player_index < player_names.size():
		return player_names[current_player_index]
	return "Player " + str(current_player_index + 1)

func next_player():
	# Move to the next player
	current_player_index = (current_player_index + 1) % player_count
	
	# If we've cycled through all players, adjust scores based on speed and move to next question
	if current_player_index == 0:
		adjust_scores_based_on_speed()
		current_question_index += 1
		
	# Reset active power-up when changing players
	active_power_up = null

func add_power_up(power_up_type):
	# Add a power-up to the current player
	power_ups[current_player_index].append(power_up_type)

func use_power_up(power_up_index):
	# Use a power-up from the current player's inventory
	if power_up_index < power_ups[current_player_index].size():
		var power_up = power_ups[current_player_index][power_up_index]
		power_ups[current_player_index].remove_at(power_up_index)
		return power_up
	return null

func get_score_summary():
	# Return a summary of all player scores
	var summary = ""
	for i in range(player_count):
		var player_name = player_names[i] if i < player_names.size() else "Player " + str(i + 1)
		summary += player_name + ": " + str(scores[i]) + "\n"
	return summary

func get_ranked_players():
	# Create pairs of [index, score]
	var player_scores = []
	for i in range(player_count):
		player_scores.append([i, scores[i]])
	
	# Sort by score in descending order
	player_scores.sort_custom(func(a, b): return a[1] > b[1])
	
	# Extract just the player indices in rank order
	var ranked_indices = []
	for pair in player_scores:
		ranked_indices.append(pair[0])
	
	return ranked_indices
