extends Node

enum {
	MAIN,
	OFF,
	BOSS
}
var playing = OFF
var trackIndex = -1
var players = []
var tween
var bosstrack = preload("res://assets/music/BS-Post-Boss.mp3")
var tracks = [[],[]]

func _ready():
	var amount = 3 if OS.get_name() == 'HTML5' else 13
	for track in range(1, amount):
		tracks[0].append(load("res://assets/music/BS-" + "%03d" % track + "-Main.mp3"))
		tracks[1].append(load("res://assets/music/BS-" + "%03d" % track + "-Off.mp3"))

	tween = Tween.new()
	add_child(tween)
	for index in 3: 
		var player = AudioStreamPlayer.new()
		player.bus = 'Music'
		player.volume_db = -80.0
		add_child(player)
		players.append(player)
	players[playing].volume_db = 0.0
	players[2].stream = bosstrack


func next():
	var index = trackIndex
	while index == trackIndex:
		index = randi() % tracks[0].size()
	players[0].stream = tracks[0][index]
	players[1].stream = tracks[1][index]
	players[0].play()
	players[1].play()
	trackIndex = index


func stop():
	for index in 3:
		players[index].stop()


func fade(to, next_track = false):
	# Fade out the currently playing track
	tween.interpolate_property(players[playing], 'volume_db', 0, -80.0, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN)
	tween.start()
	yield(tween, 'tween_all_completed')
	# Start/stop the boss track
	if to == BOSS:
		players[2].play()
	else:
		players[2].stop()
	# Optionally skip to next track
	if next_track:
		next()
	# Set the now playing track
	playing = to
	# Fade in the now playing track
	tween.interpolate_property(players[playing], 'volume_db', -80.0, 0, 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()


func xfade(to):
	# Crossfade the players
	tween.interpolate_property(players[playing], 'volume_db', 0, -80.0, 0.5, Tween.TRANS_QUAD, Tween.EASE_IN)
	tween.interpolate_property(players[to], 'volume_db', -80.0, 0, 0.5, Tween.TRANS_QUAD, Tween.EASE_OUT)
	tween.start()
	# Set the now playing track
	playing = to
