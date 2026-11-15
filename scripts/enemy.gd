
extends CharacterBody2D

@export var max_health = 100
@export var speed = 100.0
@onready var anim = $AnimatedSprite2D

var health = 100
var player: CharacterBody2D

func _ready():
	add_to_group("enemy")
	health = max_health

	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed

	update_animation()
	move_and_slide()

func take_damage(amount: int):
	health -= amount

	print("Enemy HP: ", health)

	if health <= 0:
		die()

func die():
	print("Enemy died!")
	queue_free()

func update_animation():
	if anim.animation != "idle":
		anim.play("idle")

	if velocity.x > 0:
		anim.flip_h = true
	elif velocity.x < 0:
		anim.flip_h = false
