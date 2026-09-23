class_name PersistenciaManager
extends RefCounted

const RUTA_GUARDADO: String = "user://partida_guardada.json"

# Variable estática para transferir la partida cargada desde MainMenu a GameManager
static var partida_cargada_pendiente: Dictionary = {}

static func hay_partida_guardada() -> bool:
	return FileAccess.file_exists(RUTA_GUARDADO)

static func guardar_partida(estado: EstadoJuego, mano: Array[Carta] = [], comodines: Array[Carta] = [], logs: Array[String] = []) -> bool:
	if estado == null:
		push_error("PersistenciaManager: No se puede guardar un EstadoJuego nulo.")
		return false

	var serializar_carta = func(c: Carta) -> Dictionary:
		return {
			"id": c.id,
			"nombre": c.nombre,
			"tipo": c.tipo,
			"valor": c.valor,
			"base_texture": c.base_texture_path,
			"icon_texture": c.icon_texture_path
		}

	var mano_serializada: Array[Dictionary] = []
	for c in mano:
		mano_serializada.append(serializar_carta.call(c))

	var comodines_serializados: Array[Dictionary] = []
	for c in comodines:
		comodines_serializados.append(serializar_carta.call(c))

	var datos_partida: Dictionary = {
		"puntos_reduccion": estado.get_puntos_reduccion(),
		"contaminacion_actual": estado.get_contaminacion_actual(),
		"limite_contaminacion": estado.limite_contaminacion,
		"turno": estado.turno,
		"cartas_a_robar": estado.cartas_a_robar,
		"limite_mano": estado.limite_mano,
		"estado_partida": estado.estado_partida,
		"mano": mano_serializada,
		"comodines_usados": comodines_serializados,
		"logs": logs.slice(max(0, logs.size() - 10)),
		"fecha_guardado": Time.get_datetime_string_from_system()
	}

	var texto_json: String = JSON.stringify(datos_partida, "\t")
	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
	if archivo == null:
		push_error("PersistenciaManager: Error al abrir el archivo para escribir: " + str(FileAccess.get_open_error()))
		return false

	archivo.store_string(texto_json)
	archivo.close()
	print("Partida guardada con éxito en: ", RUTA_GUARDADO)
	return true

static func cargar_partida_datos() -> Dictionary:
	if not hay_partida_guardada():
		print("PersistenciaManager: No se encontró ningún archivo de guardado previo.")
		return {}

	var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
	if archivo == null:
		push_error("PersistenciaManager: Error al leer el archivo de guardado.")
		return {}

	var texto_json: String = archivo.get_as_text()
	archivo.close()

	var json = JSON.new()
	var error_parseo = json.parse(texto_json)
	if error_parseo != OK:
		push_error("PersistenciaManager: Error al parsear JSON: " + json.get_error_message())
		return {}

	return json.data as Dictionary

static func obtener_resumen_guardado() -> String:
	var datos = cargar_partida_datos()
	if datos.is_empty():
		return "No hay partida guardada."
	var turno = datos.get("turno", 1)
	var contam = datos.get("contaminacion_actual", 0)
	var limite = datos.get("limite_contaminacion", 21)
	var pts = datos.get("puntos_reduccion", 0)
	var fecha = datos.get("fecha_guardado", "")
	return "Turno %d | Contaminación: %d/%d | Puntos: %d\nFecha: %s" % [turno, contam, limite, pts, fecha]