extends CharacterBody3D

signal enemy_died # Avisa al Main que este enemigo murió
var player = null

@export var speed: float = 3.0 
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") 

# --- ESTADÍSTICAS ---
@export var health: int = 50 
@export var attack_damage: int = 10
@export var attack_range: float = 1.5 
@export var attack_cooldown: float = 1.0 

# --- REFERENCIAS A NODOS ---
@onready var anim_player: AnimationPlayer = $Zombie/AnimationPlayer 
@onready var sfx_zombie: AudioStreamPlayer3D = $AudioStreamPlayer3D # Referencia al sonido

# --- ANIMACIONES ---
const ANIM_IDLE = "Idle"
const ANIM_RUN = "Run"
const ANIM_HIT = "HitRecieve" 
const ANIM_DEATH = "Death"
const ANIM_ATTACK = "Attack"

# --- ESTADOS ---
var is_dead: bool = false
var is_hurting: bool = false 
var is_attacking: bool = false
var time_until_next_attack: float = 0.0

func _ready():
	# Variamos el tono un poco para que cada zombie suene ligeramente distinto
	if sfx_zombie:
		sfx_zombie.pitch_scale = randf_range(0.8, 1.2)

func _physics_process(delta: float) -> void:
	if is_dead:
		if not is_on_floor(): velocity.y -= gravity * delta
		move_and_slide()
		return

	# Gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Gestionar cooldown de ataque
	if time_until_next_attack > 0:
		time_until_next_attack -= delta

	# Si está herido, espera a recuperarse
	if is_hurting:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		move_and_slide()
		if not anim_player.is_playing() or anim_player.current_animation != ANIM_HIT:
			is_hurting = false
		return

	# --- IA DE PERSECUCIÓN Y ATAQUE ---
	if player:
		var distance_to_player = global_position.distance_to(player.global_position)
		
		if distance_to_player <= attack_range:
			velocity.x = 0
			velocity.z = 0
			if time_until_next_attack <= 0 and not is_attacking:
				attack_player()
		else:
			is_attacking = false 
			var direction_to_player = (player.global_position - global_position).normalized()
			direction_to_player.y = 0 
			
			velocity.x = direction_to_player.x * speed
			velocity.z = direction_to_player.z * speed
			
			look_at(player.global_position, Vector3.UP)
			
			if anim_player.current_animation != ANIM_RUN and not is_attacking:
				anim_player.play(ANIM_RUN)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		if anim_player.current_animation != ANIM_IDLE:
			anim_player.play(ANIM_IDLE)

	move_and_slide()

func attack_player():
	is_attacking = true
	time_until_next_attack = attack_cooldown
	anim_player.play(ANIM_ATTACK)
	
	await get_tree().create_timer(0.3).timeout
	
	if not is_dead and player and global_position.distance_to(player.global_position) <= attack_range + 0.5:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
	
	is_attacking = false

func take_damage(amount: int):
	if is_dead: return
	health -= amount
	
	# Reproducir sonido de impacto
	if sfx_zombie:
		sfx_zombie.play()

	if health <= 0:
		die()
	else:
		is_hurting = true
		is_attacking = false 
		anim_player.stop()
		anim_player.play(ANIM_HIT)

func die():
	if is_dead: return 
	is_dead = true
	
	enemy_died.emit() 
	
	# Reproducir sonido de muerte
	if sfx_zombie:
		sfx_zombie.play()
	
	# Desactivar colisiones
	if has_node("CollisionShape3D"):
		$CollisionShape3D.set_deferred("disabled", true)
	
	anim_player.play(ANIM_DEATH)
	
	# Esperar antes de borrar al zombie de la escena
	await get_tree().create_timer(3.0).timeout
	queue_free()
