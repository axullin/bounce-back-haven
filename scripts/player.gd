extends CharacterBody2D

enum Weapon {
	PISTOL,
	SHOTGUN
}

const SPEED = 200.0
const JUMP_VELOCITY = -200.0
const MIN_JUMP_VELOCITY = -200.0
const MAX_JUMP_VELOCITY = -500.0
const MAX_CHARGE_TIME = 1.5
const INVULN_TIME = 0.6

signal health_changed(new_health)

@export var max_health = 100

var bt
var current_weapon = Weapon.PISTOL
var charge_time = 0.0
var is_charging = false
var health = 100
var invulnerable = false

@onready var bullet = preload("res://scenes/bullet.tscn")
@onready var anim = $AnimatedSprite2D

func _ready():
	health = max_health
	health_changed.emit(health)

func _physics_process(delta: float) -> void:
	if is_on_floor() and Input.is_action_pressed("charge_jump"):
		is_charging = true
		charge_time = min(charge_time + delta, MAX_CHARGE_TIME)

	if is_charging and Input.is_action_just_released("charge_jump"):
		var charge_ratio = charge_time / MAX_CHARGE_TIME
		velocity.y = lerp(MIN_JUMP_VELOCITY, MAX_JUMP_VELOCITY, charge_ratio)
		is_charging = false
		charge_time = 0.0

	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("move_left", "move_right")

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	handle_weapon_input()
	update_animation()

func handle_weapon_input():
	if Input.is_action_just_pressed("weapon_pistol"):
		current_weapon = Weapon.PISTOL

	if Input.is_action_just_pressed("weapon_shotgun"):
		current_weapon = Weapon.SHOTGUN

	if Input.is_action_just_pressed("shoot"):
		match current_weapon:
			Weapon.PISTOL:
				pistol_shoot()
			Weapon.SHOTGUN:
				shotgun_shoot()

func pistol_shoot():
	var target_pos = get_global_mouse_position()
	var spawn_pos = $BulletSpawn.global_position

	bt = bullet.instantiate()
	get_parent().add_child(bt)
	bt.setup(spawn_pos, target_pos)

func shotgun_shoot():
	var target_pos = get_global_mouse_position()
	var spawn_pos = $BulletSpawn.global_position
	var spread = [-0.2, -0.1, 0.0, 0.1, 0.2]

	for angle in spread:
		var aim = (target_pos - spawn_pos).normalized()
		var pellet_target = spawn_pos + aim.rotated(angle) * 1000.0

		bt = bullet.instantiate()
		get_parent().add_child(bt)
		bt.setup(spawn_pos, pellet_target)

func update_animation():
	if abs(velocity.x) > 0:
		anim.play("walk")
	else:
		anim.play("idle")

	if velocity.x > 0:
		anim.flip_h = true
	elif velocity.x < 0:
		anim.flip_h = false

func take_damage(amount: int):
	if invulnerable or health <= 0:
		return

	health = max(health - amount, 0)
	print("Gracz dostał obrażenia! HP: ", health)
	health_changed.emit(health)

	if health <= 0:
		die()
		return

	invulnerable = true
	await get_tree().create_timer(INVULN_TIME).timeout
	invulnerable = false

func die():
	print("Gracz zginął!")
	get_tree().reload_current_scene()
