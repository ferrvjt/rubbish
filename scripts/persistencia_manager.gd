class_name PersistenciaManager
extends RefCounted

const RUTA_GUARDADO: String = "user://partida_guardada.json"

# Guardar
static func guardar_partida(estado: EstadoJuego) -> bool:
    if estado == null:
        push_error("PersistenciaManager: No se puede guardar un EstadoJuego nulo.")
        return false

    # Estructura de datos
    var datos_partida: Dictionary = {
            "puntos_reduccion": estado.get_puntos_reduccion(),
            "contaminacion_actual": estado.get_contaminacion_actual(),
            "limite_contaminacion": estado.limite_contaminacion,
            "fecha_guardado": Time.get_datetime_string_from_system()
        }

    # Diccionario a JSON
    var texto_json: String = JSON.stringify(datos_partida, "\t")

        # Abrir/crear archivo local
    var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.WRITE)
    if archivo == null:
        push_error("PersistenciaManager: Error al abrir el archivo para escribir: " + str(FileAccess.get_open_error()))
        return false

    archivo.store_string(texto_json)
    archivo.close()
    print("Partida guargaga con éxito en: ", RUTA_GUARDADO)
    return true

# Cargar y reconstruir
static func cargar_partida() -> EstadoJuego:
    if not FileAccess.file_exists(RUTA_GUARDADO):
        print("PersistenciaManager: No se encontró ningún archivo de guardado previo.")
        return null
    
    var archivo = FileAccess.open(RUTA_GUARDADO, FileAccess.READ)
    if archivo == null:
        push_error("PersistenciaManager: Error al leer el archivo de guardado.")
        return null
    
    var texto_json: String = archivo.get_as_text()
    archivo.close()

    var json = JSON.new()
    var error_parseo = json.parse(texto_json)

    if error_parseo != OK:
        push_error("PersistenciaManager: Error al parsear JSON: " + json.get_error_message())
        return null

    var datos: Dictionary = json.data

    # Reconstruir instancia
    var estado_cargado = EstadoJuego.new(datos.get("limite_contaminacion", 21))
    estado_cargado.actualizar_puntos(datos.get("puntos_reduccion", 0))
    estado_cargado.incrementar_contaminacion(datos.get("contaminacion_actual", 0))

    print("Partida cargada")

    return estado_cargado