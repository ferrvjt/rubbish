class_name MainMenu
extends Control

# Submenús
@onready var menu_principal: VBoxContainer = $CenterContainer/PanelMenu/MarginContainer/MenuPrincipal
@onready var menu_modos: VBoxContainer = $CenterContainer/PanelMenu/MarginContainer/MenuModos

# Botones Menú Principal
@onready var boton_nueva: Button = $CenterContainer/PanelMenu/MarginContainer/MenuPrincipal/BotonNueva
@onready var boton_cargar: Button = $CenterContainer/PanelMenu/MarginContainer/MenuPrincipal/BotonCargar
@onready var boton_tutorial_completo: Button = $CenterContainer/PanelMenu/MarginContainer/MenuPrincipal/BotonTutorialCompleto
@onready var label_info: Label = $CenterContainer/PanelMenu/MarginContainer/MenuPrincipal/LabelInfoGuardado
@onready var boton_salir: Button = $CenterContainer/PanelMenu/MarginContainer/MenuPrincipal/BotonSalir

# Botones Menú de Modos
@onready var boton_estandar: Button = $CenterContainer/PanelMenu/MarginContainer/MenuModos/BotonModoEstandar
@onready var boton_infinito: Button = $CenterContainer/PanelMenu/MarginContainer/MenuModos/BotonModoInfinito
@onready var boton_reto: Button = $CenterContainer/PanelMenu/MarginContainer/MenuModos/BotonModoReto
@onready var boton_volver: Button = $CenterContainer/PanelMenu/MarginContainer/MenuModos/BotonVolver

# Nodos del Modal de Descripción
@onready var modal_descripcion: ColorRect = $ModalDescripcion
@onready var label_titulo_modo: Label = $ModalDescripcion/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LabelTituloModo
@onready var label_desc_modo: RichTextLabel = $ModalDescripcion/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LabelDescModo
@onready var boton_cancelar_modo: Button = $ModalDescripcion/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContenedorBotones/BotonCancelarModo
@onready var boton_empezar_modo: Button = $ModalDescripcion/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContenedorBotones/BotonEmpezarModo

var modo_pendiente_inicio: String = "ESTANDAR"

const DESCRIPCIONES_MODOS = {
	"ESTANDAR": "Partida clásica equilibrada. Limpia las cartas del mazo procesando combos antes de que el medidor alcance 21 de contaminación.",
	"INFINITO": "El mazo se recicla y rebaraja de forma ilimitada cuando se agotan las cartas. Consigue el puntaje más alto posible antes de sucumbir a la contaminación acumulada.",
	"RETO_TOXICO": "Desafío extremo. El límite de contaminación se reduce a 15 y la penalización por retención de residuos tóxicos es más severa."
}

func _ready() -> void:
	if boton_nueva != null:
		boton_nueva.pressed.connect(_mostrar_menu_modos)
	if boton_cargar != null:
		boton_cargar.pressed.connect(_on_cargar_partida_pressed)
	if boton_tutorial_completo != null:
		boton_tutorial_completo.pressed.connect(_on_tutorial_completo_pressed)
	if boton_salir != null:
		boton_salir.pressed.connect(_on_salir_pressed)
	
	if boton_estandar != null:
		boton_estandar.pressed.connect(func(): _preparar_descripcion_modo("ESTANDAR"))
	if boton_infinito != null:
		boton_infinito.pressed.connect(func(): _preparar_descripcion_modo("INFINITO"))
	if boton_reto != null:
		boton_reto.pressed.connect(func(): _preparar_descripcion_modo("RETO_TOXICO"))
	if boton_volver != null:
		boton_volver.pressed.connect(_mostrar_menu_principal)
		
	if boton_cancelar_modo != null:
		boton_cancelar_modo.pressed.connect(func(): modal_descripcion.visible = false)
	if boton_empezar_modo != null:
		boton_empezar_modo.pressed.connect(_confirmar_e_iniciar_partida)
		
	_mostrar_menu_principal()
	_actualizar_estado_guardado()

func _preparar_descripcion_modo(modo: String) -> void:
	modo_pendiente_inicio = modo
	
	# Si el nodo ModalDescripcion no existe en la escena, inicia el juego directamente
	if modal_descripcion == null:
		_iniciar_nueva_partida(modo)
		return
		
	if label_titulo_modo != null:
		label_titulo_modo.text = "MODO: " + modo.replace("_", " ")
	if label_desc_modo != null:
		label_desc_modo.text = DESCRIPCIONES_MODOS.get(modo, "Sin descripción disponible.")
		
	modal_descripcion.visible = true

func _confirmar_e_iniciar_partida() -> void:
	_iniciar_nueva_partida(modo_pendiente_inicio)

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

func _on_cargar_partida_pressed() -> void:
	var datos = PersistenciaManager.cargar_partida_datos()
	if not datos.is_empty():
		datos["es_nueva_partida"] = false
		PersistenciaManager.partida_cargada_pendiente = datos
		get_tree().change_scene_to_file("res://scenes/main_ui.tscn")

func _on_tutorial_completo_pressed() -> void:
	PersistenciaManager.partida_cargada_pendiente = {
		"es_nueva_partida": true,
		"modo_juego": "TUTORIAL_COMPLETO"
	}
	get_tree().change_scene_to_file("res://scenes/main_ui.tscn")

func _on_salir_pressed() -> void:
	get_tree().quit()