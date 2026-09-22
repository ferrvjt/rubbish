class_name Mazo
extends RefCounted

var cartas: Array[Carta] = []
var descarte: Array[Carta] = []

func barajar() -> void:
	cartas.shuffle()

func robar_carta() -> Carta:
	if cartas.is_empty():
		return null
	return cartas.pop_back()

func agregar_a_descarte(carta: Carta) -> void:
	if carta != null:
		descarte.append(carta)

func cantidad_restante() -> int:
	return cartas.size()

func cantidad_descarte() -> int:
	return descarte.size()

func esta_vacio() -> bool:
	return cartas.is_empty()

func cargar_desde_json(ruta_archivo: String) -> void:
	if not FileAccess.file_exists(ruta_archivo):
		push_error("No se encontró el archivo de cartas en: " + ruta_archivo)
		return

	var archivo = FileAccess.open(ruta_archivo, FileAccess.READ)
	var texto_json = archivo.get_as_text()
	archivo.close()

	var json = JSON.new()
	var error_parseo = json.parse(texto_json)

	if error_parseo == OK:
		var lista_cartas_data = json.data
		cartas.clear()
		descarte.clear()
		
		for data in lista_cartas_data:
			var nueva_carta = Carta.new(
				data["id"],
				data["nombre"],
				data["tipo"] as Carta.Tipo,
				data["valor"],
				data.get("base_texture", ""),
				data.get("icon_texture", "")
			)
			cartas.append(nueva_carta)
			
		barajar()
	else:
		push_error("Error al parsear el JSON de cartas: " + json.get_error_message())