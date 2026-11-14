extends CharacterBody2D

enum Weapon {
	SWORD,
	PISTOL,
	SHOTGUN
}

const SPEED = 200.0
const JUMP_VELOCITY = -200.0
var bt
var current_weapon = Weapon.SWORD
var can_attack = true
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
	handle_weapon_input()


func handle_weapon_input():
	if Input.is_action_just_pressed("weapon_sword"):
		current_weapon = Weapon.SWORD

	if Input.is_action_just_pressed("weapon_pistol"):
		current_weapon = Weapon.PISTOL

	if Input.is_action_just_pressed("weapon_shotgun"):
		current_weapon = Weapon.SHOTGUN

	if Input.is_action_just_pressed("shoot"):
		match current_weapon:
			Weapon.SWORD:
				sword_attack()

			Weapon.PISTOL:
				pistol_shoot()

			Weapon.SHOTGUN:
				shotgun_shoot()


func pistol_shoot():
	var target_pos = get_global_mouse_position()
	var spawn_pos = $BulletSpawn.global_position

	var bt = bullet.instantiate()
	get_parent().add_child(bt)
	bt.setup(spawn_pos, target_pos)


func shotgun_shoot():
	var target_pos = get_global_mouse_position()
	var spawn_pos = $BulletSpawn.global_position

	var spread = [-0.2, -0.1, 0.0, 0.1, 0.2]

	for angle in spread:
		var aim = (target_pos - spawn_pos).normalized()
		var pellet_target = spawn_pos + aim.rotated(angle) * 1000.0

		var bt = bullet.instantiate()
		get_parent().add_child(bt)
		bt.setup(spawn_pos, pellet_target)
		
func sword_attack():
	if not can_attack:
		return

	can_attack = false

	$SwordHitbox/CollisionShape2D.disabled = false

	await get_tree().create_timer(0.15).timeout

	$SwordHitbox/CollisionShape2D.disabled = true

	await get_tree().create_timer(0.25).timeout

	can_attack = true
