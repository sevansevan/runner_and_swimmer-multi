extends Node2D

enum Shape { CIRCLE, SQUARE, HEXAGON }
var shape : Shape = Shape.SQUARE
@onready var pool_circle = $Pool_circle
@onready var pool_square = $Pool_square
@onready var slider_v = $CanvasLayer/HSlider
@onready var text_v = $CanvasLayer/text_v
@onready var victory = $CanvasLayer/victory
@onready var turn_based_button = $CanvasLayer/turn_based_button

var turn = 1
var swimmer: Vector2
var runner: Vector2
var runner_a : float = PI / 2

var mouse_control = false
var turn_by_turn: bool = false
@export var dt = 1.0 / 180.0
var v = 3.0

var ghost_player: Vector2 = Vector2.ZERO

var vis_scale = 200.0

var paused = false
var pause_elapsed = 0.0

func runner_turn() -> bool:
	return turn%2 == 0

func swimmer_turn() -> bool:
	return !runner_turn()

func is_in_shape(vec: Vector2):
	match shape:
		Shape.CIRCLE:
			return vec.length() < 1.0
		Shape.SQUARE:
			return abs(vec.x) < 1.0 and abs(vec.y) < 1.0
		Shape.HEXAGON:
			return false

func check_victory():
	if (runner.distance_to(swimmer)) < 0.06:
		victory.visible = true
		victory.text = "Runner wins!"
		victory.add_theme_color_override("default_color", Color.ORANGE)
		paused = true
	else: if (!is_in_shape(swimmer)): #which, ironically, means that he indeed IS in shape
		victory.visible = true
		victory.text = "Swimmer wins!"
		victory.add_theme_color_override("default_color", Color.DEEP_PINK)
		paused = true

func init():
	pool_circle.visible = shape == Shape.CIRCLE;
	pool_square.visible = shape == Shape.SQUARE;
	if shape == Shape.CIRCLE:
		runner_a = PI / 2
	if shape == Shape.SQUARE:
		runner_a = 0.5
	turn = 0;
	runner = Vector2(0.0, 1.0)
	swimmer = Vector2(0.0, 0.0)
	victory.visible = false
	pause_elapsed = 0.0
	paused = false

# called by Godot frame 1
func _ready() -> void:
	init()
	pool_circle.scale = Vector2.ONE * vis_scale * 2.0
	pool_square.scale = Vector2.ONE * vis_scale * 2.0
	
# called by Godot every frame
func _process(delta: float) -> void:
	v = slider_v.value
	text_v.text = str(v)
	slider_v.release_focus()
	turn_by_turn = turn_based_button.button_pressed
	
	if (paused):
		pause_elapsed += delta
		if pause_elapsed > 1.0:
			init()
		return
		
	
	if (turn_by_turn):
		var tdt = dt * 10
		var mp = get_global_mouse_position() / vis_scale
		if (swimmer_turn()):
			var dir = mp - swimmer
			if (dir.length() > tdt):
				dir = dir.normalized() * tdt
			ghost_player = swimmer + dir
			if Input.is_action_just_pressed("lmb"):
				swimmer = ghost_player
				turn += 1
		else:
			var dist = mp.distance_to(runner)
			if (dist > v * tdt):
				dist = v * tdt
				
			var pos_1 : Vector2 = runner
			pos_1.x = cos(runner_a + dist)
			pos_1.y = - sin(runner_a + dist)
			
			var pos_2 : Vector2 = runner
			pos_1.x = cos(runner_a - dist)
			pos_1.y = - sin(runner_a - dist)
			
			if (mp.distance_to(pos_1) < mp.distance_to(pos_2)):
				ghost_player = pos_1
			else:
				ghost_player = pos_2
			if Input.is_action_just_pressed("lmb"):
				runner = ghost_player
				turn += 1
			
			
	else:
		var d : Vector2 = Vector2.ZERO
		if Input.is_action_pressed("left"):
			d.x -= 1
		if Input.is_action_pressed("right"):
			d.x += 1
		if Input.is_action_pressed("up"):
			d.y -= 1
		if Input.is_action_pressed("down"):
			d.y += 1
		
		swimmer += d.normalized() * dt
		
		var a : float = 0.0
		if Input.is_action_pressed("dpad_left"):
			a -= 1
		if Input.is_action_pressed("dpad_right"):
			a += 1
		a = a * v * dt
		runner_a += a
		
		match shape:
			Shape.CIRCLE:
				runner.x = cos(runner_a)
				runner.y = - sin(runner_a)
			Shape.SQUARE:
				if runner_a > 4.0:
					runner_a -= 4.0
				if runner_a < 0:
					runner_a += 4.0
				if (runner_a >= 0 and runner_a < 1):
					runner.x = runner_a * 2.0 - 1.0
					runner.y = -1.0
				if (runner_a >= 1 and runner_a < 2):
					runner.x = 1.0
					runner.y = (runner_a - 1) * 2.0 - 1.0
				if (runner_a >= 2 and runner_a < 3):
					runner.x = - ((runner_a - 2) * 2.0 - 1.0)
					runner.y = 1.0
				if (runner_a >= 3 and runner_a < 4):
					runner.x = - 1.0
					runner.y = - ((runner_a - 3) * 2.0 - 1.0)
	
	check_victory()
	queue_redraw()
					
func _draw() -> void:
	draw_circle(runner * vis_scale, 3.0, Color.ORANGE, true, -1.0, false)
	draw_circle(swimmer * vis_scale, 3.0, Color.DEEP_PINK, true, -1.0, true)
	if (turn_by_turn):
		draw_circle(ghost_player * vis_scale, 3.0, Color.WHITE_SMOKE, true, -1.0, true)


func _on_button_circle_button_up() -> void:
	shape = Shape.CIRCLE
	init()


func _on_button_square_button_up() -> void:
	shape = Shape.SQUARE
	init()
