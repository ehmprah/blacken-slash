extends Node2D

var alive = true

onready var counter = $Label

func countdown(turns):
	if turns >= 0:
		counter.text = String(turns)
	else:
		counter.text = ''
