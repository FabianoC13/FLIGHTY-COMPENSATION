it# 📡 FlightRadar24 API - Requisitos de Input

## ✅ Input que acepta la API

Según la documentación de FlightRadar24, la API acepta varios parámetros:

### Opción 1: Búsqueda por número de vuelo (recomendado)
- **Parámetro:** `flights`
- **Formato:** Números de vuelo separados por comas (máximo 15)
- **Ejemplo:** `flights=BA178,FR1234`

### Opción 2: Búsqueda genérica
- **Parámetro:** `query` + `fetchBy`
- **Formato:** `query=BA178` + `fetchBy=flight`
- Usado para búsquedas más flexibles

## 🔧 Nuestra implementación actual

Actualmente estamos usando:
```
Endpoint: https://api.flightradar24.com/common/v1/flight/list.json
Parámetros:
  - query: "BA178" (código de vuelo completo)
  - fetchBy: "flight"
  - page: "1"
  - limit: "1"
```

## 📝 Formato del código de vuelo

La API espera el código de vuelo completo en formato:
- **Ejemplos:** `BA178`, `FR1234`, `LH441`, `A320`
- Formato: `[CÓDIGO_AEROLÍNEA][NÚMERO]`
  - Código aerolínea: 2-3 letras (BA, FR, AAL)
  - Número: dígitos (178, 1234, 441)

## ✅ Cómo funciona en nuestra app

1. **Usuario ingresa:** Solo el código de vuelo (ej: "BA178")
2. **Nuestra app parsea:** 
   - Airline: "BA"
   - Flight Number: "178"
3. **Llamada a API:** Enviamos "BA178" completo en el parámetro `query`

## 🧪 Para probar

1. Agrega un vuelo con código: `BA178` (o cualquier vuelo real)
2. La app enviará: `query=BA178&fetchBy=flight`
3. La API debería responder con el estado del vuelo

## 🔍 Verificar si funciona

Si la API responde correctamente, verás:
- Status real del vuelo (on time, delayed, etc.)
- Información adicional si está disponible

Si hay errores, revisa:
- Console de Xcode para ver la respuesta completa
- Status code HTTP (401 = key inválida, 404 = vuelo no encontrado)

## 💡 Mejora sugerida

Podríamos cambiar a usar el parámetro `flights` en lugar de `query` si es más directo:

```swift
components?.queryItems = [
    URLQueryItem(name: "flights", value: formattedFlightNumber),
    URLQueryItem(name: "page", value: "1"),
    URLQueryItem(name: "limit", value: "1")
]
```

Esto dependerá de qué endpoint específico estemos usando.

