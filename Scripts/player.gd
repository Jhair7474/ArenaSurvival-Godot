extends CharacterBody3D

# Velocidad de movimiento del jugador
@export var speed: float = 8.0 
# La gravedad es útil si hubiera saltos, pero la mantenemos para el CharacterBody3D
const JUMP_VELOCITY = 4.5
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") 

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	
	# 1. Aplicar la gravedad (siempre cae, pero el suelo lo detiene)
	if not is_on_floor():
		velocity.y -= gravity * delta

	# 2. Convertir la entrada 2D (horizontal) a un vector 3D
	# Usamos X y Z para el plano horizontal (el suelo)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# 3. Establecer la velocidad horizontal
	if direction:
		# Mantenemos la velocidad Y (gravedad) pero aplicamos el movimiento XZ
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Desaceleración suave (deja la velocidad Y intacta)
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# 4. Mover el CharacterBody3D
	move_and_slide()
