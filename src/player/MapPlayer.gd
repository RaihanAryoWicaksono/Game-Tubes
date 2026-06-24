extends CharacterBody2D

var controls = []
var commands = {
	"move_jump" : {
		"flag" : false,
		"input" : [KEY_K, JOY_BUTTON_A],
		"id" : "jump"
	},
	"look_up" : {
		"flag" : false,
		"input" : [KEY_W, JOY_BUTTON_DPAD_UP],
		"id" : "look_up"
	},
	"look_down" : {
		"flag" : false,
		"input" : [KEY_S, JOY_BUTTON_DPAD_DOWN],
		"id" : "look_down"
	},
	"shoot" : {
		"flag" : false,
		"input" : [KEY_J, JOY_BUTTON_X],
		"id" : "shoot"
	},
	"move_left" : {
		"flag" : false,
		"input" : [KEY_A, JOY_BUTTON_DPAD_LEFT],
		"id" : "left"
	},
	"move_right" : {
		"flag" : false,
		"input" : [KEY_D, JOY_BUTTON_DPAD_RIGHT],
		"id" : "right"
	},
}

func _ready():
	
	$image/gun/gun/anim.play("idle")
	
	change_anim("idle")
	
	for cmd in commands.values():
		for input in cmd.input:
			controls.append(input)
	
var canJump = false
var canMove = true


func _input(ev):
	
	
	if !isDying:
		if ev is InputEventKey:
			
			if controls.has(ev.keycode):
				
				for cmd in commands.values():
					if cmd.input.has(ev.keycode):
						
						if !cmd.flag and ev.pressed:
							just_pressed_events(cmd.id)
						if cmd.flag and !ev.pressed:
							just_released_events(cmd.id)
						cmd.flag = ev.pressed
		
		if ev is InputEventJoypadButton:
			if controls.has(ev.button_index):
				
				for cmd in commands.values():
					if cmd.input.has(ev.button_index):
						
						if !cmd.flag and ev.pressed:
							just_pressed_events(cmd.id)
						if cmd.flag and !ev.pressed:
							just_released_events(cmd.id)
					cmd.flag = ev.pressed

var speed = Vector2(100, 0)
var isDying = false
var currentVelocity = Vector2(0, 1)

func _physics_process(d):
	
	if !isDying:
		
		currentVelocity = Vector2(0, 1)
		
		if canMove:
			if commands.move_left.flag:
				currentVelocity.x -= 1
			if commands.move_right.flag:
				currentVelocity.x += 1
		set_velocity(speed * currentVelocity)
		set_up_direction(Vector2(0, -1))
		move_and_slide()
		var movement = velocity
		
		if !is_on_floor():
			speed.y += 350 * d
		else:
			if shoot_down:
				shoot_down = false
				$image/gun/gun/anim.play("idle")
			canJump = true
			currentJumps = 0
			if !commands.move_jump.flag:
				speed.y = 0
		
		if movement.y == 0:
			if movement.x == 0:
				change_anim("idle")
			else:
				change_anim("run")
		else:
			
			if commands.look_down.flag:
				$image/gun/gun/anim.play("look_down")
				shoot_down = true
			
			if speed.y > 0:
				change_anim("jump_down")
			else:
				change_anim("jump_up")
		
		if movement.x < 0:
			change_facing("left")
		elif movement.x > 0:
			change_facing("right")
		
		if is_on_ceiling():
			speed.y += 100
		
		if commands.shoot.flag and shoot_count > shoot_timer:
			shoot()
	
		if shoot_count < shoot_timer:
			shoot_count += d
		
func just_pressed_events(cmd_id):
	
	match(cmd_id):
		"jump":
			if canJump:
				jump()
				change_anim("jump_up")
		"look_up":
			$image/gun/gun/anim.play("look_up")
			shoot_up = true
		"look_down":
			if !speed.y == 0:
				$image/gun/gun/anim.play("look_down")
				shoot_down = true
		"shoot":
			shoot()
func just_released_events(cmd_id):
	
	match(cmd_id):
		"look_up":
			$image/gun/gun/anim.play("idle")
			shoot_up = false
		"look_down" :
			$image/gun/gun/anim.play("idle")
			shoot_down = false


var currentState = ""
var currentFacing = "right"

func change_facing(dir):
	
	if currentFacing != dir:
		if dir == "right":
			$image.set_scale(Vector2(1, 1))
		elif dir == "left":
			$image.set_scale(Vector2(-1, 1))
		
		currentFacing = dir
		

var currentJumps = 0
var maxJumps = 2

func jump():
	currentJumps += 1 
	$jump_stream.play()
	speed.y = -150
	if currentJumps == maxJumps:
		canJump = false

func change_anim(newState):
	
	if isDying:
		pass
	if currentState != newState and $image/anim.has_animation(newState):
		currentState = newState
		if newState == "die":
			stopCommands()
		if $image/anim.current_animation != "hurt":
			$image/anim.play(newState)
		

func stopCommands():
	
	isDying = true
	
	for cmd in commands.values():
		cmd.flag = false
	

func setMovable(value : bool):
	
	canMove = value
	
	if !value:
		for cmd in commands.values():
			cmd.flag = false

func go_to_position(vec):
	pass

@onready var bullet_spawn = $image/gun/gun/bullet_spawn

@export var shoot_timer: float = 0.20
var shoot_count = 1.0

var shoot_down = false
var shoot_up = false

@export var bullet_reference: PackedScene

signal shoot_fired(instance, start_pos, direction)

func shoot():
	
	if shoot_timer <= shoot_count:
		shoot_count = 0
		
		var dir
		if shoot_up:
			dir = Vector2(0, -1.0).rotated(randf() * 0.1 - 0.05)
		elif shoot_down:
			dir = Vector2(0, 1.0).rotated(randf() * 0.1 - 0.05)
		else:
			dir = Vector2(1.0, 0).rotated(randf() * 0.1 - 0.05)
			if currentFacing == "left":
				dir = -dir
		$shoot_stream.play()
		emit_signal("shoot_fired", bullet_reference.instantiate(), bullet_spawn.get_global_position(), dir)
	


func _on_bounce_checker_area_entered(area):
	if area.get_groups().has("bounce"):
		if $bounce_checker.get_global_position().y > area.get_global_position().y:
			$jump_stream.play()
			speed.y = -120

var health = 4

signal game_over()
signal health_down()

func get_hurt():
	if not $hitbox.monitoring:
		pass
	else:
		$hitbox.set_deferred("monitoring", false)
		health -= 1
		if health <= 0:
			change_anim("die")
			$death_stream.play()
		else:
			$image/anim.play("hurt")
			$hurt_player.play("hurt")
			emit_signal("health_down")
			$hurt_stream.play()


func play_pick_up_sound():
	
	$collect_stream.stop()
	$collect_stream.play()
	

func _on_anim_animation_finished(anim_name):
	if anim_name == "hurt":
		change_anim("idle")
	elif anim_name == "die":
		emit_signal("game_over")


func _on_hitbox_body_entered(body):
	if body.get_groups().has("enemy"):
		get_hurt()

func _on_hurt_player_animation_finished(anim_name):
	if anim_name == "hurt":
		$hitbox.set_deferred("monitoring", true)
