# 🔑 FlightRadar24 Sandbox Token Setup

## ✅ Token Configurado

Tu token de SANDBOX está configurado:
```
019b1ebe-a96a-70ce-b39e-b9e993672ef5|2RhxQvK0fSkZVcQiVlb87tDaPtFJTNH9ZQmIpwbK3f596ccb
```

## 🔧 Cambios Realizados

He actualizado el código para manejar correctamente el token de sandbox:

1. **Detección automática de Sandbox**: El código detecta si es un token de sandbox
2. **Múltiples métodos de autenticación**: Intenta varios formatos:
   - `X-API-Key-Id` + `X-API-Key-Secret` (split)
   - `Authorization: Bearer {token}`
   - `Access-Token: {token}` (común en sandbox)
   - `X-API-Key: {token}`

## 📡 Endpoint Usado

Actualmente usando:
```
https://api.flightradar24.com/common/v1/flight/list.json
```

## 🧪 Cómo Probar

1. Ejecuta la app
2. Agrega un vuelo con código (ej: "BA178")
3. Haz tracking del vuelo
4. Revisa la consola de Xcode para ver:
   - Qué headers se están enviando
   - Qué respuesta devuelve la API
   - Cualquier error específico

## 🔍 Debugging

Si aún hay errores, revisa en la consola:

### Request Headers
Busca en los logs: `🚀 FlightRadar24 API Request:`
- Verifica que se estén enviando los headers correctos

### Response
Busca en los logs: `📡 FlightRadar24 API Response:`
- Status Code: debería ser 200 para éxito
- Body: muestra la respuesta de la API

### Errores Comunes

1. **401 Unauthorized**
   - El token no es válido o está expirado
   - Los headers de autenticación no son correctos
   - Verifica que el token esté completo

2. **404 Not Found**
   - El endpoint no existe o es incorrecto
   - El vuelo no existe en la base de datos

3. **500/503 Server Error**
   - Problema temporal del servidor
   - Endpoint no disponible en sandbox

## 💡 Nota sobre Sandbox

Los tokens de sandbox pueden:
- Tener limitaciones de rate limiting más estrictas
- Usar endpoints diferentes
- Tener datos de prueba limitados
- Requerer un formato de autenticación específico

Si la API sigue sin funcionar, puede que necesitemos:
1. Verificar la documentación específica de sandbox
2. Usar un endpoint diferente para sandbox
3. Ajustar el formato de autenticación según los requisitos exactos

## 🚀 Próximos Pasos

1. Ejecuta la app y prueba con un vuelo real
2. Revisa los logs en la consola
3. Comparte los logs si hay errores para ajustar el código

