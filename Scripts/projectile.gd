extends Area3D

@export var speed: float = 20.0
var direction: Vector3 = Vector3.FORWARD
var damage: int = 10
var shooter_ref: Node3D = null # Variable para guardar quién disparó

func _ready() -> void:
	# Conectamos la señal. Asegúrate de que NO esté conectada manualmente en el editor
	# para evitar que se conecte dos veces.
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# Temporizador de seguridad: si no golpea nada en 3 seg, se destruye
	await get_tree().create_timer(3.0).timeout
	if is_instance_valid(self):
		queue_free()

func _process(delta: float) -> void:
	# Mover el proyectil en la dirección asignada
	global_position += direction * speed * delta

# Función llamada desde el player para iniciar la bala
func setup(dir: Vector3, dmg: int, who_shot: Node3D):
	direction = dir.normalized()
	damage = dmg
	shooter_ref = who_shot # Guardamos la referencia del jugador
	
	# Hacemos que la bala mire visualmente hacia donde va
	if direction.length() > 0:
		look_at(global_position + direction, Vector3.UP)

func _on_body_entered(body: Node3D) -> void:
	# 1. IMPORTANTE: Si el cuerpo que tocamos es el tirador (el jugador), ignoramos el choque.
	if body == shooter_ref:
		return

	# 2. Si es un enemigo (tiene la función take_damage), le hacemos daño
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free() # Destruimos la bala
	
	# 3. Si es una pared o suelo (y no es el jugador), destruimos la bala
	else:
		queue_free()
