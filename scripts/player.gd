extends CharacterBody2D


const SPEED = 200.0
const JUMP_VELOCITY = -200.0
var bt
@onready var bullet = preload("res://scenes/bullet.tscn")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	shoot()

func shoot():
	if Input.is_action_just_pressed('shoot'):
		bt = bullet.instantiate()
		get_parent().add_child(bt)
		bt.global_position = $Node2D.global_position

func _on_pickup_area_area_entered(area: Area2D) -> void:
	if area.is_in_group("object") and not $HeldObject.visible:
		area.queue_free()
		$HeldObject.visible = true
