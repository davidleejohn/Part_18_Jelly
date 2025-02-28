extends Node2D

enum {wait, move}
var state

@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

@export var empty_spaces: PackedVector2Array
@export var ice_spaces: PackedVector2Array


signal damage_ice
signal make_ice

@onready var destroy_timer: Timer = $"../destroy_timer"
@onready var collapse_timer: Timer = $"../collapse_timer"
@onready var refill_timer: Timer = $"../refill_timer"



var possible_pieces = [
preload("res://Scenes/blue_piece.tscn"),
preload("res://Scenes/green_piece.tscn"),
preload("res://Scenes/pink_piece.tscn"),
preload("res://Scenes/light_green_piece.tscn"),
preload("res://Scenes/orange_piece.tscn"),
preload("res://Scenes/yellow_piece.tscn")
] 

var all_pieces = []

var piece_one = null
var piece_two = null
var last_place = Vector2(0,0)
var last_direction = Vector2(0,0)

var first_touch = Vector2(0,0)
var last_touch = Vector2(0,0)
var controlling = false






func _ready() -> void:
	state = move
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	spawn_ice()
	
func restricted_movement(place):
	for i in empty_spaces.size():
		if empty_spaces[i] == place:
			return true
	return false


func _process(_delta: float) -> void:
	if state == move:
		touch_input()
	
func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null);
	return array;

func spawn_pieces():
	for i in width:
		for j in height:
			if !restricted_movement(Vector2(i,j)):
				var rand = floor(randi_range(0, possible_pieces.size() - 1))
				var loops = 0
				var piece = possible_pieces[rand].instantiate()
				while(match_at(i,j,piece.color) && loops < 100):
					rand = floor(randi_range(0, possible_pieces.size() - 1))
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.set_position(grid_to_pixel(i, j))
				all_pieces[i][j] = piece
			
func spawn_ice():
	for i in ice_spaces.size():
		emit_signal("make_ice", ice_spaces[i])
			
func match_at(i, j, color):
	if i > 1:
		if all_pieces[i - 1][j] != null && all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color && all_pieces[i - 2][j].color == color:
				return true
	if j > 1:
		if all_pieces[i ][j - 1] != null && all_pieces[i ][j - 2] != null:
			if all_pieces[i ][j - 1].color == color && all_pieces[i][j - 2].color == color:
				return true
			
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column;
	var new_y = y_start + -offset * row;
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x =  round((pixel_x - x_start)/offset)
	var new_y = round((pixel_y - y_start)/-offset)
	return Vector2(new_x, new_y)
	
func is_in_grid(grid_position):
	if grid_position.x >= 0 && grid_position.x < width:
		if grid_position.y >= 0 && grid_position.y < height:
			return true
	return false
	
func touch_input():
	var mouse = get_global_mouse_position()
	if Input.is_action_just_pressed("ui_touch"):
		if is_in_grid(pixel_to_grid(mouse.x, mouse.y)):
			first_touch = pixel_to_grid(mouse.x, mouse.y)
			controlling = true

	if Input.is_action_just_released("ui_touch"):
		if is_in_grid(pixel_to_grid(mouse.x, mouse.y)) && controlling:
			controlling = false
			last_touch = pixel_to_grid(mouse.x, mouse.y)
			touch_difference(first_touch, last_touch)
			
func swap_pieces(column, row, direction):
	var first_piece = all_pieces [column][row]
	var other_piece = all_pieces [column + direction.x][row + direction.y]
	if first_piece != null && other_piece != null:
		store_info(first_piece, other_piece, Vector2(column, row), direction)
		state = wait
		all_pieces[column][row] = other_piece
		all_pieces[column + direction.x][row + direction.y] = first_piece
		first_piece.move(grid_to_pixel(column + direction.x , row + direction.y))
		other_piece.move(grid_to_pixel(column,row))
		find_matches()
		
func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null && piece_two != null:
		swap_pieces(last_place.x,last_place.y, last_direction)
		piece_one = null
		piece_two = null
		last_place = null
		last_direction = null
		print("unswapping!")
	state=move

func touch_difference(grid1, grid2):
	var difference = grid2 - grid1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid1.x, grid1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid1.x, grid1.y, Vector2(-1, 0))
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid1.x, grid1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid1.x, grid1.y, Vector2(0, -1))
				
func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				if i > 0 && i < width-1:
					if all_pieces[i-1][j] != null && all_pieces[i+1][j] != null:
						if all_pieces[i-1][j].color == current_color && all_pieces[i+1][j].color == current_color:
							create_match_h(i,j)
				if j > 0 && j < height-1:
					if all_pieces[i][j-1] != null && all_pieces[i][j+1] != null:
						if all_pieces[i][j-1].color == current_color && all_pieces[i][j+1].color == current_color:
							create_match_v(i,j)
							
	destroy_timer.start()

func create_match_h(i,j):
	all_pieces[i-1][j].matched = true
	all_pieces[i-1][j].dim()
	all_pieces[i][j].matched = true
	all_pieces[i][j].dim()
	all_pieces[i+1][j].matched = true
	all_pieces[i+1][j].dim()
	return

func create_match_v(i,j):
	all_pieces[i][j-1].matched = true
	all_pieces[i][j-1].dim()
	all_pieces[i][j].matched = true
	all_pieces[i][j].dim()
	all_pieces[i][j+1].matched = true
	all_pieces[i][j+1].dim()
	return
	
func destroy_matched():
	var match_detect = false
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					emit_signal("damage_ice", Vector2(i,j))
					match_detect = true
					all_pieces[i][j].queue_free()
					all_pieces[i][j] = null
	if match_detect == true:
		collapse_timer.start()
	else:
		swap_back()

func collapse_column():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null && !restricted_movement(Vector2(i,j)):
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i,j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	refill_timer.start()
	
func refill_column():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null && !restricted_movement(Vector2(i,j)):
				var rand = floor(randi_range(0, possible_pieces.size() - 1))
				var loops = 0
				var piece = possible_pieces[rand].instantiate()
				while(match_at(i,j,piece.color) && loops < 100):
					rand = floor(randi_range(0, possible_pieces.size() - 1))
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.set_position(grid_to_pixel(i, j - y_offset))
				piece.move(grid_to_pixel(i,j))
				all_pieces[i][j] = piece
	after_refill()

func after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if match_at(i,j, all_pieces[i][j].color):
					find_matches()
					destroy_timer.start()
					return
	state = move
	
func _on_destroy_timer_timeout() -> void:
	destroy_matched()

func _on_collapse_timer_timeout() -> void:
	collapse_column()

func _on_refill_timer_timeout() -> void:
	refill_column()
