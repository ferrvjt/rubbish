class_name MainMenu
extends Control

# Submenús
@onready var menu_principal: VBoxContainer = $CenterContainer/PanelMenu/MarginContainer/MenuPrincipal
@onready var menu_modos: VBoxContainer = $CenterContainer/PanelMenu/MarginContainer/MenuModos

# Botones del menú principal
@onready var boton_nueva: Button = $CenterContainer/PanelMenu/MarginContainer/MenuPrincipal/BotonNueva
@onready var boton_cargar: Button = $CenterContainer/PanelMenu/MarginContainer/MenuPrincipal/BotonCargar
@onready var label_info: Label = $CenterContainer/PanelMenu/MarginContainer/MenuPrincipal/LabelInfoGuardado
@onready var boton_salir: Button = $CenterContainer/PanelMenu/MarginContainer/MenuPrincipal/BotonSalir

# Botones del menú de modos
@onready var boton_estandar: Button = $CenterContainer/PanelMenu/MarginContainer/MenuModos/BotonModoEstandar
@onready var boton_infinito: Button = $CenterContainer/PanelMenu/MarginContainer/MenuModos/BotonModoInfinito
@onready var boton_reto: Button = $CenterContainer/PanelMenu/MarginContainer/MenuModos/BotonModoReto
@onready var boton_volver: Button = $CenterContainer/PanelMenu/MarginContainer/MenuModos/BotonVolver

func _ready() -> void:
	# Conexiones Menú Principal
	if boton_nueva != null:
		boton_nueva.pressed.connect(_mostrar_menu_modos)
	if boton_cargar != null:
		boton_cargar.pressed.connect(_on_cargar_partida_pressed)
	if boton_salir != null:
		boton_salir.pressed.connect(_on_salir_pressed)
	
	# Conexiones Menú de Modos
	if boton_estandar != null:
		boton_estandar.pressed.connect(func(): _iniciar_nueva_partida("ESTANDAR"))
	if boton_infinito != null:
		boton_infinito.pressed.connect(func(): _iniciar_nueva_partida("INFINITO"))
	if boton_reto != null:
		boton_reto.pressed.connect(func(): _iniciar_nueva_partida("RETO_TOXICO"))
	if boton_volver != null:
		boton_volver.pressed.connect(_mostrar_menu_principal)
		
	_mostrar_menu_principal()
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

func _mostrar_menu_modos() -> void:
	if menu_principal != null: menu_principal.visible = false
	if menu_modos != null: menu_modos.visible = true

func _mostrar_menu_principal() -> void:
	if menu_modos != null: menu_modos.visible = false
	if menu_principal != null: menu_principal.visible = true

func _iniciar_nueva_partida(modo_seleccionado: String) -> void:
	var perfil = PersistenciaManager.cargar_perfil()
	var modo_final = modo_seleccionado
	
	if not perfil.get("tutorial_completado", false):
		modo_final = "TUTORIAL"
		
	PersistenciaManager.partida_cargada_pendiente = {
		"es_nueva_partida": true,
		"modo_juego": modo_final
	}
	get_tree().change_scene_to_file("res://scenes/main_ui.tscn")

func _on_cargar_partida_pressed() -> void:
	var datos = PersistenciaManager.cargar_partida_datos()
	if not datos.is_empty():
		datos["es_nueva_partida"] = false
		PersistenciaManager.partida_cargada_pendiente = datos
		get_tree().change_scene_to_file("res://scenes/main_ui.tscn")
	else:
		if label_info != null:
			label_info.text = "[ERROR] No se pudo leer el archivo."
			label_info.modulate = Color(1.0, 0.3, 0.3)


func _on_salir_pressed() -> void:
	get_tree().quit()