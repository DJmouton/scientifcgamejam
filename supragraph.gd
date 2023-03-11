extends Node2D

@export var temp_init: float = 0.5
@export var pres_init: float = 0.5
@export var max_speed: float = 100
@export var color_collision_in: Color
@export var color_collision_out: Color
@export_category("Parameter Evolution Speed:")
@export var temperature_increase_factor: float = 0.1
@export var temperature_decrease_factor: float = 0.5
@export var helium_decrease_factor: float = 0.05
@export var speed_increase_factor: float = 0.5 
@export var speed_decrease_factor: float = 1
@export var pressure_increase_speed: float = 0.2 
@export var pressure_decrease_speed: float = 0.05
@export_category("Train and Paralax:")
@export var paralax_speed_front: float = 12
@export var background_speed_factor: float = 10
@export var supra_speed: float = 200
@export var star_background: Texture2D
@export var supra_background: Texture2D
@export_category("Terrain")
@onready var timer_random_interval: Vector2 = Vector2(3, 10)
@export var graph1_sprite: Texture2D
@export var graph2_sprite: Texture2D
@export var graph3_sprite: Texture2D
@export var graph4_sprite: Texture2D


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


@onready var pres_slider = $Graph/UI/PressureSlider
@onready var cursor = $Graph/Cursor
@onready var origin = $Graph/GraphMarkers/Origin
@onready var temp_max_axis = $Graph/GraphMarkers/TemperatureMaxAxis
@onready var pres_max_axis = $Graph/GraphMarkers/PressureMaxAxis
@onready var col_check_sprite = $Graph/CollisionCheckSprite
@onready var speed_bar = $Graph/UI/SpeedBar
@onready var helium_bar = $Graph/UI/HeliumBar
@onready var camera = $Camera2D
@onready var background = $Background
@onready var graph1_area = $Graph/Graphs/GraphArea2D
@onready var graph2_area = $Graph/Graphs/GraphArea2D2
@onready var graph3_area = $Graph/Graphs/GraphArea2D3
@onready var graph4_area = $Graph/Graphs/GraphArea2D4
@onready var graph_label = $Graph/UI/GraphLabel
@onready var graph_sprite = $Graph/Graphs/GraphSprite
@onready var timer = $Graph/Graphs/Timer


func _ready():
	temperature = temp_init
	pressure = pres_init
	pres_slider.value = pres_init
	speed_bar.max_value = max_speed
	graph_origin = origin.position
	graph_axis_length = Vector2(pres_max_axis.position.x - origin.position.x, temp_max_axis.position.y - origin.position.y)
	col_check_sprite.modulate = color_collision_out
	speed_bar.max_value = max_speed
	_on_timer_timeout()


func update_cursor_pos():
	var x = graph_origin.x + pressure * graph_axis_length.x
	var y = graph_origin.y + temperature * graph_axis_length.y
	cursor.position = Vector2(x, y)


func temp_decrease_formula():
	return temperature * temperature_decrease_factor


func update_parameters(delta):
	if injecting_helium && helium > 0:
		temperature = max(0, temperature - temp_decrease_formula()* delta)
		helium = max(0, helium - helium_decrease_factor * delta)
	else:
		temperature = min(1, temperature + temperature_increase_factor * delta)
	
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
		if speed < max_speed:
			is_background_supra = false
			background.texture = star_background
	else:
		background.region_rect.position.x += speed * background_speed_factor * delta
		if speed >= max_speed:
			is_background_supra = true
			background.texture = supra_background


func change_graph(index: int):
	match index:
		1:
			graph_label.text = "CeCu2Si2"
			graph_sprite.texture = graph1_sprite
			current_area = graph1_area
			graph1_area.monitoring = true
			graph2_area.monitoring = false
			graph3_area.monitoring = false
			graph4_area.monitoring = false
		2:
			graph_label.text = "Fer"
			graph_sprite.texture = graph2_sprite
			current_area = graph2_area
			graph1_area.monitoring = false
			graph2_area.monitoring = true
			graph3_area.monitoring = false
			graph4_area.monitoring = false
		3:
			graph_label.text = "Graphène"
			graph_sprite.texture = graph3_sprite
			current_area = graph3_area
			graph1_area.monitoring = false
			graph2_area.monitoring = false
			graph3_area.monitoring = true
			graph4_area.monitoring = false
		4:
			graph_label.text = "UTe2"
			graph_sprite.texture = graph4_sprite
			current_area = graph4_area
			graph1_area.monitoring = false
			graph2_area.monitoring = false
			graph3_area.monitoring = false
			graph4_area.monitoring = true


func _process(delta):
	update_cursor_pos()
	update_parameters(delta)
	update_background(delta)
	helium_bar.value = helium
	speed_bar.value = speed


func _on_area_2d_area_entered(_area):
	col_check_sprite.modulate = color_collision_in
	supra = true


func _on_area_2d_area_exited(_area):
	col_check_sprite.modulate = color_collision_out
	supra = false


func _on_helium_button_button_down():
	injecting_helium = true


func _on_helium_button_button_up():
	injecting_helium = false


func _on_timer_timeout():
	change_graph(randi_range(1, 4))
	timer.set_wait_time(randi_range(timer_random_interval.x, timer_random_interval.y))
	timer.start()
