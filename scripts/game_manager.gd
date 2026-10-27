class_name GameManager
extends Node

var estado: EstadoJuego
var mazo: Mazo
var mano_actual: Array[Carta] = []

@export var vista_ui: MainUI

func _ready() -> void:
	call_deferred("_iniciar_o_cargar")

func _iniciar_o_cargar() -> void:
	if not PersistenciaManager.partida_cargada_pendiente.is_empty():
		var datos = PersistenciaManager.partida_cargada_pendiente.duplicate()
		PersistenciaManager.partida_cargada_pendiente.clear()
		
		if datos.get("es_nueva_partida", false) == true:
			iniciar_partida(datos.get("modo_juego", "ESTANDAR"))
		else:
			cargar_desde_datos(datos)
	else:
		iniciar_partida("ESTANDAR")

func iniciar_partida(modo_juego_seleccionado: String = "ESTANDAR") -> void:
	estado = EstadoJuego.new(21)
	estado.configurar_modo(modo_juego_seleccionado)
	mazo = Mazo.new()
	mazo.cargar_desde_json("res://assets/cartas_base.json")
	mano_actual.clear()
	conectar_senales()

	if estado.en_tutorial:
		ejecutar_paso_tutorial()
	else:
		robar_cartas(estado.cartas_a_robar)
		actualizar_pantalla()
		if vista_ui != null:
			vista_ui.set_estado_botones(true, true, true)
			vista_ui.mostrar_feedback("[INFO] Partida iniciada en Modo: " + estado.modo_juego, Color(0.4, 1.0, 0.7))

func ejecutar_paso_tutorial() -> void:
	mano_actual.clear()
	
	if estado.paso_tutorial == 0:
		mano_actual.append(extraer_carta_especifica(Carta.Categoria.ORGANICO))
		mano_actual.append(extraer_carta_especifica(Carta.Categoria.ORGANICO))
		mano_actual.append(extraer_carta_especifica(Carta.Categoria.RECICLABLE))
		
		if vista_ui != null:
			vista_ui.set_estado_botones(true, false, false)
			vista_ui.mostrar_feedback("[TUTORIAL 1/2] Selecciona SÓLO los 2 Residuos Orgánicos y presiona JUGAR.", Color.CYAN)
			
	elif estado.paso_tutorial == 1:
		mano_actual.append(extraer_carta_especifica(Carta.Categoria.EWASTE))
		mano_actual.append(extraer_carta_especifica(Carta.Categoria.RECICLABLE))
		
		if vista_ui != null:
			vista_ui.set_estado_botones(true, false, false)
			vista_ui.mostrar_feedback("[TUTORIAL 2/2] ¡Bien! Ahora procesa la Batería (E-Waste) sola.", Color.CYAN)
			
	else:
		estado.en_tutorial = false
		estado.modo_juego = "ESTANDAR"
		estado.registrar_log("[TUTORIAL] Tutorial completado. ¡Se guarda tu progreso de forma permanente!")
		
		var perfil = PersistenciaManager.cargar_perfil()
		perfil["tutorial_completado"] = true
		PersistenciaManager.guardar_perfil(perfil)
		
		if vista_ui != null:
			vista_ui.set_estado_botones(true, true, true)
			vista_ui.mostrar_feedback("[ÉXITO] ¡Tutorial completado! Buena suerte.", Color.GREEN)
		
		robar_cartas(4)
		
	actualizar_pantalla()

func extraer_carta_especifica(categoria_buscada: Carta.Categoria) -> Carta:
	for i in range(mazo.cartas.size()):
		if mazo.cartas[i].categoria == categoria_buscada:
			var carta_encontrada = mazo.cartas[i]
			mazo.cartas.pop_at(i)
			return carta_encontrada
	return null

func robar_cartas(cantidad: int) -> void:
	estado.registrar_log("[ROBO] Turno %d: Robando %d cartas." % [estado.turno, cantidad])
	
	for i in range(cantidad):
		if mazo.esta_vacio():
			if estado.modo_juego == "INFINITO" and mazo.cantidad_descarte() > 0:
				mazo.cartas = mazo.descarte.duplicate()
				mazo.descarte.clear()
				mazo.barajar()
				var msg_reciclar = "[INFINITO] ¡Mazo agotado! Descarte reciclado y rebarajado."
				estado.registrar_log(msg_reciclar)
				if vista_ui != null:
					vista_ui.mostrar_feedback(msg_reciclar, Color(0.4, 0.8, 1.0))
			else:
				break
				
		var carta_robada = mazo.robar_carta()
		if carta_robada == null:
			break
			
		if carta_robada.es_toxico():
			estado.incrementar_contaminacion(3)
			var msg_tox = "[ALERTA] ¡Robaste Agente Tóxico! +3 a la Contaminación."
			estado.registrar_log(msg_tox)
			if vista_ui != null:
				vista_ui.mostrar_feedback(msg_tox, Color(1.0, 0.4, 0.4))
				vista_ui.generar_popup_alerta("¡+3 CONTAMINACIÓN!", "#FF3333")
				
		mano_actual.append(carta_robada)
		
	estado.cartas_a_robar = 4
	verificar_mano_llena()

func procesar_jugada_seleccionada(cartas_sel: Array[Carta]) -> void:
	if cartas_sel.is_empty():
		if vista_ui != null:
			vista_ui.mostrar_feedback("[AVISO] Selecciona al menos una carta para jugar.", Color(1.0, 0.5, 0.5))
		return

	# Intercepción de Tutorial
	if estado.en_tutorial:
		if estado.paso_tutorial == 0:
			if cartas_sel.size() != 2 or not todos_del_tipo(cartas_sel, Carta.Categoria.ORGANICO):
				if vista_ui != null:
					vista_ui.mostrar_feedback("[ERROR TUTORIAL] Selecciona EXACTAMENTE los 2 orgánicos.", Color(1.0, 0.3, 0.3))
				return
		elif estado.paso_tutorial == 1:
			if cartas_sel.size() != 1 or not cartas_sel[0].es_ewaste():
				if vista_ui != null:
					vista_ui.mostrar_feedback("[ERROR TUTORIAL] Selecciona SÓLO la carta E-Waste.", Color(1.0, 0.3, 0.3))
				return

	# 0. JUGAR AS (Limpia -5 Contaminación)
	if cartas_sel.size() == 1 and cartas_sel[0].es_as():
		descartar_cartas(cartas_sel)
		estado.reducir_contaminacion(5)
		var msg = "[LIMPIEZA] ¡Jugaste un As! (-5 Contaminación)."
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(0.4, 1.0, 0.6))
			vista_ui.generar_popup_combo("¡Limpieza!", "#66ff66")
		_avanzar_tutorial_si_aplica()
		actualizar_pantalla()
		verificar_fin_juego()
		return

	# 1. PAR ORGÁNICOS
	if cartas_sel.size() == 2 and todos_del_tipo(cartas_sel, Carta.Categoria.ORGANICO):
		var suma = (cartas_sel[0].valor + cartas_sel[1].valor) * 2
		estado.actualizar_puntos(suma)
		descartar_cartas(cartas_sel)
		var msg = "[COMBO] Par de Orgánicos (+%d Pts)." % suma
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(0.4, 1.0, 0.6))
			vista_ui.generar_popup_combo("¡Par Organicos!!", "#66ff66")
		_avanzar_tutorial_si_aplica()
		actualizar_pantalla()
		verificar_fin_juego()
		return

	# 2. TERCIA RECICLABLES
	if cartas_sel.size() == 3 and todos_del_tipo(cartas_sel, Carta.Categoria.RECICLABLE):
		var suma = (cartas_sel[0].valor + cartas_sel[1].valor + cartas_sel[2].valor) * 3
		estado.actualizar_puntos(suma)
		var msg = "[COMBO] Tercia de Reciclables (+%d Pts)." % suma
		if estado.comodines_usados.size() > 0:
			var com_rec = estado.comodines_usados.pop_back()
			mano_actual.append(com_rec)
			msg += " Recuperaste " + com_rec.get_nombre() + "."
		descartar_cartas(cartas_sel)
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(0.4, 1.0, 0.6))
			vista_ui.generar_popup_combo("¡Tercia Reciclables!!", "#66ffff")
		_avanzar_tutorial_si_aplica()
		actualizar_pantalla()
		verificar_fin_juego()
		return

	# 3. PAR E-WASTE
	if cartas_sel.size() == 2 and todos_del_tipo(cartas_sel, Carta.Categoria.EWASTE):
		var suma = (cartas_sel[0].valor + cartas_sel[1].valor) * 3
		estado.actualizar_puntos(suma)
		estado.incrementar_contaminacion(1)
		descartar_cartas(cartas_sel)
		var msg = "[COMBO] Par E-Waste (+%d Pts, +1 Contaminación)." % suma
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(1.0, 0.8, 0.4))
			vista_ui.generar_popup_combo("¡Par E-waste!!", "#ffcc66")
		_avanzar_tutorial_si_aplica()
		actualizar_pantalla()
		verificar_fin_juego()
		return

	# 4. COMODINES
	var comodines: Array[Carta] = []
	var residuos: Array[Carta] = []
	for c in cartas_sel:
		if c.es_comodin():
			comodines.append(c)
		else:
			residuos.append(c)

	if comodines.size() == 1 and residuos.size() >= 1:
		var com = comodines[0]
		
		if com.comodin_subtipo == "J" and todos_del_tipo(residuos, Carta.Categoria.ORGANICO):
			var suma = 0
			for r in residuos: suma += r.valor * 2
			estado.actualizar_puntos(suma)
			estado.comodines_usados.append(com)
			mano_actual.erase(com)
			descartar_cartas(residuos)
			var msg = "[COMODIN] Comodín J (+%d Pts)." % suma
			estado.registrar_log(msg)
			if vista_ui != null:
				vista_ui.mostrar_feedback(msg, Color(0.4, 1.0, 0.6))
				vista_ui.generar_popup_combo("¡Compostera!", "#66ff66")
			actualizar_pantalla()
			verificar_fin_juego()
			return

		elif com.comodin_subtipo == "Q" and todos_del_tipo(residuos, Carta.Categoria.RECICLABLE):
			var suma = 0
			for r in residuos: suma += r.valor * 2
			estado.actualizar_puntos(suma)
			estado.comodines_usados.append(com)
			mano_actual.erase(com)
			descartar_cartas(residuos)
			var msg = "[COMODIN] Comodín Q (+%d Pts)." % suma
			estado.registrar_log(msg)
			if vista_ui != null:
				vista_ui.mostrar_feedback(msg, Color(0.4, 1.0, 0.6))
				vista_ui.generar_popup_combo("¡Recicladora!", "#66ffff")
			actualizar_pantalla()
			verificar_fin_juego()
			return

		elif com.comodin_subtipo == "K":
			var todos_validos = true
			for r in residuos:
				if not r.es_ewaste() and not r.es_toxico():
					todos_validos = false
					break
			if todos_validos:
				var suma = 0.0
				for r in residuos:
					if r.es_ewaste(): suma += (float(r.valor) * 1.5) * 2.0
				var pts = int(suma)
				estado.actualizar_puntos(pts)
				estado.comodines_usados.append(com)
				mano_actual.erase(com)
				descartar_cartas(residuos)
				var msg = "[COMODIN] Comodín K (+%d Pts)." % pts
				estado.registrar_log(msg)
				if vista_ui != null:
					vista_ui.mostrar_feedback(msg, Color(0.4, 1.0, 0.6))
					vista_ui.generar_popup_combo("¡Aislado!!", "#cc66ff")
				actualizar_pantalla()
				verificar_fin_juego()
				return

	# 5. E-WASTE INDIVIDUAL
	if cartas_sel.size() == 1 and cartas_sel[0].es_ewaste():
		var pts = int(float(cartas_sel[0].valor) * 1.5)
		estado.actualizar_puntos(pts)
		estado.incrementar_contaminacion(3)
		descartar_cartas(cartas_sel)
		var msg = "[ALERTA] 1 E-Waste procesado (+%d Pts, +3 Contaminación)." % pts
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(1.0, 0.6, 0.4))
			vista_ui.generar_popup_combo("¡E-waste!", "#ff6666")
		_avanzar_tutorial_si_aplica()
		actualizar_pantalla()
		verificar_fin_juego()
		return

	# Combo No Válido
	var msg_error = "[ERROR] Combinación no válida."
	estado.registrar_log(msg_error)
	if vista_ui != null:
		vista_ui.mostrar_feedback(msg_error, Color(1.0, 0.35, 0.35))

func _avanzar_tutorial_si_aplica() -> void:
	if estado.en_tutorial:
		estado.paso_tutorial += 1
		ejecutar_paso_tutorial()

func verificar_fin_juego() -> bool:
	if estado.es_derrota():
		var msg = "[DERROTA] Nivel de contaminación máximo alcanzado (%d / %d)." % [estado.get_contaminacion_actual(), estado.limite_contaminacion]
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(1.0, 0.25, 0.25))
			vista_ui.mostrar_fin_juego(msg, false)
		return true
		
	elif mazo.esta_vacio() and mano_actual.is_empty() and estado.modo_juego != "INFINITO":
		var msg = "[VICTORIA] Vaciaste el mazo y procesaste todos los residuos. Puntos Finales: %d" % estado.get_puntos_reduccion()
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(0.3, 1.0, 0.4))
			vista_ui.mostrar_fin_juego(msg, true)
		return true
		
	return false

# Resto de funciones asociadas (limpiar_mano, aplicar_sinergias_negativas, terminar_turno, actualizar_pantalla, guardar_progreso, etc.)
func cargar_desde_datos(datos: Dictionary) -> void:
	conectar_senales()
	estado = EstadoJuego.new(datos.get("limite_contaminacion", 21))
	estado.configurar_modo(datos.get("modo_juego", "ESTANDAR"))
	estado.actualizar_puntos(datos.get("puntos_reduccion", 0))
	estado.incrementar_contaminacion(datos.get("contaminacion_actual", 0))
	estado.turno = datos.get("turno", 1)
	
	if datos.has("logs"):
		estado.logs.clear()
		for l in datos["logs"]: estado.logs.append(str(l))

	mazo = Mazo.new()
	mazo.cargar_desde_json("res://assets/cartas_base.json")
	
	var deserializar_carta = func(d: Dictionary) -> Carta:
		return Carta.new(d.get("id", ""), d.get("nombre", ""), d.get("tipo", Carta.Tipo.RESIDUO) as Carta.Tipo, d.get("valor", 0), d.get("base_texture", ""), d.get("icon_texture", ""))

	mano_actual.clear()
	var ids_a_remover: Array[String] = []
	if datos.has("mano"):
		for d in datos["mano"]:
			var c = deserializar_carta.call(d)
			mano_actual.append(c)
			ids_a_remover.append(c.id)

	estado.comodines_usados.clear()
	if datos.has("comodines_usados"):
		for d in datos["comodines_usados"]:
			var com = deserializar_carta.call(d)
			estado.comodines_usados.append(com)
			ids_a_remover.append(com.id)

	for id_rem in ids_a_remover:
		for mazo_card in mazo.cartas:
			if mazo_card.id == id_rem:
				mazo.cartas.erase(mazo_card)
				break

	actualizar_pantalla()

func conectar_senales() -> void:
	if vista_ui == null: return
	if not vista_ui.jugar_combo.is_connected(procesar_jugada_seleccionada): vista_ui.jugar_combo.connect(procesar_jugada_seleccionada)
	if not vista_ui.limpiar_mano_solicitada.is_connected(limpiar_mano): vista_ui.limpiar_mano_solicitada.connect(limpiar_mano)
	if not vista_ui.pasar_turno.is_connected(terminar_turno): vista_ui.pasar_turno.connect(terminar_turno)
	if not vista_ui.guardar_juego.is_connected(guardar_progreso): vista_ui.guardar_juego.connect(guardar_progreso)

func verificar_mano_llena() -> void:
	if mano_actual.size() >= estado.limite_mano:
		var cant = mano_actual.size()
		var msg = "[ALERTA] ¡DESBORDAMIENTO! +5 Contaminación."
		estado.incrementar_contaminacion(5)
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(1.0, 0.3, 0.3))
			vista_ui.generar_popup_alerta("¡+5 DESBORDAMIENTO!", "#FF2222")
		for c in mano_actual: mazo.agregar_a_descarte(c)
		mano_actual.clear()


func descartar_cartas(cartas_a_descartar: Array[Carta]) -> void:
	for c in cartas_a_descartar:
		mano_actual.erase(c)
		if not c.es_comodin(): mazo.agregar_a_descarte(c)

func todos_del_tipo(lista: Array[Carta], cat: Carta.Categoria) -> bool:
	for c in lista:
		if c.categoria != cat: return false
	return true

func limpiar_mano() -> void:
	if mano_actual.is_empty():
		if vista_ui != null:
			vista_ui.mostrar_feedback("[AVISO] Tu mano ya está vacía.", Color(1.0, 0.8, 0.4))
		return
		
	# Declaración de la variable 'cant' ANTES de usarla en el mensaje
	var cant: int = mano_actual.size()

	for c in mano_actual:
		mazo.agregar_a_descarte(c)
	mano_actual.clear()
	
	estado.incrementar_contaminacion(5)
	var msg = "[DESCARTE] Descartaste voluntariamente %d cartas. +5 Contaminación." % cant
	estado.registrar_log(msg)
	
	if vista_ui != null:
		vista_ui.mostrar_feedback(msg, Color(1.0, 0.4, 0.4))
		vista_ui.generar_popup_alerta("¡+5 DESCARTE!", "#FF4444")
		
	actualizar_pantalla()
	verificar_fin_juego()

func aplicar_sinergias_negativas() -> void:
	var organicos: Array[Carta] = []
	var reciclables: Array[Carta] = []
	var ewaste: Array[Carta] = []
	var toxicos: Array[Carta] = []
	
	for c in mano_actual:
		if c.es_organico(): organicos.append(c)
		elif c.es_reciclable(): reciclables.append(c)
		elif c.es_ewaste(): ewaste.append(c)
		elif c.es_toxico(): toxicos.append(c)

# 1. Orgánico + Reciclable
	if organicos.size() > 0 and reciclables.size() > 0:
		estado.incrementar_contaminacion(1)
		for c in reciclables: c.contaminar()
		if vista_ui != null:
			vista_ui.generar_popup_alerta("¡+1 CONTAMINACIÓN!", "#FF6633")

	# 2. Orgánico + E-Waste
	if organicos.size() > 0 and ewaste.size() > 0:
		estado.incrementar_contaminacion(4)
		if vista_ui != null:
			vista_ui.generar_popup_alerta("¡+4 CONTAM. (E-WASTE)!", "#FF3333")

	# 3. Retención de Orgánicos
	if organicos.size() >= 2:
		estado.incrementar_contaminacion(5)
		estado.cartas_a_robar = 3
		if vista_ui != null:
			vista_ui.generar_popup_alerta("¡+5 DESCOMPOSICIÓN!", "#FF2222")
	elif organicos.size() == 1:
		estado.incrementar_contaminacion(2)
		if vista_ui != null:
			vista_ui.generar_popup_alerta("¡+2 CONTAMINACIÓN!", "#FF5533")

	# 5. Retención de Tóxicos
	if toxicos.size() > 0:
		var pts_tox = toxicos.size()
		estado.incrementar_contaminacion(pts_tox)
		if vista_ui != null:
			vista_ui.generar_popup_alerta("¡+%d TÓXICOS EN MANO!" % pts_tox, "#FF2222")

func terminar_turno() -> void:
	aplicar_sinergias_negativas()
	verificar_mano_llena()
	if verificar_fin_juego():
		actualizar_pantalla()
		return
	estado.turno += 1
	robar_cartas(estado.cartas_a_robar)
	verificar_fin_juego()
	actualizar_pantalla()

func actualizar_pantalla() -> void:
	if vista_ui != null:
		vista_ui.renderizar_mano(mano_actual)
		vista_ui.actualizar_metricas(
			estado.turno,
			estado.get_contaminacion_actual(),
			estado.limite_contaminacion,
			estado.get_puntos_reduccion(),
			mazo.cantidad_restante(),
			estado.comodines_usados.size()
		)
		vista_ui.actualizar_historial(estado.logs)

func guardar_progreso() -> void:
	var exito = PersistenciaManager.guardar_partida(estado, mano_actual, estado.comodines_usados, estado.logs)
	if vista_ui != null:
		if exito: vista_ui.mostrar_feedback("[GUARDADO] Partida guardada con éxito.", Color(0.5, 1.0, 0.5))
		else: vista_ui.mostrar_feedback("[ERROR] Error al guardar partida.", Color(1.0, 0.4, 0.4))