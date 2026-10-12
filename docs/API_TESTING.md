# 🧪 Testing FlightRadar24 API

## ✅ Configuración completada

He integrado tu API key de FlightRadar24 en la app. Todo está listo para probar.

## 🔑 API Key configurada

Tu API key está configurada en:
- Archivo: `FlightCompensation/Utilities/Config.swift`
- Variable: `flightRadar24APIKey`

## 🚀 Cómo probar

### 1. Verifica la configuración

Abre `FlightCompensation/Utilities/Config.swift` y verifica que:
- ✅ `flightRadar24APIKey` tenga tu key correcta
- ✅ `useRealFlightTracking = true` (para usar la API real)

### 2. Ejecuta la app

1. Abre el proyecto en Xcode
2. Ejecuta la app (⌘R)
3. Agrega un vuelo:
   - Click en el botón **+**
   - Usa "Enter flight number" para agregar un vuelo de prueba
   - Ejemplo: Airline: `BA`, Flight Number: `178`, Date: mañana

### 3. Verifica el tracking

1. Después de agregar el vuelo, la app intentará obtener el status de FlightRadar24
2. Si funciona correctamente, verás el status real del vuelo
3. Si hay errores, verás mensajes informativos

## 🐛 Debugging

### Ver logs en Xcode

1. Abre la consola en Xcode (View → Debug Area → Activate Console o ⌘⇧Y)
2. Busca mensajes que comiencen con "FlightRadar24 API Error:"
3. Estos te dirán qué salió mal

### Posibles errores

1. **401 Unauthorized**
   - Tu API key no es válida o expiró
   - Verifica que la key esté correctamente copiada

2. **404 Flight Not Found**
   - El vuelo no existe en FlightRadar24
   - Prueba con un vuelo conocido (ej: BA178, LH441)

3. **Server Error (500, 503, etc.)**
   - Problema temporal del servidor de FlightRadar24
   - Intenta de nuevo más tarde

4. **Decoding Error**
   - El formato de respuesta de la API cambió
   - Necesitamos ajustar el parser (ver sección "Ajustar parser")

## 🔧 Cambiar entre Mock y Real API

En `Config.swift`:

```swift
// Usar API real
static let useRealFlightTracking = true

// Usar datos mock (para desarrollo sin API)
static let useRealFlightTracking = false
```

## 📝 Ajustar el parser

Si la API responde pero no se parsea correctamente:

1. **Ver la respuesta real:**
   - En `FlightRadar24Service.swift`, línea ~80, agrega:
   ```swift
   print("API Response: \(String(data: data, encoding: .utf8) ?? "Unable to decode")")
   ```

2. **Ajustar modelos:**
   - Revisa `FlightRadar24Response` y modelos relacionados
   - Ajusta según la estructura real de la respuesta

3. **Mejorar extractStatus:**
   - El método `extractStatus` intenta ser flexible
   - Ajusta las rutas JSON según la respuesta real

## 📚 Endpoint usado

Actualmente usando:
```
https://api.flightradar24.com/common/v1/flight/list.json
```

Query parameters:
- `query`: Número de vuelo (ej: "BA178")
- `fetchBy`: "flight"
- `page`: "1"
- `limit`: "1"

Headers:
- `X-API-Key-Id`: primera parte de tu key (antes del |)
- `X-API-Key-Secret`: segunda parte de tu key (después del |)
- O `X-API-Key`: key completa (si no tiene |)

## ✅ Próximos pasos

1. Prueba con vuelos reales
2. Verifica que los status se muestren correctamente
3. Si hay problemas de parsing, revisa los logs y ajusta el código

## 💡 Nota

Esta implementación intenta ser flexible con el formato de respuesta de la API. Si el formato exacto de FlightRadar24 es diferente, puedes ajustar:
- Los modelos de respuesta (`FlightRadar24Response`, etc.)
- El método `extractStatus`
- Los headers de autenticación

¡Listo para probar! 🚀

