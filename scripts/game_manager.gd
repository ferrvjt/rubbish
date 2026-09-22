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
		cargar_desde_datos(datos)
	else:
		iniciar_partida()

func iniciar_partida() -> void:
	# 1. Instanciar Partida y Mazo
	estado = EstadoJuego.new(21)
	mazo = Mazo.new()

	# 2. Cargar cartas y barajar
	mazo.cargar_desde_json("res://assets/cartas_base.json")
	mano_actual.clear()

	# 3. Conectar señales con MainUI
	conectar_senales()

	# 4. Robar mano inicial (4 cartas según app.py)
	robar_cartas(estado.cartas_a_robar)

	# 5. Actualizar vista inicial
	actualizar_pantalla()
	if vista_ui != null:
		vista_ui.mostrar_feedback("[INFO] Turno 1 iniciado. Selecciona cartas y presiona JUGAR.", Color(0.4, 1.0, 0.7))

func cargar_desde_datos(datos: Dictionary) -> void:
	conectar_senales()
	
	# 1. Reconstruir estado
	estado = EstadoJuego.new(datos.get("limite_contaminacion", 21))
	estado.actualizar_puntos(datos.get("puntos_reduccion", 0))
	estado.incrementar_contaminacion(datos.get("contaminacion_actual", 0))
	estado.turno = datos.get("turno", 1)
	estado.cartas_a_robar = datos.get("cartas_a_robar", 4)
	estado.limite_mano = datos.get("limite_mano", 10)
	estado.estado_partida = datos.get("estado_partida", "JUGANDO")
	
	if datos.has("logs"):
		estado.logs.clear()
		for l in datos["logs"]:
			estado.logs.append(str(l))

	# 2. Reconstruir mazo completo
	mazo = Mazo.new()
	mazo.cargar_desde_json("res://assets/cartas_base.json")
	
	var deserializar_carta = func(d: Dictionary) -> Carta:
		return Carta.new(
			d.get("id", ""),
			d.get("nombre", ""),
			d.get("tipo", Carta.Tipo.RESIDUO) as Carta.Tipo,
			d.get("valor", 0),
			d.get("base_texture", ""),
			d.get("icon_texture", "")
		)

	# 3. Restaurar mano
	mano_actual.clear()
	var ids_a_remover_del_mazo: Array[String] = []
	if datos.has("mano"):
		for d in datos["mano"]:
			var c = deserializar_carta.call(d)
			mano_actual.append(c)
			ids_a_remover_del_mazo.append(c.id)

	# 4. Restaurar comodines usados
	estado.comodines_usados.clear()
	if datos.has("comodines_usados"):
		for d in datos["comodines_usados"]:
			var com = deserializar_carta.call(d)
			estado.comodines_usados.append(com)
			ids_a_remover_del_mazo.append(com.id)

	# Remover cartas que ya están en mano o comodines del mazo
	for id_rem in ids_a_remover_del_mazo:
		for mazo_card in mazo.cartas:
			if mazo_card.id == id_rem:
				mazo.cartas.erase(mazo_card)
				break

	estado.registrar_log("[CARGA] Partida cargada con éxito. Turno: " + str(estado.turno))
	actualizar_pantalla()
	if vista_ui != null:
		vista_ui.mostrar_feedback("[CARGA] Partida restaurada exitosamente.", Color(0.4, 1.0, 0.7))

func conectar_senales() -> void:
	if vista_ui == null:
		return
	if not vista_ui.jugar_combo.is_connected(procesar_jugada_seleccionada):
		vista_ui.jugar_combo.connect(procesar_jugada_seleccionada)
	if not vista_ui.limpiar_mano_solicitada.is_connected(limpiar_mano):
		vista_ui.limpiar_mano_solicitada.connect(limpiar_mano)
	if not vista_ui.pasar_turno.is_connected(terminar_turno):
		vista_ui.pasar_turno.connect(terminar_turno)
	if not vista_ui.guardar_juego.is_connected(guardar_progreso):
		vista_ui.guardar_juego.connect(guardar_progreso)

func robar_cartas(cantidad: int) -> void:
	estado.registrar_log("[ROBO] Turno %d: Robando %d cartas." % [estado.turno, cantidad])
	
	for i in range(cantidad):
		if mazo.esta_vacio():
			break
		var carta_robada = mazo.robar_carta()
		if carta_robada == null:
			break
			
		# Agentes tóxicos al ser tomados suman +3 a contaminación de inmediato
		if carta_robada.es_toxico():
			estado.incrementar_contaminacion(3)
			var msg_tox = "[ALERTA] ¡Robaste Agente Tóxico! +3 a la Contaminación."
			estado.registrar_log(msg_tox)
			if vista_ui != null:
				vista_ui.mostrar_feedback(msg_tox, Color(1.0, 0.4, 0.4))
				
		mano_actual.append(carta_robada)
		print("Se robó: ", carta_robada.get_nombre())
		
	# Restablecer cartas a robar por defecto
	estado.cartas_a_robar = 4
	verificar_mano_llena()

func verificar_mano_llena() -> void:
	if mano_actual.size() >= estado.limite_mano:
		var cant = mano_actual.size()
		var msg = "[ALERTA] ¡DESBORDAMIENTO! Mano con %d cartas. +5 Contaminación y mano descartada." % cant
		estado.incrementar_contaminacion(5)
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(1.0, 0.3, 0.3))
		for c in mano_actual:
			mazo.agregar_a_descarte(c)
		mano_actual.clear()

func descartar_cartas(cartas_a_descartar: Array[Carta]) -> void:
	for c in cartas_a_descartar:
		mano_actual.erase(c)
		if not c.es_comodin():
			mazo.agregar_a_descarte(c)

func todos_del_tipo(lista: Array[Carta], cat: Carta.Categoria) -> bool:
	for c in lista:
		if c.categoria != cat:
			return false
	return true

func procesar_jugada_seleccionada(cartas_sel: Array[Carta]) -> void:
	if cartas_sel.is_empty():
		if vista_ui != null:
			vista_ui.mostrar_feedback("[AVISO] Selecciona al menos una carta para jugar.", Color(1.0, 0.5, 0.5))
		return

	# 0. JUGAR AS (Limpia -5 Contaminación)
	if cartas_sel.size() == 1 and cartas_sel[0].es_as():
		descartar_cartas(cartas_sel)
		estado.reducir_contaminacion(5)
		var msg = "[LIMPIEZA] ¡Jugaste un As! (-5 Contaminación)."
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(0.4, 1.0, 0.6))
		actualizar_pantalla()
		return

	# 1. PAR ORGÁNICOS: 2 orgánicos, Puntos = Suma * 2
	if cartas_sel.size() == 2 and todos_del_tipo(cartas_sel, Carta.Categoria.ORGANICO):
		var suma = (cartas_sel[0].valor + cartas_sel[1].valor) * 2
		estado.actualizar_puntos(suma)
		descartar_cartas(cartas_sel)
		var msg = "[COMBO] Par de Orgánicos (+%d Pts)." % suma
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(0.4, 1.0, 0.6))
		actualizar_pantalla()
		return

	# 2. TERCIA RECICLABLES: 3 reciclables, Puntos = Suma * 3, Recupera 1 comodín usado
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
		actualizar_pantalla()
		return

	# 3. PAR E-WASTE: 2 e-waste, Puntos = Suma * 3, +1 Contaminación
	if cartas_sel.size() == 2 and todos_del_tipo(cartas_sel, Carta.Categoria.EWASTE):
		var suma = (cartas_sel[0].valor + cartas_sel[1].valor) * 3
		estado.actualizar_puntos(suma)
		estado.incrementar_contaminacion(1)
		descartar_cartas(cartas_sel)
		var msg = "[COMBO] Par E-Waste (+%d Pts, +1 Contaminación)." % suma
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(1.0, 0.8, 0.4))
		actualizar_pantalla()
		verificar_fin_juego()
		return

	# 4. COMODINES (1 Comodín + Residuos >= 1)
	var comodines: Array[Carta] = []
	var residuos: Array[Carta] = []
	for c in cartas_sel:
		if c.es_comodin():
			comodines.append(c)
		else:
			residuos.append(c)

	if comodines.size() == 1 and residuos.size() >= 1:
		var com = comodines[0]
		
		# Comodín J (Compostera) + Orgánicos: suma * 2
		if com.comodin_subtipo == "J" and todos_del_tipo(residuos, Carta.Categoria.ORGANICO):
			var suma = 0
			for r in residuos:
				suma += r.valor * 2
			estado.actualizar_puntos(suma)
			estado.comodines_usados.append(com)
			mano_actual.erase(com)
			descartar_cartas(residuos)
			var msg = "[COMODIN] Comodín J (Compostera) (+%d Pts)." % suma
			estado.registrar_log(msg)
			if vista_ui != null:
				vista_ui.mostrar_feedback(msg, Color(0.4, 1.0, 0.6))
			actualizar_pantalla()
			return

		# Comodín Q (Reciclaje) + Reciclables: suma * 2
		elif com.comodin_subtipo == "Q" and todos_del_tipo(residuos, Carta.Categoria.RECICLABLE):
			var suma = 0
			for r in residuos:
				suma += r.valor * 2
			estado.actualizar_puntos(suma)
			estado.comodines_usados.append(com)
			mano_actual.erase(com)
			descartar_cartas(residuos)
			var msg = "[COMODIN] Comodín Q (Reciclaje) (+%d Pts)." % suma
			estado.registrar_log(msg)
			if vista_ui != null:
				vista_ui.mostrar_feedback(msg, Color(0.4, 1.0, 0.6))
			actualizar_pantalla()
			return

		# Comodín K (Aislamiento) + E-Waste o Tóxicos: E-Waste * 1.5 * 2, tóxicos neutralizados
		elif com.comodin_subtipo == "K":
			var todos_validos = true
			for r in residuos:
				if not r.es_ewaste() and not r.es_toxico():
					todos_validos = false
					break
			if todos_validos:
				var suma = 0.0
				for r in residuos:
					if r.es_ewaste():
						suma += (float(r.valor) * 1.5) * 2.0
				var pts = int(suma)
				estado.actualizar_puntos(pts)
				estado.comodines_usados.append(com)
				mano_actual.erase(com)
				descartar_cartas(residuos)
				var msg = "[COMODIN] Comodín K (Aislamiento) (+%d Pts neutralizados)." % pts
				estado.registrar_log(msg)
				if vista_ui != null:
					vista_ui.mostrar_feedback(msg, Color(0.4, 1.0, 0.6))
				actualizar_pantalla()
				return

	# 5. E-WASTE INDIVIDUAL: 1 E-Waste solo -> Valor * 1.5 pts, +3 Contaminación
	if cartas_sel.size() == 1 and cartas_sel[0].es_ewaste():
		var pts = int(float(cartas_sel[0].valor) * 1.5)
		estado.actualizar_puntos(pts)
		estado.incrementar_contaminacion(3)
		descartar_cartas(cartas_sel)
		var msg = "[ALERTA] 1 E-Waste procesado individualmente (+%d Pts, +3 Contaminación)." % pts
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(1.0, 0.6, 0.4))
		actualizar_pantalla()
		verificar_fin_juego()
		return

	# Combinación no válida
	var msg_error = "[ERROR] Combinación no válida. Revisa los combos válidos."
	estado.registrar_log(msg_error)
	if vista_ui != null:
		vista_ui.mostrar_feedback(msg_error, Color(1.0, 0.35, 0.35))

func limpiar_mano() -> void:
	if mano_actual.is_empty():
		if vista_ui != null:
			vista_ui.mostrar_feedback("[AVISO] Tu mano ya está vacía.", Color(1.0, 0.8, 0.4))
		return
		
	var cant = mano_actual.size()
	for c in mano_actual:
		mazo.agregar_a_descarte(c)
	mano_actual.clear()
	
	estado.incrementar_contaminacion(5)
	var msg = "[DESCARTE] Descartaste voluntariamente %d cartas. +5 Contaminación." % cant
	estado.registrar_log(msg)
	if vista_ui != null:
		vista_ui.mostrar_feedback(msg, Color(1.0, 0.4, 0.4))
		
	actualizar_pantalla()
	verificar_fin_juego()

func aplicar_sinergias_negativas() -> void:
	estado.registrar_log("[FIN DE TURNO] Evaluando sinergias negativas de cartas retenidas.")
	
	var organicos: Array[Carta] = []
	var reciclables: Array[Carta] = []
	var ewaste: Array[Carta] = []
	var toxicos: Array[Carta] = []
	var comodines: Array[Carta] = []
	
	for c in mano_actual:
		if c.es_organico():
			organicos.append(c)
		elif c.es_reciclable():
			reciclables.append(c)
		elif c.es_ewaste():
			ewaste.append(c)
		elif c.es_toxico():
			toxicos.append(c)
		elif c.es_comodin():
			comodines.append(c)

	# 1. Orgánico + Reciclable
	if organicos.size() > 0 and reciclables.size() > 0:
		estado.registrar_log("[ALERTA] Orgánico + Reciclable retenidos: Reciclables contaminados (+1 Contaminación).")
		estado.incrementar_contaminacion(1)
		for c in reciclables:
			c.contaminar()
		organicos.clear()
		for c in mano_actual:
			if c.es_organico():
				organicos.append(c)

	# 2. Orgánico + E-Waste
	if organicos.size() > 0 and ewaste.size() > 0:
		var com_msg = ""
		if comodines.size() > 0:
			var com_del = comodines[0]
			mano_actual.erase(com_del)
			mazo.agregar_a_descarte(com_del)
			com_msg = " y pierdes 1 comodín (" + com_del.get_nombre() + ")"
		estado.registrar_log("[ALERTA] Orgánico + E-Waste retenidos: +4 Contaminación" + com_msg + ".")
		estado.incrementar_contaminacion(4)

	# 3. Retención de Orgánicos
	if organicos.size() >= 2:
		estado.registrar_log("[ALERTA] 2 o más Orgánicos retenidos: +5 Contaminación. Robarás 3 cartas el próximo turno.")
		estado.incrementar_contaminacion(5)
		estado.cartas_a_robar = 3
	elif organicos.size() == 1:
		estado.registrar_log("[ALERTA] 1 Orgánico retenido: +2 Contaminación.")
		estado.incrementar_contaminacion(2)

	# 4. Retención de E-Waste (1 e-waste retenido sin orgánicos)
	if ewaste.size() == 1 and organicos.size() == 0:
		estado.registrar_log("[ALERTA] 1 E-Waste retenido sin orgánicos: -3 Puntos de Reducción.")
		estado.actualizar_puntos(-3)

	# 5. Retención de Agente Tóxico
	if toxicos.size() > 0:
		var pts_tox = toxicos.size()
		estado.incrementar_contaminacion(pts_tox)
		estado.registrar_log("[ALERTA] %d Agente(s) Tóxico(s) en mano: +%d Contaminación." % [pts_tox, pts_tox])

func terminar_turno() -> void:
	print("Finalizando turno...")
	aplicar_sinergias_negativas()
	verificar_mano_llena()
	
	if verificar_fin_juego():
		actualizar_pantalla()
		return
		
	# Avanzar turno y robar cartas
	estado.turno += 1
	var cant_a_robar = estado.cartas_a_robar
	robar_cartas(cant_a_robar)
	
	if vista_ui != null:
		vista_ui.mostrar_feedback("[TURNO %d] Turno completado. Robaste %d cartas." % [estado.turno, cant_a_robar], Color(0.9, 0.9, 0.5))
		
	verificar_fin_juego()
	actualizar_pantalla()

func verificar_fin_juego() -> bool:
	if estado.es_derrota():
		var msg = "[DERROTA] Nivel de contaminación máximo alcanzado (%d / %d)." % [estado.get_contaminacion_actual(), estado.limite_contaminacion]
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(1.0, 0.25, 0.25))
			vista_ui.mostrar_fin_juego(msg, false)
		return true
	elif mazo.esta_vacio() and mano_actual.is_empty():
		var msg = "[VICTORIA] Vaciaste el mazo y procesaste todos los residuos. Puntos Finales: %d" % estado.get_puntos_reduccion()
		estado.registrar_log(msg)
		if vista_ui != null:
			vista_ui.mostrar_feedback(msg, Color(0.3, 1.0, 0.4))
			vista_ui.mostrar_fin_juego(msg, true)
		return true
	return false

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
	print("Iniciando guardado de partida...")
	var exito = PersistenciaManager.guardar_partida(estado, mano_actual, estado.comodines_usados, estado.logs)
	if vista_ui != null:
		if exito:
			vista_ui.mostrar_feedback("[GUARDADO] Partida guardada con éxito en disco.", Color(0.5, 1.0, 0.5))
		else:
			vista_ui.mostrar_feedback("[ERROR] Error al guardar partida.", Color(1.0, 0.4, 0.4))
