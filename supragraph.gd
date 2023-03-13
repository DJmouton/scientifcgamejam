extends Node2D

@export var temp_init: float = 0.5
@export var pres_init: float = 0.5
@export var max_speed: float = 100
@export var slider_keyboard_speed: float = 0.5
@export_category("Parameter Evolution Speed")
@export var temperature_increase_factor: float = 0.1
@export var temperature_decrease_factor: float = 0.5
@export var helium_decrease_factor: float = 0.05
@export var speed_increase_factor: float = 0
@export var speed_decrease_factor: float = 1
@export var pressure_increase_speed: float = 0.2 
@export var pressure_decrease_speed: float = 0.05
@export_category("Train")
@export var background_speed_factor: float = 10
@export var supra_speed: float = 200
@export var max_speed_supra_leeway = 0.98
@export var star_background: Texture2D
@export var supra_background: Texture2D
@export var start_speed_ratio: float = 0.5
@export var slow_mo_speed: float = 30
@export var slow_mo_time: float = 2
@export var time_on_station: float = 1.5
@export var wheel1_sprite: Texture2D
@export var wheel2_sprite: Texture2D
@export var wheel3_sprite: Texture2D
@export var wheel4_sprite: Texture2D
@export var wheel5_sprite: Texture2D
@export var helium_refuel_amount: float = 0.25
@export_category("Terrain")
@onready var timer_random_interval: Vector2 = Vector2(10,25)
@export var graph1_sprite: Texture2D
@export var graph2_sprite: Texture2D
@export var graph3_sprite: Texture2D
@export var graph4_sprite: Texture2D
@export var graph5_sprite: Texture2D
@export var station1_sprite: Texture2D
@export var station2_sprite: Texture2D
@export var station3_sprite: Texture2D
@export var station4_sprite: Texture2D
@export var station5_sprite: Texture2D
@export var spark_sprite1: Texture2D
@export var spark_sprite2: Texture2D
@export var spark_sprite3: Texture2D
@export var spark_sprite4: Texture2D
@export var glow1: Texture2D
@export var glow2: Texture2D
@export var glow3: Texture2D
@export var glow4: Texture2D
@export var glow5: Texture2D


var graph_origin: Vector2
var graph_axis_length: Vector2
var temperature: float = 0
var pressure: float = 0
var speed: float = 0
var supra: bool = false
var helium: float = 1
var injecting_helium: bool = false
var distance: float = 0
var is_background_supra: bool = false
var current_area: Area2D
var train_offset: Vector2
var slow_mo: bool = false
var speed_before_slow_mo: float = 0
var slow_mo_timer: float = 0
var station_needs_updating: bool = false
var wheels_need_updating: bool = false
var station_texture: Texture2D
var wheels_texture: Texture2D
var keyboard_injecting_helium: bool = false
var do_mid_slow_mo: bool = false
var station_counter: int = 0
var game_over: bool = false
var current_glow: Texture2D


@onready var pres_slider = $Graph/UI/PressureSlider
@onready var cursor = $Graph/Cursor
@onready var origin = $Graph/GraphMarkers/Origin
@onready var temp_max_axis = $Graph/GraphMarkers/TemperatureMaxAxis
@onready var pres_max_axis = $Graph/GraphMarkers/PressureMaxAxis
@onready var helium_bar = $Graph/UI/HeliumBar
@onready var camera = $Camera2D
@onready var background = $Background
@onready var graph1_area = $Graph/Graphs/GraphArea2D
@onready var graph2_area = $Graph/Graphs/GraphArea2D2
@onready var graph3_area = $Graph/Graphs/GraphArea2D3
@onready var graph4_area = $Graph/Graphs/GraphArea2D4
@onready var graph5_area = $Graph/Graphs/GraphArea2D5
@onready var graph_sprite = $Graph/Graphs/GraphSprite
@onready var timer = $Graph/Graphs/Timer
@onready var slider_nob = $Graph/UI/SliderNob
@onready var slider_x_start = slider_nob.position.x
@onready var slider_start = $Graph/SliderMarkers/Start
@onready var slider_end = $Graph/SliderMarkers/End
@onready var slider_x_range = slider_end.position.x - slider_start.position.x
@onready var train_min_speed = $Train/TrainMarkers/MinSpeed
@onready var train_max_speed = $Train/TrainMarkers/MaxSpeed
@onready var train_supra = $Train/TrainMarkers/Supra
@onready var train_speed_ratio = train_max_speed.position.x - train_min_speed.position.x
@onready var train_supra_ratio = train_supra.position.x - train_min_speed.position.x
@onready var train_supra_height = train_supra.position.y - train_min_speed.position.y
@onready var train_body = $Train/Body
@onready var train_body_init = train_body.position
@onready var train_sprite_normal = $Train/Body/Normal
@onready var train_sprite_supra = $Train/Body/Supra
@onready var train_station = $TrainStation
@onready var train_station_range = train_station.position.x
@onready var station_sprite = $TrainStation/Sprite2D
@onready var wheels_sprite = $Train/Body/Wheels
@onready var heating_up = $Train/Body/Wheels/Sprite2D
@onready var sparks = $Train/Body/Wheels/Sparks
@onready var music_danger = $SFX/MusicDanger
@onready var music_supra = $SFX/MusicSupra
@onready var slow_mo_fade_in = $SFX/SlowMoFadeIn
@onready var slow_mo_fade_out = $SFX/SlowMoFadeOut
@onready var bad_brakes = $SFX/BadBrakes
@onready var glow = $Train/Body/Glow
@onready var to_supra = $SFX/ToSupra
@onready var from_supra = $SFX/FromSupra


func _ready():
	get_tree().paused = true
	music_danger.play()
	temperature = temp_init
	pressure = pres_init
	speed = start_speed_ratio * max_speed
	slow_mo_timer = slow_mo_time
	pres_slider.value = pres_init
	graph_origin = origin.position
	graph_axis_length = Vector2(pres_max_axis.position.x - origin.position.x, temp_max_axis.position.y - origin.position.y)
	change_graph(randi_range(1,5))
	station_sprite_update()
	wheels_sprite_update()
	timer.set_wait_time(randi_range(timer_random_interval.x, timer_random_interval.y))
	timer.start()


func update_cursor_pos():
	var x = graph_origin.x + pressure * graph_axis_length.x
	var y = graph_origin.y + temperature * graph_axis_length.y
	cursor.position = Vector2(x, y)


func temp_decrease_formula():
	return temperature * temperature_decrease_factor


func update_parameters(delta):
	if (injecting_helium || Input.is_action_pressed("press_helium_button")) && helium > 0:
		temperature = max(0, temperature - temp_decrease_formula()* delta)
		helium = max(0, helium - helium_decrease_factor * delta)
	else:
		if !slow_mo:
			temperature = min(1, temperature + temperature_increase_factor * delta)
	if !slow_mo:
		if supra:
			speed = min(max_speed, speed + speed_increase_factor * delta)
		else:
			speed = max(0, speed - speed_decrease_factor * delta)
	
	if pressure >= pres_slider.value:
		pressure = max(pres_slider.value, pressure - pressure_decrease_speed * delta)
	else:
		pressure = min(pres_slider.value, pressure + pressure_increase_speed * delta)


func update_background(delta):
	if is_background_supra:
		background.region_rect.position.x += supra_speed * delta
		if speed < max_speed * max_speed_supra_leeway:
			is_background_supra = false
			background.texture = star_background
	else:
		background.region_rect.position.x += speed * background_speed_factor * delta
		if speed >= max_speed:
			is_background_supra = true
	if !slow_mo:
		update_train_sprite()


func update_train_sprite():
	if is_background_supra:
		train_sprite_normal.hide()
		train_sprite_supra.show()
		glow.show()
		glow.texture = current_glow
	else:
		train_sprite_normal.show()
		train_sprite_supra.hide()
		glow.hide()


func change_graph(index: int):
	var graph_texture: Texture2D
	match index:
		1:
			graph_texture = graph1_sprite
			station_texture = station1_sprite
			wheels_texture = wheel1_sprite
			current_area = graph1_area
			current_glow = glow1
			graph1_area.monitoring = true
			graph2_area.monitoring = false
			graph3_area.monitoring = false
			graph4_area.monitoring = false
			graph5_area.monitoring = false
		2:
			graph_texture = graph2_sprite
			current_area = graph2_area
			station_texture = station2_sprite
			wheels_texture = wheel2_sprite
			current_glow = glow2
			graph1_area.monitoring = false
			graph2_area.monitoring = true
			graph3_area.monitoring = false
			graph4_area.monitoring = false
			graph5_area.monitoring = false
		3:
			graph_texture = graph3_sprite
			current_area = graph3_area
			station_texture = station3_sprite
			wheels_texture = wheel3_sprite
			current_glow = glow3
			graph1_area.monitoring = false
			graph2_area.monitoring = false
			graph3_area.monitoring = true
			graph4_area.monitoring = false
			graph5_area.monitoring = false
		4:
			graph_texture = graph4_sprite
			current_area = graph4_area
			station_texture = station4_sprite
			wheels_texture = wheel4_sprite
			current_glow = glow4
			graph1_area.monitoring = false
			graph2_area.monitoring = false
			graph3_area.monitoring = false
			graph4_area.monitoring = true
			graph5_area.monitoring = false
		5:
			graph_texture = graph5_sprite
			current_area = graph5_area
			station_texture = station5_sprite
			wheels_texture = wheel5_sprite
			current_glow = glow5
			graph1_area.monitoring = false
			graph2_area.monitoring = false
			graph3_area.monitoring = false
			graph4_area.monitoring = false
			graph5_area.monitoring = true
	graph_sprite.texture = graph_texture
	station_needs_updating = true
	wheels_need_updating = true


func station_sprite_update():
	station_sprite.texture = station_texture
	station_needs_updating = false


func wheels_sprite_update():
	wheels_sprite.texture = wheels_texture
	wheels_need_updating = false


func update_train():
	if !slow_mo:
		if is_background_supra:
			train_body.position.x = train_body_init.x + train_speed_ratio
		else:
			train_body.position.x = train_body_init.x + speed / max_speed * train_speed_ratio
		train_body.position.y = train_body_init.y + speed / max_speed * -15


func _process(delta):
	if !game_over:
		update_cursor_pos()
		update_parameters(delta)
		update_background(delta)
		update_train()
		
		if Input.is_action_pressed("add_pressure"):
			pres_slider.value = pres_slider.value + delta * slider_keyboard_speed
		if Input.is_action_pressed("reduce_pressure"):
			pres_slider.value = pres_slider.value - delta * slider_keyboard_speed
		
		slow_mo_timer += delta / slow_mo_time
		
		train_station.position.x = lerp(train_station_range, -train_station_range, slow_mo_timer / slow_mo_time)
		
		if speed < max_speed * 0.50:
			heating_up.scale.y = (max_speed/2 - speed)/max_speed
			sparks.show()
			if !bad_brakes.playing:
				bad_brakes.play()
			match(randi_range(1,4)):
				1:
					sparks.texture = spark_sprite1
				2:
					sparks.texture = spark_sprite1
				3:
					sparks.texture = spark_sprite3
				4:
					sparks.texture = spark_sprite4
		else:
			heating_up.scale.y = 0
			sparks.hide()
			if bad_brakes.playing:
				bad_brakes.stop()
		
		if do_mid_slow_mo && train_station.position.x < 0:
			do_mid_slow_mo = false
			wheels_sprite_update()
			station_counter += 1
		
		if slow_mo && train_station.position.x < -train_station_range:
			speed = speed_before_slow_mo
			station_sprite_update()
			helium += helium_refuel_amount
			timer.set_wait_time(randi_range(timer_random_interval.x, timer_random_interval.y))
			timer.start()
			slow_mo = false
		
		helium_bar.value = helium
		slider_nob.position.x = slider_x_start + pres_slider.value * slider_x_range
		if speed <= 0:
			game_overer()


func game_overer():
	$Graph.set_process(false)
	$Graph.hide()
	$Rail.set_process(false)
	$Rail.hide()
	$GameOverScreen.set_process(true)
	$GameOverScreen.show()
	$GameOverScreen/RichTextLabel3.text = str(station_counter)


func _on_area_2d_area_entered(_area):
	supra = true


func _on_area_2d_area_exited(_area):
	supra = false


func _on_helium_button_button_down():
	injecting_helium = true


func _on_helium_button_button_up():
	injecting_helium = false


func _on_timer_timeout():
	if speed < slow_mo_speed:
		timer.set_wait_time(1)
		timer.start
	else:
		change_graph(randi_range(1, 5))
		slow_mo = true
		do_mid_slow_mo = true
		speed_before_slow_mo = speed
		speed = slow_mo_speed
		slow_mo_timer = 0
		slow_mo_fade_in.play()
		
#	if slow_mo:
#		speed = speed_before_slow_mo
#		slow_mo = false
#		print("slow mo END")
#		update_train_sprite()
#		timer.set_wait_time(randi_range(timer_random_interval.x, timer_random_interval.y))
#		timer.start()
#		
#	else:
#		if speed < slow_mo_speed:
#			timer.set_wait_time(1)
#			timer.start
#		else:
#			change_graph(randi_range(1, 4))
#			slow_mo = true
#			print("slow mo START")
#			speed_before_slow_mo = speed
#			slow_mo_timer = 0
#			timer.set_wait_time(1)
#			timer.start


func _on_button_button_down():
	get_tree().reload_current_scene()


func _on_slow_mo_fade_in_finished():
	slow_mo_fade_out.play()


func _on_music_danger_finished():
	music_danger.play()


func _on_button_pressed():
	get_tree().paused = false
	$StaticUI/TutoWindow.hide()
