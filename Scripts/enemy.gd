extends CharacterBody3D

# Esta es la variable que el script Main.gd necesita para asignar el jugador.
# La declaramos sin tipado estricto para evitar el error anterior.
var player = null 

@export var speed: float = 2.0 
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") 

# Estadísticas (Mínimo requerido para la progresión)
var health: int = 10 
var xp_value: int = 1 


func _physics_process(delta: float) -> void:
	# Aplicar la gravedad (para que se mantenga en el suelo)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Lógica de persecución
	if player:
		# 1. Calcular la dirección hacia el jugador
		var direction_to_player = (player.global_position - global_position).normalized()
		
		# 2. Ignoramos la altura (eje Y) para que no intenten subir
		direction_to_player.y = 0 
		
		# 3. Aplicar movimiento
		velocity.x = direction_to_player.x * speed
		velocity.z = direction_to_player.z * speed
		
		# (Opcional) Rotar para que el enemigo mire hacia donde se mueve
		look_at(player.global_position, Vector3.UP)
		
	else:
		# Si no encuentra al jugador, desacelera suavemente
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	move_and_slide()


# Función para que el proyectil del jugador aplique daño
func take_damage(amount: int):
	health -= amount
	print(name, " ha recibido ", amount, " de daño. Vida restante: ", health)
	
	if health <= 0:
		die()

func die():
	print(name, " ha sido destruido.")
	# Aquí se generará el objeto de XP (más adelante)
	queue_free() # Destruye el enemigo
