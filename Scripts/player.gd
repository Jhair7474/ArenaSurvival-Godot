extends CharacterBody3D

# --- CONFIGURACIÓN DE MOVIMIENTO ---
@export var speed: float = 8.0
@export var rotation_speed: float = 5.0
const JUMP_VELOCITY = 4.5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# --- ANIMACIONES ---
@onready var anim_player: AnimationPlayer = $Character_Male_2/AnimationPlayer
const ANIM_IDLE = "Idle"
const ANIM_RUN = "Run"

# --- CONFIGURACIÓN DE ATAQUE (RÁFAGA AUTOMÁTICA) ---
# Asegúrate de que la ruta sea correcta. Si cambiaste la carpeta, actualízala aquí.
const ProjectileScene = preload("res://Entities/projectile.tscn")

@export var damage: int = 10
@export var shots_per_burst: int = 3      # Dispara 3 balas seguidas
@export var time_between_shots: float = 0.2 # Tiempo entre bala y bala (ta-ta-ta)
@export var reload_time: float = 1.5      # Tiempo de espera antes de la siguiente ráfaga
@export_group("Ajustes de Disparo")
@export var projectile_offset: Vector3 = Vector3(0, 1.0, -0.8) 
@export var shoot_forward_vector: Vector3 = Vector3(0, 0, -1)

var can_shoot: bool = true # Semáforo para controlar la ráfaga

func _ready() -> void:
	if anim_player and anim_player.has_animation(ANIM_IDLE):
		anim_player.play(ANIM_IDLE)

func _physics_process(delta: float) -> void:
	# --------------------
	# A. LÓGICA DE MOVIMIENTO
	# --------------------
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var rotation_input = input_dir.x 
	var forward_input = input_dir.y   

	# Rotación
	if rotation_input != 0:
		rotate_y(-rotation_input * rotation_speed * delta)

	# Movimiento (eje Z local)
	var direction = (transform.basis * Vector3(0, 0, forward_input)).normalized()
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if anim_player and anim_player.current_animation != ANIM_RUN:
			anim_player.play(ANIM_RUN)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		if anim_player and anim_player.current_animation != ANIM_IDLE:
			anim_player.play(ANIM_IDLE)

	move_and_slide()
	
	# --------------------
	# B. LÓGICA DE DISPARO AUTOMÁTICO
	# --------------------
	# Si el "semáforo" está en verde, iniciamos una ráfaga nueva
	if can_shoot:
		start_auto_burst()

# Función asíncrona (Corrutina) para manejar la ráfaga
func start_auto_burst():
	can_shoot = false # Bloqueamos para que no se inicien ráfagas superpuestas
	
	# Bucle para disparar X cantidad de veces
	for i in range(shots_per_burst):
		fire_projectile()
		# Esperamos el tiempo corto entre disparos
		await get_tree().create_timer(time_between_shots).timeout
	
	# Al terminar la ráfaga, esperamos el tiempo largo de recarga
	await get_tree().create_timer(reload_time).timeout
	
	can_shoot = true # Desbloqueamos para permitir la siguiente ráfaga

func fire_projectile():
	var projectile = ProjectileScene.instantiate()
	
	# 1. POSICIÓN: Usamos 'to_global' para convertir el offset a coordenadas del mundo real
	# Si sale de la espalda, cambia la Z en el Inspector (ej: de -0.8 a 0.8)
	projectile.global_position = to_global(projectile_offset)
	
	# 2. DIRECCIÓN: Usamos global_transform para asegurar la dirección real en el mundo
	# Multiplicamos la base global por tu vector de ajuste.
	var final_direction = (global_transform.basis * shoot_forward_vector).normalized()
	
	projectile.setup(final_direction, damage, self)
	get_parent().add_child(projectile)
