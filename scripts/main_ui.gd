class_name MainUI
extends Control

signal jugar_combo(cartas: Array[Carta])
signal limpiar_mano_solicitada
signal pasar_turno
signal guardar_juego

@onready var contenedor_mano: HBoxContainer = $ContenedorMano
@onready var label_limite_mano: Label = $LabelLimiteMano

# Métricas
@onready var panel_metricas_container: PanelContainer = $PanelMetricasContainer
@onready var label_turno: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/LabelTurno
@onready var barra_contaminacion: TextureProgressBar = $PanelMetricasContainer/MarginContainer/PanelMetricas/ContenedorContaminacion/BarraContaminacion
@onready var titulo_contaminacion: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/ContenedorContaminacion/TituloContaminacion
@onready var valor_puntos: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/ContenedorPuntos/ValorPuntos
@onready var valor_mazo: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/ContenedorMazo/ValorMazo
@onready var label_comodines: Label = $PanelMetricasContainer/MarginContainer/PanelMetricas/LabelComodines

# Botones de Acción
@onready var botones_accion: HBoxContainer = $BotonesAccion
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

# Panel de Efectos Negativos Retráctil
@onready var panel_negativos: Panel = $PanelNegativos
@onready var boton_toggle_negativos: Button = $PanelNegativos/BotonToggleNegativos
var panel_negativos_abierto: bool = false

# Modal Fin juego
@onready var modal_fin_juego: ColorRect = $ModalFinJuego
@onready var label_titulo_fin: Label = $ModalFinJuego/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LabelTituloFin
@onready var label_mensaje_fin: Label = $ModalFinJuego/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LabelMensajeFin
@onready var boton_reintentar: Button = $ModalFinJuego/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContenedorBotonesFin/BotonReintentar
@onready var boton_menu_fin: Button = $ModalFinJuego/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContenedorBotonesFin/BotonMenuFin

# Modal Tutorial Completo Guía
@onready var modal_tutorial_guia: PanelContainer = $ModalTutorialGuia
@onready var label_titulo_tutorial: Label = $ModalTutorialGuia/MarginContainer/VBoxContainer/LabelTituloTutorial
@onready var texto_tutorial: RichTextLabel = $ModalTutorialGuia/MarginContainer/VBoxContainer/ContenedorDemostracion/TextoExplicacionTutorial
@onready var contenedor_cartas_demo: HBoxContainer = $ModalTutorialGuia/MarginContainer/VBoxContainer/ContenedorDemostracion/ContenedorCartasDemo
@onready var boton_siguiente_tutorial: Button = $ModalTutorialGuia/MarginContainer/VBoxContainer/ContenedorBotonGuia/BotonSiguienteTutorial

# Modal Tutorial Finalizado
@onready var modal_tutorial_finalizado: ColorRect = $ModalTutorialFinalizado
@onready var label_titulo_finalizado: Label = $ModalTutorialFinalizado/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LabelTituloFinalizado
@onready var label_mensaje_finalizado: Label = $ModalTutorialFinalizado/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LabelMensajeFinalizado
@onready var boton_entendido_tutorial: Button = $ModalTutorialFinalizado/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ContenedorBotonFinalizado/BotonEntendidoTutorial

const CARTA_VIEW_SCENE = preload("res://scenes/card_view.tscn")
const COMBO_VFX_SCENE = preload("res://scenes/combo_vfx.tscn")

var cartas_seleccionadas: Array[Carta] = []

# Control de Tutorial Completo Interactivo
const TOTAL_PASOS_TUTORIAL: int = 10
var paso_tutorial_completo: int = 1
var tween_resaltado: Tween = null
var nodo_resaltado_actual: CanvasItem = null

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
	if boton_toggle_negativos != null:
		boton_toggle_negativos.pressed.connect(_on_boton_toggle_negativos_pressed)
	if boton_historial != null:
		boton_historial.pressed.connect(_on_abrir_historial)
	if boton_cerrar_historial != null:
		boton_cerrar_historial.pressed.connect(_on_cerrar_historial)
	if boton_reintentar != null:
		boton_reintentar.pressed.connect(_on_reintentar_pressed)
	if boton_menu_fin != null:
		boton_menu_fin.pressed.connect(_on_boton_menu_pressed)
		
	# Conectar botones del Tutorial Completo
	if boton_siguiente_tutorial != null and not boton_siguiente_tutorial.pressed.is_connected(_on_boton_siguiente_tutorial_pressed):
		boton_siguiente_tutorial.pressed.connect(_on_boton_siguiente_tutorial_pressed)
	if boton_entendido_tutorial != null and not boton_entendido_tutorial.pressed.is_connected(_on_boton_entendido_tutorial_pressed):
		boton_entendido_tutorial.pressed.connect(_on_boton_entendido_tutorial_pressed)
		
	if label_limite_mano != null:
		label_limite_mano.text = "0/10"
		
	_actualizar_boton_jugar()

# --- Flujo del Tutorial Completo Interactivo ---

func iniciar_tutorial_completo() -> void:
	paso_tutorial_completo = 1
	avanzar_paso_tutorial_completo(1)

func avanzar_paso_tutorial_completo(paso: int) -> void:
	paso_tutorial_completo = paso
	
	if paso > TOTAL_PASOS_TUTORIAL:
		finalizar_tutorial_completo()
		return
		
	if modal_tutorial_guia != null:
		modal_tutorial_guia.visible = true
		
	if boton_siguiente_tutorial != null:
		boton_siguiente_tutorial.text = "SIGUIENTE (" + str(paso) + "/" + str(TOTAL_PASOS_TUTORIAL) + ")"
		
	_limpiar_resaltado()
	
	match paso:
		1:
			# Paso 1: Métricas de Juego
			desplegar_panel_combos(false)
			desplegar_panel_negativos(false)
			_mostrar_cartas_demo([])
			if label_titulo_tutorial != null:
				label_titulo_tutorial.text = "PASO 1: MÉTRICAS DE JUEGO"
			if texto_tutorial != null:
				texto_tutorial.text = "[b]Panel de Métricas:[/b]\n" \
					+ "• [b]Turno:[/b] Número de turno actual.\n" \
					+ "• [b]Contaminación:[/b] Barra que sube con el residuo sin tratar; si llega al límite se pierde la partida.\n" \
					+ "• [b]Puntos de Reducción:[/b] Puntaje acumulado por procesar combos.\n" \
					+ "• [b]Mazo y Comodines Usados:[/b] Cantidad de cartas restantes y comodines activos."
			if panel_metricas_container != null:
				_resaltar_nodo(panel_metricas_container)
		2:
			# Paso 2: Tipos de Cartas en Mano
			desplegar_panel_combos(false)
			desplegar_panel_negativos(false)
			_mostrar_cartas_demo([])
			if label_titulo_tutorial != null:
				label_titulo_tutorial.text = "PASO 2: TIPOS DE CARTAS EN MANO"
			if texto_tutorial != null:
				texto_tutorial.text = "Hay distintas cartas: Orgánicas, Reciclables, E-Waste, Tóxicas y Comodines especiales (Compostera, Recicladora, Aislamiento y Limpieza).\n\nEn tu mano puedes ver ejemplos de cada una."
			if contenedor_mano != null:
				_resaltar_nodo(contenedor_mano)
		3:
			# Paso 3: Orgánicas y Compostera (J)
			desplegar_panel_combos(false)
			desplegar_panel_negativos(false)
			var carta_org = _crear_carta_demo("org_apple_01", "Manzana", Carta.Tipo.RESIDUO, 2, "res://assets/BaseCard_organic.png", "res://assets/icons/apple.png")
			var carta_j = _crear_carta_demo("wild_j_01", "Compostera", Carta.Tipo.COMODIN, 5, "res://assets/BaseCard_wildcard.png", "res://assets/icons/J.png")
			_mostrar_cartas_demo([carta_org, carta_j])
			if label_titulo_tutorial != null:
				label_titulo_tutorial.text = "PASO 3: ORGÁNICAS Y COMPOSTERA (J)"
			if texto_tutorial != null:
				texto_tutorial.text = "• [b]Orgánicas:[/b] Forman pares (Suma x2), pero si las retienes al final del turno generan descomposición (+2 o +5 de contaminación).\n\n• [b]Compostera (J):[/b] Combínala con residuos orgánicos para multiplicar sus puntos sin dejar residuos ni generar penalizaciones."
		4:
			# Paso 4: Reciclables y Recicladora
			desplegar_panel_combos(false)
			desplegar_panel_negativos(false)
			var carta_rec = _crear_carta_demo("rec_box_01", "Cartón", Carta.Tipo.RESIDUO, 3, "res://assets/BaseCard_recyclable.png", "res://assets/icons/cardboard_box.png")
			var carta_q = _crear_carta_demo("wild_q_01", "Recicladora", Carta.Tipo.COMODIN, 3, "res://assets/BaseCard_wildcard.png", "res://assets/icons/Q.png")
			_mostrar_cartas_demo([carta_rec, carta_q])
			if label_titulo_tutorial != null:
				label_titulo_tutorial.text = "PASO 4: RECICLABLES Y RECICLADORA (Q)"
			if texto_tutorial != null:
				texto_tutorial.text = "• [b]Reciclables:[/b] Forman tercias (Suma x3) y recuperan un comodín usado previamente para devolverlo a tu mano.\n\n• [b]Recicladora (Q):[/b] Puedes combinarla con cartas reciclables para potenciar su procesamiento y sumar valiosos puntos."
		5:
			# Paso 5: E-Waste y Contención
			desplegar_panel_combos(false)
			desplegar_panel_negativos(false)
			var carta_ewaste = _crear_carta_demo("ewaste_battery_01", "Batería", Carta.Tipo.RESIDUO, 5, "res://assets/BaseCard_ewaste.png", "res://assets/icons/battery.png")
			var carta_k1 = _crear_carta_demo("wild_k_01", "Contención", Carta.Tipo.COMODIN, 0, "res://assets/BaseCard_wildcard.png", "res://assets/icons/anti_toxic.png")
			_mostrar_cartas_demo([carta_ewaste, carta_k1])
			if label_titulo_tutorial != null:
				label_titulo_tutorial.text = "PASO 5: E-WASTE Y CONTENCIÓN (K)"
			if texto_tutorial != null:
				texto_tutorial.text = "• [b]E-Waste:[/b] Dan muchos puntos pero aumentan la contaminación si se juegan solos (+3) o en pares sin aislar (+1).\n\n• [b]Contención (K):[/b] Neutraliza residuos de E-Waste y tóxicos, evitando la contaminación y otorgando bonus de puntos."
		6:
			# Paso 6: Tóxicas y Contención
			desplegar_panel_combos(false)
			desplegar_panel_negativos(false)
			var carta_tox = _crear_carta_demo("toxic_waste_01", "Tóxico", Carta.Tipo.RESIDUO, 6, "res://assets/BaseCard_toxic.png", "res://assets/icons/toxic_barrel.png")
			var carta_k2 = _crear_carta_demo("wild_k_01", "Contención", Carta.Tipo.COMODIN, 0, "res://assets/BaseCard_wildcard.png", "res://assets/icons/anti_toxic.png")
			_mostrar_cartas_demo([carta_tox, carta_k2])
			if label_titulo_tutorial != null:
				label_titulo_tutorial.text = "PASO 6: TÓXICAS Y CONTENCIÓN (K)"
			if texto_tutorial != null:
				texto_tutorial.text = "• [b]Tóxicas:[/b] Al robarlas suman +3 inmediato a la contaminación y +1 por cada una que retengas al final del turno.\n\n• [b]Contención (K):[/b] Combina el Comodín K con residuos tóxicos para eliminarlos con seguridad sin sufrir penalizaciones."
		7:
			# Paso 7: Limpieza
			desplegar_panel_combos(false)
			desplegar_panel_negativos(false)
			var carta_as = _crear_carta_demo("wild_ace_01", "Limpieza", Carta.Tipo.TRATAMIENTO, -5, "res://assets/BaseCard_wildcard.png", "res://assets/icons/Ace.png")
			_mostrar_cartas_demo([carta_as])
			if label_titulo_tutorial != null:
				label_titulo_tutorial.text = "PASO 7: CARTA DE LIMPIEZA (AS)"
			if texto_tutorial != null:
				texto_tutorial.text = "• [b]Limpieza (As):[/b] ¡Tu mejor salvavidas ambiental!\n\nJugar un As solo reduce inmediatamente -5 puntos de contaminación acumulada de tu barra de peligro."
		8:
			# Paso 8: Panel de Combos (desplegado y resaltado)
			desplegar_panel_negativos(false)
			desplegar_panel_combos(true)
			_mostrar_cartas_demo([])
			if label_titulo_tutorial != null:
				label_titulo_tutorial.text = "PASO 8: PANEL DE COMBOS"
			if texto_tutorial != null:
				texto_tutorial.text = "Se ha desplegado el [b]Panel de Combos[/b]. Consúltalo en cualquier momento durante la partida para verificar las combinaciones válidas y cómo maximizar tus puntos de reducción."
			if panel_combos != null:
				_resaltar_nodo(panel_combos)
		9:
			# Paso 9: Panel de Efectos Negativos / Alertas (desplegado y resaltado)
			desplegar_panel_combos(false)
			desplegar_panel_negativos(true)
			_mostrar_cartas_demo([])
			if label_titulo_tutorial != null:
				label_titulo_tutorial.text = "PASO 9: PANEL DE EFECTOS NEGATIVOS (ALERTAS)"
			if texto_tutorial != null:
				texto_tutorial.text = "Se ha desplegado el [b]Panel de Alertas Negativas[/b]. Aquí se detallan todas las penalizaciones por mezclar residuos incompatibles, retener cartas en mano o desbordar la capacidad de tu mano."
			if panel_negativos != null:
				_resaltar_nodo(panel_negativos)
		10:
			# Paso 10: Acciones del Jugador (Jugar, Pasar Turno, Descartar mano, Ver Historial)
			desplegar_panel_combos(false)
			desplegar_panel_negativos(false)
			_mostrar_cartas_demo([])
			if label_titulo_tutorial != null:
				label_titulo_tutorial.text = "PASO 10: ACCIONES DEL JUGADOR"
			if texto_tutorial != null:
				texto_tutorial.text = "[b]Botones de Acción Disponibles:[/b]\n" \
					+ "• [b]JUGAR:[/b] Procesa las cartas seleccionadas si forman una combinación válida.\n" \
					+ "• [b]PASAR TURNO:[/b] Aplica efectos del turno y roba nuevas cartas del mazo.\n" \
					+ "• [b]Descartar mano:[/b] Descarta toda tu mano voluntariamente (+5 contaminación de penalización).\n" \
					+ "• [b]VER HISTORIAL:[/b] Consulta el registro detallado de eventos y jugadas."
			if botones_accion != null:
				_resaltar_nodo(botones_accion)
		_:
			finalizar_tutorial_completo()

func _crear_carta_demo(id: String, nombre: String, tipo: Carta.Tipo, valor: int, base_path: String, icon_path: String) -> Carta:
	var c = Carta.new(id, nombre, tipo, valor, base_path, icon_path)
	return c

func _mostrar_cartas_demo(cartas: Array[Carta]) -> void:
	if contenedor_cartas_demo == null:
		return
	for child in contenedor_cartas_demo.get_children():
		child.queue_free()
	if cartas.is_empty():
		contenedor_cartas_demo.visible = false
		return
	contenedor_cartas_demo.visible = true
	for c in cartas:
		var card_view = CARTA_VIEW_SCENE.instantiate()
		contenedor_cartas_demo.add_child(card_view)
		if card_view.has_method("cargar_carta"):
			card_view.cargar_carta(c)
		card_view.mouse_filter = Control.MOUSE_FILTER_IGNORE

func finalizar_tutorial_completo() -> void:
	_limpiar_resaltado()
	desplegar_panel_combos(false)
	desplegar_panel_negativos(false)
	_mostrar_cartas_demo([])
	
	var gm = get_node_or_null("GameManager")
	if gm != null and gm.estado != null and gm.estado.modo_juego == "ONBOARDING_COMPLETO":
		if modal_tutorial_guia != null:
			modal_tutorial_guia.visible = false
		gm.iniciar_tutorial_practico()
		return
		
	if modal_tutorial_guia != null:
		modal_tutorial_guia.visible = false
		
	if modal_tutorial_finalizado != null:
		modal_tutorial_finalizado.visible = true
		if label_mensaje_finalizado != null:
			label_mensaje_finalizado.text = "¡Tutorial terminado, se regresa al menú!"

func _on_boton_siguiente_tutorial_pressed() -> void:
	avanzar_paso_tutorial_completo(paso_tutorial_completo + 1)

func _on_boton_entendido_tutorial_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func desplegar_panel_combos(abrir: bool) -> void:
	if panel_combos == null:
		return
	panel_combos_abierto = abrir
	if panel_combos_abierto and panel_negativos_abierto:
		desplegar_panel_negativos(false)
	if boton_toggle_combos != null:
		boton_toggle_combos.text = "<" if panel_combos_abierto else "C\nO\nM\nB\nO\nS"
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel_combos, "position:x", 0.0 if panel_combos_abierto else -300.0, 0.4)

func desplegar_panel_negativos(abrir: bool) -> void:
	if panel_negativos == null:
		return
	panel_negativos_abierto = abrir
	if panel_negativos_abierto and panel_combos_abierto:
		desplegar_panel_combos(false)
	if boton_toggle_negativos != null:
		boton_toggle_negativos.text = "<" if panel_negativos_abierto else "A\nL\nE\nR\nT\nA\nS"
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel_negativos, "position:x", 0.0 if panel_negativos_abierto else -300.0, 0.4)

func _resaltar_nodo(nodo: CanvasItem) -> void:
	_limpiar_resaltado()
	if nodo == null:
		return
	nodo_resaltado_actual = nodo
	tween_resaltado = create_tween().set_loops()
	tween_resaltado.tween_property(nodo, "modulate", Color(0.6, 1.0, 0.8, 1.0), 0.5)
	tween_resaltado.tween_property(nodo, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5)

func _limpiar_resaltado() -> void:
	if tween_resaltado != null and tween_resaltado.is_valid():
		tween_resaltado.kill()
		tween_resaltado = null
	if nodo_resaltado_actual != null:
		nodo_resaltado_actual.modulate = Color(1.0, 1.0, 1.0, 1.0)
		nodo_resaltado_actual = null

# --- Fin Flujo Tutorial Completo ---

func _on_reintentar_pressed() -> void:
	get_tree().reload_current_scene()

var ultimo_offset_popup: Vector2 = Vector2.ZERO

func _obtener_posicion_popup_variada() -> Vector2:
	var viewport_size = get_viewport_rect().size
	var centro = viewport_size / 2.0
	var offset = Vector2(
		randf_range(-180.0, 180.0),
		randf_range(-80.0, 70.0)
	)
	if offset.distance_to(ultimo_offset_popup) < 60.0:
		offset.x += 75.0 if offset.x <= 0 else -75.0
		offset.y += 40.0 if offset.y <= 0 else -40.0
	ultimo_offset_popup = offset
	return centro + offset

func generar_popup_alerta(texto_efecto: String, color_hex: String = "#FF3333") -> void:
	var pos_popup = _obtener_posicion_popup_variada()
	var vfx = COMBO_VFX_SCENE.instantiate()
	add_child(vfx)
	vfx.global_position = pos_popup
	
	if vfx.has_method("configurar"):
		vfx.configurar(texto_efecto, pos_popup, color_hex)

func generar_popup_combo(texto_efecto: String, color_hex: String = "#FFD700") -> void:
	var pos_popup = _obtener_posicion_popup_variada()
	var vfx = COMBO_VFX_SCENE.instantiate()
	add_child(vfx)
	vfx.global_position = pos_popup
	
	if vfx.has_method("configurar"):
		vfx.configurar(texto_efecto, pos_popup, color_hex)

func renderizar_mano(mano: Array[Carta], limite_mano: int = 10) -> void:
	cartas_seleccionadas.clear()
	_actualizar_boton_jugar()
	
	if label_limite_mano != null:
		label_limite_mano.text = str(mano.size()) + "/" + str(limite_mano)
	
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
	desplegar_panel_combos(not panel_combos_abierto)

func _on_boton_toggle_negativos_pressed() -> void:
	desplegar_panel_negativos(not panel_negativos_abierto)

func _on_abrir_historial() -> void:
	if modal_historial != null: modal_historial.visible = true

func _on_cerrar_historial() -> void:
	if modal_historial != null: modal_historial.visible = false
