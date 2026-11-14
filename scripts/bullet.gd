extends Sprite2D

var bullet_speed = 600.0
var direction = Vector2.ZERO

func _ready() -> void:
	scale = Vector2(0.1, 0.1)

func setup(start_pos: Vector2, target_pos: Vector2) -> void:
	global_position = start_pos
	direction = (target_pos - start_pos).normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * bullet_speed * delta
