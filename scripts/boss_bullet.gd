extends Area2D

var bullet_speed = 140.0
var direction = Vector2.ZERO
var damage = 12
var lifetime = 4.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func setup(start_pos: Vector2, target_pos: Vector2, speed: float = 140.0, dmg: int = 12) -> void:
	global_position = start_pos
	bullet_speed = speed
	damage = dmg
	direction = (target_pos - start_pos).normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * bullet_speed * delta

func _hit_player(target: Node) -> void:
	if target and target.has_method("take_damage"):
		target.take_damage(damage)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_hit_player(body)

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent and parent.is_in_group("player"):
		_hit_player(parent)
