extends Sprite2D

var bullet_speed = 5

func _ready() -> void:
	scale = Vector2(.1, .1)


func _process(_delta: float) -> void:
	position.x += bullet_speed
