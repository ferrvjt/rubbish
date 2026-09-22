class_name MainMenu
extends Control

@onready var boton_nueva: Button = $CenterContainer/PanelMenu/MarginContainer/VBoxMenu/BotonNueva
@onready var boton_cargar: Button = $CenterContainer/PanelMenu/MarginContainer/VBoxMenu/BotonCargar
@onready var label_info: Label = $CenterContainer/PanelMenu/MarginContainer/VBoxMenu/LabelInfoGuardado
@onready var boton_salir: Button = $CenterContainer/PanelMenu/MarginContainer/VBoxMenu/BotonSalir

func _ready() -> void:
	if boton_nueva != null:
		boton_nueva.pressed.connect(_on_nueva_partida_pressed)
	if boton_cargar != null:
		boton_cargar.pressed.connect(_on_cargar_partida_pressed)
	if boton_salir != null:
		boton_salir.pressed.connect(_on_salir_pressed)
		
	_actualizar_estado_guardado()

func _actualizar_estado_guardado() -> void:
	if PersistenciaManager.hay_partida_guardada():
		if boton_cargar != null:
			boton_cargar.disabled = false
		if label_info != null:
			label_info.text = PersistenciaManager.obtener_resumen_guardado()
			label_info.modulate = Color(0.5, 1.0, 0.6)
	else:
		if boton_cargar != null:
			boton_cargar.disabled = true
		if label_info != null:
			label_info.text = "No hay partida guardada disponible."
			label_info.modulate = Color(0.7, 0.7, 0.7)

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

