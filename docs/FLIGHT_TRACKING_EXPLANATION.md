# ✈️ Flight Tracking - Explicación

## 📡 Cómo funciona el tracking de vuelos

### Cuando agregas un vuelo

1. **Agregas el código de vuelo** (ej: "IB6074", "BCS3")
2. **La app busca en FlightRadar24 API**
3. **Resultados posibles:**

### ✅ Vuelo encontrado y activo
- El vuelo está en el aire o a punto de despegar
- API devuelve datos del vuelo
- Status: `departed`, `delayed`, `onTime`, etc.

### ⏰ Vuelo programado (futuro)
- El vuelo existe pero aún no ha despegado
- API responde con `data: null` (no hay datos activos)
- Status: `scheduled` (estado por defecto)
- **Esto es normal** - el vuelo será trackeado cuando se active

### ❌ Vuelo completado o no encontrado
- El vuelo ya aterrizó o no existe en FlightRadar24
- API responde con `data: null`
- Status: `scheduled` (usaremos mock data para testing)

## 🔄 Tracking continuo

Cuando un vuelo tiene status `scheduled`:
- La app puede hacer tracking periódico
- Cuando el vuelo se active (despegue), la API devolverá datos reales
- El status se actualizará automáticamente

## 💡 Nota importante

**No encontrar un vuelo en la API NO es un error crítico:**
- Los vuelos futuros no aparecen hasta que están cerca del despegue
- Los vuelos históricos pueden no estar disponibles
- El sandbox puede tener datos limitados

**La app funciona igual:**
- Puedes agregar vuelos aunque no estén activos
- El sistema de elegibilidad EU261 funciona con delays detectados
- Cuando el vuelo se active, obtendrás datos reales

## 🧪 Para testing

Si quieres probar con vuelos activos:
1. Busca vuelos que estén volando ahora mismo
2. Usa códigos de vuelo reales de aerolíneas conocidas
3. Ejemplo: "BA178" si hay un vuelo BA178 activo ahora

Si quieres agregar vuelos futuros:
1. Agrega el código normalmente
2. El status será "scheduled"
3. La app trackeará cuando el vuelo se active

