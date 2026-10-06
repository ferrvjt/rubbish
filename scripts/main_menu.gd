class_name MainMenu
extends Control

# Contenedores de los submenús
@onready var menu_principal: VBoxContainer = $CenterContainer/PanelMenu/MarginContainer/MenuPrincipal
@onready var menu_modos: VBoxContainer = $CenterContainer/PanelMenu/MarginContainer/MenuModos

# Botones del menu principal
@onready var boton_nueva: Button = $CenterContainer/PanelMenu/MarginContainer/VBoxMenu/BotonNueva
@onready var boton_cargar: Button = $CenterContainer/PanelMenu/MarginContainer/VBoxMenu/BotonCargar
@onready var label_info: Label = $CenterContainer/PanelMenu/MarginContainer/VBoxMenu/LabelInfoGuardado
@onready var boton_salir: Button = $CenterContainer/PanelMenu/MarginContainer/VBoxMenu/BotonSalir

# Botones del menú de modos
@onready var boton_estandar: Button = $CenterContainer/PanelMenu/MarginContainer/MenuModos/BotonModoEstandar
@onready var boton_infinito: Button = $CenterContainer/PanelMenu/MarginContainer/MenuModos/BotonModoInfinito
@onready var boton_reto: Button = $CenterContainer/PanelMenu/MarginContainer/MenuModos/BotonModoReto
@onready var boton_volver: Button = $CenterContainer/PanelMenu/MarginContainer/MenuModos/BotonVolver

func _ready() -> void:
	#Conexiones Menu principal
	boton_nueva.pressed.connect(_on_nueva_partida_pressed)
	boton_cargar.pressed.connect(_on_cargar_partida_pressed)
	boton_salir.pressed.connect(_on_salir_pressed)

	# Conexiones Menú de Modos
	boton_estandar.pressed.connect(func(): _iniciar_nueva_partida("ESTANDAR"))
	boton_infinito.pressed.connect(func() :_iniciar_nueva_partida("INFINITO"))
	boton_reto.pressed.connect(func(): _iniciar_nueva_partida("RETO_TOXICO"))
	boton_volver.pressed.connect(_mostrar_menu_principal)

	_mostrar_menu_principal()
	_actualizar_estado_guardado()

func _actualizar_estado_guardado() -> void:
	if PersistenciaManager.hay_partida_guardada():
		boton_cargar.disabled = false
		label_info.text = PersistenciaManager.obtener_resumen_guardado()
		label_info.modulate = Color(0.5, 1.0, 0.6)
	else:
		boton_cargar.disabled = true
		label_info.text = "No hay partida guardada disponible."
		label_info.modulate = Color(0.7, 0.7, 0.7)

func _mostrar_menu_modos() -> void:
	menu_principal.visible = true
	menu_modos.visible= true

func _mostrar_menu_principal() -> void:
	menu_principal.visible = true
	menu_modos.visible= false

func _iniciar_nueva_partida(modo_seleccionado: String)-> void:
	PersistenciaManager.partida_cargada_pendiente = {
		"es_nueva_partida": true,
		"modo_juego": modo_seleccionado
	}
	get_tree().change_scene_to_file("res://scenes/main_ui.tscn")

func _on_nueva_partida_pressed() -> void:
	PersistenciaManager.partida_cargada_pendiente = {}
	get_tree().change_scene_to_file("res://scenes/main_ui.tscn")

func _on_cargar_partida_pressed() -> void:
	var datos = PersistenciaManager.cargar_partida_datos()
	if not datos.is_empty():
		PersistenciaManager.partida_cargada_pendiente = datos
		get_tree().change_scene_to_file("res://scenes/main_ui.tscn")
	else:
		if label_info != null:
			label_info.text = "[ERROR] No se pudo leer el archivo de guardado."
			label_info.modulate = Color(1.0, 0.3, 0.3)

func _on_salir_pressed() -> void:
	get_tree().quit()
