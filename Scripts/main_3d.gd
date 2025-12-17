extends Node3D

# --- REFERENCIAS A NODOS ---
@onready var player_ref = $Player
@onready var hud = $HUD 
@onready var musica_fondo = $AudioStreamPlayer # Asegúrate de que este nodo exista en tu escena

# --- CONFIGURACIÓN DE RUTAS ---
const MENU_SCENE_PATH = "res://Entities/main_menu.tscn"

# --- CONFIGURACIÓN DE ENEMIGOS (Inspector) ---
@export_group("Configuración de Enemigos")
@export var demon_scene: PackedScene 
@export var zombie_scene: PackedScene
@export var Giant_scene: PackedScene 

# --- CONFIGURACIÓN DE OLEADAS (Inspector) ---
@export_group("Configuración de Olas")
@export var spawn_radius_min: float = 5.0  # Distancia mínima
@export var spawn_radius_max: float = 15.0 # Distancia máxima (un poco más amplia)
@export var initial_enemy_count: int = 3   # Enemigos ronda 1

# --- VARIABLES INTERNAS DEL JUEGO ---
var current_wave: int = 0
var enemies_alive: int = 0
var score: int = 0

# --- CICLO DE VIDA ---

func _ready():
	# 1. Iniciar Música
	if musica_fondo:
		musica_fondo.play()
	else:
		print("ADVERTENCIA: No se encontró el nodo AudioStreamPlayer para la música.")

	# 2. Verificar Player
	if not player_ref:
		print("ERROR CRÍTICO: No se encuentra el nodo Player en Main3D.")
		return
	
	# Conectamos la señal de muerte del jugador
	if player_ref.has_signal("player_died"):
		player_ref.player_died.connect(_on_player_died)
	
	# 3. Configurar HUD
	if hud:
		# Conectamos salud y botones
		player_ref.health_changed.connect(hud.update_health)
		hud.update_health(player_ref.max_health)
		hud.retry_pressed.connect(_on_retry)
		hud.menu_pressed.connect(_on_menu)
		
		# Reset visual
		hud.update_score(0)
		hud.update_wave(0)
		hud.update_enemies(0)
	else:
		print("ADVERTENCIA: No se encontró el nodo HUD.")

	# 4. Iniciar el flujo de oleadas
	await get_tree().create_timer(2.0).timeout
	if is_instance_valid(player_ref) and not player_ref.is_dead:
		start_new_wave()

# --- LÓGICA DE OLEADAS ---

func start_new_wave():
	current_wave += 1
	print("--- INICIANDO HORDA ", current_wave, " ---")
	
	if hud: hud.update_wave(current_wave)
	
	var amount_to_spawn = initial_enemy_count + ((current_wave - 1) * 2)
	var extra_damage = (current_wave - 1) * 5
	
	spawn_horde(amount_to_spawn, extra_damage)

func spawn_horde(count: int, bonus_damage: int):
	enemies_alive = count
	if hud: hud.update_enemies(enemies_alive)
	
	for i in range(count):
		if not is_instance_valid(player_ref) or player_ref.is_dead:
			break
			
		spawn_random_enemy(bonus_damage)
		await get_tree().create_timer(0.3).timeout

func spawn_random_enemy(bonus_damage: int):
	if not player_ref: return
	
	var chosen_scene: PackedScene
	var chance = randf()

	if chance < 0.15:
		chosen_scene = Giant_scene
	elif chance < 0.55:
		chosen_scene = zombie_scene
	else:
		chosen_scene = demon_scene

	if chosen_scene == null:
		return

	var enemy_instance = chosen_scene.instantiate()
	
	# Posición aleatoria alrededor del jugador
	var angle = randf() * TAU
	var distance = randf_range(spawn_radius_min, spawn_radius_max)
	var spawn_pos = player_ref.global_position
	spawn_pos.x += sin(angle) * distance
	spawn_pos.z += cos(angle) * distance
	
	enemy_instance.global_position = spawn_pos
	enemy_instance.player = player_ref
	
	if "attack_damage" in enemy_instance:
		enemy_instance.attack_damage += bonus_damage
	
	enemy_instance.enemy_died.connect(_on_enemy_died)
	add_child(enemy_instance)

# --- CALLBACKS Y SEÑALES ---

func _on_enemy_died():
	enemies_alive -= 1
	score += 10
	
	if hud:
		hud.update_enemies(enemies_alive)
		hud.update_score(score)
	
	if enemies_alive <= 0:
		await get_tree().create_timer(3.0).timeout
		if is_instance_valid(player_ref) and not player_ref.is_dead:
			start_new_wave()

func _on_player_died():
	# Detener música o bajar volumen al morir si lo deseas:
	# musica_fondo.stop() 
	await get_tree().create_timer(2.0).timeout
	if hud:
		hud.show_game_over()

func _on_retry():
	get_tree().reload_current_scene()

func _on_menu():
	get_tree().change_scene_to_file(MENU_SCENE_PATH)
