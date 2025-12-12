extends Node3D

# Esta función se llama cuando la escena Main_3D está cargada y lista.
func _ready():
	# 1. Obtener la referencia al nodo Jugador 
	var player_node = $Player 

	# 2. Obtener la referencia al nodo Enemigo
	var enemy_node = $Enemy 

	# 3. Pasar la referencia del jugador al script del enemigo
	if enemy_node and player_node:
		enemy_node.player = player_node
		print("Conexión Player-Enemy establecida.")
	else:
		print("ERROR: No se encontró el nodo Player o Enemy.")
