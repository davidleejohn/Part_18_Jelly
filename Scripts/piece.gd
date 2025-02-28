extends Node2D

var matched = false

@export var color: String;

func _ready() -> void:
	pass 

func move(target):
	var tween: Tween = create_tween()
	tween.tween_property(self,"position",target, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func dim():
	$Sprite2D.modulate.a = .5
