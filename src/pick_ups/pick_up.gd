extends Area2D

var player = null

@export var points: int = 1

var speed = 300

signal collected(self_ref)
var is_collected = false

func _ready():
	randomize()
	set_rotation(randf())

@onready var dir = Vector2(randf(), randf()).normalized()
@export var time_total: float = 0.2
var time_cont = 0

func _process(d):
	
	
	if time_cont < time_total:
		set_global_position(get_global_position() + dir.normalized() * 45 * d)
	
	
	time_cont += d



func _on_coin_body_entered(body):
	if body.get_groups().has("player"):
		if !is_collected:
			is_collected = true
			emit_signal("collected", self)
			hide()
			queue_free()


func _on_attract_to_player_body_entered(body):
	if body.get_groups().has("player"):
		player = body
