extends Node2D

@export var health: int

func _ready() -> void:
	pass # Replace with function body.

func take_damage(damage):
	health -= damage
