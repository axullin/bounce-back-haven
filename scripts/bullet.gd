
extends Area2D

var bullet_speed = 600.0
var direction = Vector2.ZERO
var damage = 20

func _ready() -> void:
	$Sprite2D.scale = Vector2(2, 2)
	body_entered.connect(_on_body_entered)

func setup(start_pos: Vector2, target_pos: Vector2) -> void:
	global_position = start_pos
	direction = (target_pos - start_pos).normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * bullet_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		body.take_damage(damage)
		queue_free()
