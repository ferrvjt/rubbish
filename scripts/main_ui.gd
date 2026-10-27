class_name MainUI
extends Control

signal jugar_combo(cartas: Array[Carta])
signal limpiar_mano_solicitada
signal pasar_turno
signal guardar_juego

@onready var contenedor_mano: HBoxContainer = $ContenedorMano

# Métricas
@onready var label_turno: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/LabelTurno
@onready var barra_contaminacion: TextureProgressBar = $PanelMetricasContainer/MarginContainer/PanelMetricas/ContenedorContaminacion/BarraContaminacion
@onready var titulo_contaminacion: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/ContenedorContaminacion/TituloContaminacion
@onready var valor_puntos: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/ContenedorPuntos/ValorPuntos
@onready var valor_mazo: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/ContenedorMazo/ValorMazo
@onready var label_comodines: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/LabelComodines

# Botones de Acción
@onready var boton_jugar: Button = $BotonesAccion/BotonJugar
@onready var boton_limpiar: Button = $BotonesAccion/BotonLimpiar
@onready var boton_pasar: Button = $BotonesAccion/BotonPasar
@onready var boton_guardar: Button = $BotonesAccion/BotonGuardar
@onready var boton_menu: Button = $BotonesAccion/BotonMenu
@onready var boton_historial: Button = $BotonesAccion/BotonHistorial

# Feedback e Historial
@onready var label_feedback: Label = $AreaTablero/MarginContainer/VBoxTablero/LabelFeedback
@onready var modal_historial: ColorRect = $ModalHistorial
@onready var texto_historial: RichTextLabel = $ModalHistorial/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TextoHistorial
@onready var boton_cerrar_historial: Button = $ModalHistorial/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BotonCerrarHistorial
@onready var label_fin_juego: Label = $AreaTablero/MarginContainer/VBoxTablero/LabelFinJuego

# Panel de Combos Retráctil
@onready var panel_combos: Panel = $PanelCombos
@onready var boton_toggle_combos: Button = $PanelCombos/BotonToggleCombos
var panel_combos_abierto: bool = false

#Modal Fin juego
@onready var modal_fin_juego: ColorRect = $ModalFinJuego
@onready var label_titulo_fin: Label = $ModalFinJuego/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LabelTituloFin
@onready var label_mensaje_fin: Label = $ModalFinJuego/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LabelMensajeFin
@onready var boton_reintentar: Button = $ModalFinJuego/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContenedorBotonesFin/BotonReintentar
@onready var boton_menu_fin: Button = $ModalFinJuego/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContenedorBotonesFin/BotonMenuFin

const CARTA_VIEW_SCENE = preload("res://scenes/card_view.tscn")
const COMBO_VFX_SCENE = preload("res://scenes/combo_vfx.tscn")

var cartas_seleccionadas: Array[Carta] = []

func _ready() -> void:
	if boton_jugar != null and not boton_jugar.pressed.is_connected(_on_boton_jugar_pressed):
		boton_jugar.pressed.connect(_on_boton_jugar_pressed)
	if boton_limpiar != null and not boton_limpiar.pressed.is_connected(_on_boton_limpiar_pressed):
		boton_limpiar.pressed.connect(_on_boton_limpiar_pressed)
	if boton_pasar != null and not boton_pasar.pressed.is_connected(_on_boton_pasar_pressed):
		boton_pasar.pressed.connect(_on_boton_pasar_pressed)
	if boton_guardar != null and not boton_guardar.pressed.is_connected(_on_boton_guardar_pressed):
		boton_guardar.pressed.connect(_on_boton_guardar_pressed)
	if boton_menu != null and not boton_menu.pressed.is_connected(_on_boton_menu_pressed):
		boton_menu.pressed.connect(_on_boton_menu_pressed)
	if boton_toggle_combos != null:
		boton_toggle_combos.pressed.connect(_on_boton_toggle_combos_pressed)
	if boton_historial != null:
		boton_historial.pressed.connect(_on_abrir_historial)
	if boton_cerrar_historial != null:
		boton_cerrar_historial.pressed.connect(_on_cerrar_historial)
	if boton_reintentar != null:
		boton_reintentar.pressed.connect(_on_reintentar_pressed)
	if boton_menu_fin != null:
		boton_menu_fin.pressed.connect(_on_boton_menu_pressed)
		
	_actualizar_boton_jugar()

func _on_reintentar_pressed() -> void:
	get_tree().reload_current_scene()

func generar_popup_alerta(texto_efecto: String, color_hex: String = "#FF3333") -> void:
	var posicion_centro = get_viewport_rect().size / 2.0
	var vfx = COMBO_VFX_SCENE.instantiate()
	add_child(vfx)
	vfx.global_position = posicion_centro
	
	if vfx.has_method("configurar"):
		vfx.configurar(texto_efecto, posicion_centro, color_hex)

func generar_popup_combo(texto_efecto: String, color_hex: String = "#FFD700") -> void:
	# Obtener el centro de la pantalla/pantalla de juego
	var posicion_centro = get_viewport_rect().size / 2.0

	var vfx = COMBO_VFX_SCENE.instantiate()
	add_child(vfx)
	vfx.global_position = posicion_centro
	
	if vfx.has_method("configurar"):
		vfx.configurar(texto_efecto, posicion_centro, color_hex)

func renderizar_mano(mano: Array[Carta]) -> void:
	cartas_seleccionadas.clear()
	_actualizar_boton_jugar()
	
	for child in contenedor_mano.get_children():
		child.queue_free()
		
	for carta in mano:
		var carta_node = CARTA_VIEW_SCENE.instantiate()
		contenedor_mano.add_child(carta_node)
		if carta_node.has_method("cargar_carta"):
			carta_node.cargar_carta(carta)
		carta_node.carta_seleccionada.connect(_on_carta_seleccionada)

func actualizar_metricas(turno: int, contaminacion: int, limite_contam: int, puntos: int, cartas_mazo: int, comodines_usados: int) -> void:
	if label_turno != null:
		label_turno.text = "Turno: " + str(turno)
		
	if barra_contaminacion != null:
		barra_contaminacion.max_value = limite_contam
		var tween = create_tween()
		tween.tween_property(barra_contaminacion, "value", contaminacion, 0.3).set_trans(Tween.TRANS_SINE)
		
		if contaminacion >= limite_contam - 4:
			barra_contaminacion.tint_progress = Color(1.0, 0.35, 0.35)
			titulo_contaminacion.text = "CONTAMINACIÓN (¡PELIGRO!)"
			titulo_contaminacion.modulate = Color(1.0, 0.35, 0.35)
		else:
			barra_contaminacion.tint_progress = Color(0.4, 1.0, 0.4)
			titulo_contaminacion.text = "CONTAMINACIÓN: " + str(contaminacion) + "/" + str(limite_contam)
			titulo_contaminacion.modulate = Color(1, 1, 1)
			
	if valor_puntos != null:
		valor_puntos.text = str(puntos) + " Pts"
		
	if valor_mazo != null:
		valor_mazo.text = "x" + str(cartas_mazo)
		
	if label_comodines != null:
		label_comodines.text = "Comodines Usados: " + str(comodines_usados)

func mostrar_feedback(mensaje: String, color: Color = Color(1.0, 0.95, 0.35)) -> void:
	if label_feedback != null:
		label_feedback.text = mensaje
		label_feedback.modulate = color

func actualizar_historial(logs: Array[String]) -> void:
	if texto_historial != null and logs.size() > 0:
		texto_historial.text = "\n\n".join(logs)
		var scrollbar = texto_historial.get_v_scroll_bar()
		if scrollbar:
			scrollbar.value = scrollbar.max_value

func mostrar_fin_juego(mensaje: String, es_victoria: bool) -> void:
	if modal_fin_juego != null:
		modal_fin_juego.visible = true
		if label_titulo_fin != null:
			label_titulo_fin.text = "¡VICTORIA!" if es_victoria else "¡DERROTA!"
			label_titulo_fin.modulate = Color(0.3, 1.0, 0.4) if es_victoria else Color(1.0, 0.25, 0.25)
		if label_mensaje_fin != null:
			label_mensaje_fin.text = mensaje
			
	set_estado_botones(false, false, false)

func set_estado_botones(puede_jugar: bool, puede_limpiar: bool, puede_pasar: bool) -> void:
	if boton_jugar != null: boton_jugar.disabled = not puede_jugar
	if boton_limpiar != null: boton_limpiar.disabled = not puede_limpiar
	if boton_pasar != null: boton_pasar.disabled = not puede_pasar

func _on_carta_seleccionada(carta: Carta, esta_seleccionada: bool) -> void:
	if esta_seleccionada:
		if not cartas_seleccionadas.has(carta):
			cartas_seleccionadas.append(carta)
	else:
		cartas_seleccionadas.erase(carta)
	_actualizar_boton_jugar()

func _actualizar_boton_jugar() -> void:
	if boton_jugar != null:
		boton_jugar.text = "JUGAR (" + str(cartas_seleccionadas.size()) + ")"

func _on_boton_jugar_pressed() -> void:
	if cartas_seleccionadas.is_empty():
		mostrar_feedback("[AVISO] Selecciona al menos una carta para jugar.", Color(1.0, 0.4, 0.4))
		return
	jugar_combo.emit(cartas_seleccionadas.duplicate())

func _on_boton_limpiar_pressed() -> void:
	limpiar_mano_solicitada.emit()

func _on_boton_pasar_pressed() -> void:
	pasar_turno.emit()

func _on_boton_guardar_pressed() -> void:
	guardar_juego.emit()

func _on_boton_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_boton_toggle_combos_pressed() -> void:
	panel_combos_abierto = not panel_combos_abierto
	boton_toggle_combos.text = "<" if panel_combos_abierto else ">"
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel_combos, "position:x", 0.0 if panel_combos_abierto else -300.0, 0.4)

func _on_abrir_historial() -> void:
	if modal_historial != null: modal_historial.visible = true

func _on_cerrar_historial() -> void:
	if modal_historial != null: modal_historial.visible = false