class_name MainUI
extends Control

#Señales para GameManager
signal jugar_combo(cartas: Array[Carta])
signal limpiar_mano_solicitada
signal pasar_turno
signal guardar_juego

@onready var contenedor_mano: HBoxContainer = $ContenedorMano

# Métricas
@onready var label_turno: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/LabelTurno
@onready var label_contaminacion: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/LabelContaminacion
@onready var label_puntos: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/LabelPuntos
@onready var label_mazo: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/LabelMazo
@onready var label_comodines: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/LabelComodines

# Botones deAcción
@onready var boton_jugar: Button = $BotonesAccion/BotonJugar
@onready var boton_limpiar: Button = $BotonesAccion/BotonLimpiar
@onready var boton_pasar: Button = $BotonesAccion/BotonPasar
@onready var boton_guardar: Button = $BotonesAccion/BotonGuardar
@onready var boton_menu: Button = $BotonesAccion/BotonMenu

# Retroalimentación en Tablero
@onready var label_feedback: Label = $AreaTablero/MarginContainer/VBoxTablero/LabelFeedback
@onready var label_historial: Label = $AreaTablero/MarginContainer/VBoxTablero/LabelHistorial
@onready var label_fin_juego: Label = $AreaTablero/MarginContainer/VBoxTablero/LabelFinJuego

const CARTA_VIEW_SCENE = preload("res://scenes/card_view.tscn")

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
		
	_actualizar_boton_jugar()

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

# Nota: Tengo sueño

func actualizar_metricas(turno: int, contaminacion: int, limite_contam: int, puntos: int, cartas_mazo: int, comodines_usados: int) -> void:
	if label_turno != null:
		label_turno.text = "Turno: " + str(turno)
	if label_contaminacion != null:
		label_contaminacion.text = "Contaminación: " + str(contaminacion) + " / " + str(limite_contam)
		if contaminacion >= limite_contam - 4:
			label_contaminacion.modulate = Color(1.0, 0.35, 0.35)
		else:
			label_contaminacion.modulate = Color(1, 1, 1)
	if label_puntos != null:
		label_puntos.text = "Puntos Reducción: " + str(puntos)
	if label_mazo != null:
		label_mazo.text = "Mazo Restante: " + str(cartas_mazo) + " cartas"
	if label_comodines != null:
		label_comodines.text = "Comodines Usados: " + str(comodines_usados)

func mostrar_feedback(mensaje: String, color: Color = Color(1.0, 0.95, 0.35)) -> void:
	if label_feedback != null:
		label_feedback.text = mensaje
		label_feedback.modulate = color

func actualizar_historial(logs: Array[String]) -> void:
	if label_historial != null and logs.size() > 0:
		var lineas: Array[String] = []
		var cantidad = min(4, logs.size())
		for i in range(logs.size() - cantidad, logs.size()):
			lineas.append(logs[i])
		label_historial.text = "\n".join(lineas)

func mostrar_fin_juego(mensaje: String, es_victoria: bool) -> void:
	if label_fin_juego != null:
		label_fin_juego.visible = true
		if es_victoria:
			label_fin_juego.text = mensaje
			label_fin_juego.modulate = Color(0.3, 1.0, 0.4)
		else:
			label_fin_juego.text = mensaje
			label_fin_juego.modulate = Color(1.0, 0.25, 0.25)
			
	if boton_jugar != null:
		boton_jugar.disabled = true
	if boton_limpiar != null:
		boton_limpiar.disabled = true
	if boton_pasar != null:
		boton_pasar.disabled = true

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