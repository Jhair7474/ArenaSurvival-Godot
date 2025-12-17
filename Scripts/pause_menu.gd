extends CanvasLayer

# Referencia a la ruta de tu menú principal
const MAIN_MENU_PATH = "res://Entities/main_menu.tscn" # ¡Verifica esta ruta!

@onready var resume_btn = $CenterContainer/VBoxContainer/ButtonResume
@onready var exit_btn = $CenterContainer/VBoxContainer/ButtonExit

func _ready():
	# 1. Al iniciar, el menú debe estar oculto
	visible = false
	
	# 2. Conectar señales de botones
	resume_btn.pressed.connect(_on_resume_pressed)
	exit_btn.pressed.connect(_on_exit_pressed)

func _input(event):
	# Detectar tecla ESCAPE (ui_cancel viene configurado por defecto en Godot)
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()

func toggle_pause():
	# Invertimos el estado de pausa actual
	var is_paused = not get_tree().paused
	get_tree().paused = is_paused
	
	# Mostramos u ocultamos el menú
	visible = is_paused
	
	# MANEJO DEL MOUSE
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Mostrar mouse para clicar
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Ocultar mouse para jugar

func _on_resume_pressed():
	toggle_pause() # Simplemente volvemos a alternar la pausa para cerrar

func _on_exit_pressed():
	# IMPORTANTE: Antes de cambiar de escena, hay que DESCONGELAR el juego.
	# Si no, el menú principal estará congelado también.
	get_tree().paused = false 
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
