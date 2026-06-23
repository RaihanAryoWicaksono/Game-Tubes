extends Control


func _ready():
	randomize()
	
	$entities.connect("enemy_to_connect", Callable(self, "connect_enemy_to_money"))
	$entities.connect("new_wave", Callable(self, "update_waves"))
	
	$entities/MapPlayer.connect("shoot_fired", Callable(self, "create_bullet"))
	$entities/MapPlayer.connect("game_over", Callable(self, "game_over"))
func connect_enemy_to_money(enemy):
	enemy.connect("explode_coins", Callable(self, "create_many_coins"))

@export var smallCoin_ref: PackedScene
@export var bigCoin_ref: PackedScene

func create_many_coins(pos, amount):
	
	for i in range(amount):
		var coin = bigCoin_ref.instantiate()
		if !randi()%5 != 0:
			coin = smallCoin_ref.instantiate()
		create_coin(coin, pos)
	

func create_coin(coin, start_pos):
	
	$coins.add_child(coin)
	
	coin.set_position(start_pos)
	coin.connect("collected", Callable(self, "get_coin_points"))
	

var points = 0

var sound_stack = []

func get_coin_points(coin):
	
	points += coin.points
	$entities/MapPlayer.play_pick_up_sound()
	$UI/Points/value.set_text(str(points))

func create_bullet(bullet_instance, start_pos, dir):
	
	$bullets.add_child(bullet_instance)
	
	bullet_instance.set_bullet(start_pos, dir)
	bullet_instance.connect("enemy_hurt", Callable(self, "damage_enemy"))

func damage_enemy(bullet, enemy):
	enemy.health -= 1
	if enemy.health <= 0:
		enemy.die()
	else:
		enemy.knockback(bullet.dir)

func retry():
	get_tree().change_scene_to_file("res://src/Levels/Level_0.tscn")
func update_waves(wave):
	
	$UI/Waves/value.set_text(str(wave))


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func game_over():
	
	if score.best_score.points < points:
		score.best_score = {"points" : points, "waves" : $entities.wave_defeated}
	
	get_tree().change_scene_to_file("res://src/Menus/GameOver.tscn")
	

func _on_music_stream_finished():
	$music_stream.play()
