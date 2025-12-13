extends CharacterBody3D

# Velocidad de movimiento y rotación del jugador
@export var speed: float = 8.0
@export var rotation_speed: float = 5.0 # Nueva variable para controlar la velocidad de rotación (radianes/segundo)
const JUMP_VELOCITY = 4.5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- ANIMACIONES: CONFIGURACIÓN ACTUAL ---
@onready var anim_player: AnimationPlayer = $Character_Male_2/AnimationPlayer
const ANIM_IDLE = "Idle"
const ANIM_RUN = "Run"
# ----------------------------------------

# --- ATAQUE AUTOMÁTICO ---
const ProjectileScene = preload("res://Entities/projectile.tscn")
@export var attack_damage: int = 10
@export var attack_cooldown: float = 1.0
var time_until_next_attack: float = 0.0


func _ready() -> void:
	time_until_next_attack = 0.0
	if anim_player and anim_player.has_animation(ANIM_IDLE):
		anim_player.play(ANIM_IDLE)

func _physics_process(delta: float) -> void:
	# --------------------
	# 1. LÓGICA DE MOVIMIENTO Y ROTACIÓN (MODIFICADO)
	# --------------------
	var input_dir = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	
	# Separar la entrada para Rotación (A/D) y Movimiento (W/S)
	var rotation_input = input_dir.x  # A/D
	var forward_input = input_dir.y   # W/S
	
	# Aplicar gravedad
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Aplicar ROTACIÓN al personaje (CharacterBody3D)
	if rotation_input != 0:
		# Giramos el CharacterBody3D en el eje Y. 
		# Usamos -rotation_input para que 'A' (negativo) gire a la izquierda y 'D' (positivo) gire a la derecha.
		rotate_y(-rotation_input * rotation_speed * delta)
		
	# Calcular la dirección de MOVIMIENTO (solo adelante/atrás)
	# El Vector3(0, 0, forward_input) asegura que solo nos movemos en el eje Z local del personaje
	var direction = (transform.basis * Vector3(0, 0, forward_input)).normalized()
	
	
	if direction:
		# Aplicar la velocidad en la dirección actual del personaje
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		# Control de Animación: Correr/Caminar
		if anim_player and anim_player.current_animation != ANIM_RUN:
			anim_player.play(ANIM_RUN)

	else:
		# Detener el movimiento gradualmente (desaceleración)
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
		# Control de Animación: Detenerse
		if anim_player and anim_player.current_animation != ANIM_IDLE:
			anim_player.play(ANIM_IDLE)

	move_and_slide()
	
	# --------------------
	# 2. LÓGICA DE ATAQUE AUTOMÁTICO
	# --------------------
	time_until_next_attack -= delta
	
	if time_until_next_attack <= 0:
		perform_auto_attack()
		time_until_next_attack = attack_cooldown

func perform_auto_attack():
	# (TO DO: En el futuro, esta función debe buscar el enemigo más cercano)
	
	var projectile = ProjectileScene.instantiate()
	
	# La posición inicial del proyectil (ligeramente por encima del jugador)
	projectile.global_position = global_position + Vector3(0, 0.5, 0)
	
	# Por ahora, disparamos hacia adelante (eje Z negativo local del personaje)
	var attack_direction = -transform.basis.z 
	
	# Asumimos que la función setup() está en projectile.gd
	projectile.setup(attack_direction, attack_damage)
	
	# Añadimos el proyectil al nodo raíz (Main_3D) para que exista en el mundo
	get_parent().add_child(projectile)
