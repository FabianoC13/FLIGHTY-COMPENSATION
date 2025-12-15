# 🧪 Testing de Delays - Guía

## Opción 1: Usar Mock Service (Más fácil para testing)

Para probar delays fácilmente, puedes cambiar temporalmente a usar el mock service:

1. Abre `FlightCompensation/Utilities/Config.swift`
2. Cambia `useRealFlightTracking` a `false`:

```swift
static let useRealFlightTracking = false
```

3. El mock service simulará delays automáticamente:
   - Vuelos con fecha pasada → `departed` o `arrived`
   - Vuelos próximos (menos de 1 hora) → `delayed`
   - Vuelos futuros → 20% probabilidad de `delayed`

## Opción 2: Forzar Delay en Códigos Específicos

He modificado el código para que ciertos códigos de vuelo siempre devuelvan delay cuando uses la API real. Prueba con estos códigos:

### Códigos de vuelo que simulan delay:
- **DELAY001** - Siempre devuelve delay de 3-5 horas
- **DELAY002** - Siempre devuelve delay de 4 horas
- **CANCEL001** - Siempre devuelve cancelación

### Ejemplo:
1. Agrega un vuelo con código: **DELAY001**
2. La app detectará el código especial y simulará un delay
3. Verás la elegibilidad de compensación EU261

## Opción 3: Buscar Vuelos Reales con Delay

Para probar con datos reales de la API:

### Vuelos que suelen tener delays:
- **FR** (Ryanair) - Vuelos europeos, especialmente en verano
- **BA** (British Airways) - Vuelos transatlánticos
- **LH** (Lufthansa) - Vuelos de conexión

### Cómo encontrar vuelos con delay:
1. Ve a [FlightRadar24.com](https://www.flightradar24.com)
2. Busca vuelos activos ahora mismo
3. Filtra por "Delayed" o "Delayed Departure"
4. Usa el código de vuelo en la app

### Ejemplos de códigos comunes:
- **FR1234** - Ryanair (suele tener delays)
- **BA178** - British Airways
- **LH441** - Lufthansa
- **IB6074** - Iberia

## Opción 4: Crear Vuelo de Prueba Manual

Puedes crear un vuelo manualmente con delay:

1. Agrega un vuelo con cualquier código
2. Espera a que se carguen los datos
3. Si no tiene delay, puedes modificar temporalmente el código para forzar un delay

## 🎯 Recomendación para Testing Rápido

**Usa la Opción 1 (Mock Service)** para testing rápido:
1. Cambia `useRealFlightTracking = false` en `Config.swift`
2. Agrega un vuelo con fecha de **hoy o mañana**
3. El mock service simulará un delay automáticamente
4. Verás la elegibilidad de compensación

## 📊 Qué verás cuando hay delay:

1. **Status**: "Delayed" (botón rojo/naranja)
2. **Delay Info Card**: Muestra duración del delay
3. **Compensation Eligibility**: 
   - Monto de compensación (€250, €400, o €600)
   - Razón de elegibilidad
   - Botón "View Details"

## 🔄 Volver a API Real

Cuando termines de probar:
1. Cambia `useRealFlightTracking = true` en `Config.swift`
2. La app usará la API real de FlightRadar24

