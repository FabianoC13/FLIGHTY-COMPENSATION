# 🚀 Inicio Rápido - Flight Compensation App

## Método 1: Automático (Recomendado si tienes XcodeGen)

Si tienes `xcodegen` instalado:

```bash
# Instala xcodegen si no lo tienes
brew install xcodegen

# Genera el proyecto
xcodegen generate

# Abre el proyecto
open FlightCompensation.xcodeproj
```

## Método 2: Manual (Siempre funciona)

### Paso 1: Crear el proyecto en Xcode

1. Abre **Xcode**
2. **File** → **New** → **Project**
3. Selecciona:
   - **iOS** → **App**
   - Click **Next**
4. Completa:
   - **Product Name:** `FlightCompensation`
   - **Team:** (tu equipo o "None")
   - **Organization Identifier:** `com.flightcompensation` (o el que prefieras)
   - **Interface:** **SwiftUI** ✅
   - **Language:** **Swift** ✅
   - **Storage:** None
   - **Include Tests:** (opcional)
5. Click **Next**
6. **IMPORTANTE:** Guarda en esta carpeta: `$(pwd)` (la carpeta actual)
7. Click **Create**

### Paso 2: Configurar el proyecto

1. En Xcode, selecciona el proyecto (icono azul arriba a la izquierda)
2. Selecciona el target **FlightCompensation**
3. En **General**:
   - **Minimum Deployments:** iOS **17.0** ✅
4. En **Build Settings**:
   - Busca "Swift Language Version"
   - Asegúrate que sea **Swift 5.9** o superior

### Paso 3: Agregar los archivos

1. En Xcode, **elimina** estos archivos si existen:
   - `ContentView.swift` (si existe)
   - `FlightCompensationApp.swift` (si existe)

2. En el Finder, abre la carpeta `FlightCompensation`

3. En Xcode, **arrastra** toda la carpeta `FlightCompensation` al proyecto:
   - Arrastra desde el Finder a Xcode (al lado izquierdo donde están los archivos)
   - ⚠️ **IMPORTANTE:** En el diálogo:
     - ✅ **Create groups** (no "Create folder references")
     - ❌ **NO marques** "Copy items if needed"
     - ✅ Asegúrate que el target **FlightCompensation** esté seleccionado
   - Click **Finish**

### Paso 4: Verificar que todo está bien

1. Busca el archivo `FlightCompensationApp.swift` en Xcode
2. Deberías ver todos los archivos organizados en carpetas:
   - App/
   - Models/
   - Services/
   - ViewModels/
   - Views/
   - Utilities/

### Paso 5: Ejecutar la app

1. Selecciona un simulador:
   - Click en el dispositivo arriba (junto al botón Run)
   - Elige **iPhone 15 Pro** (o cualquier iPhone con iOS 17+)

2. Ejecuta la app:
   - Presiona **⌘R** (Cmd + R)
   - O click en el botón **▶️ Play**

3. ¡La app debería abrirse en el simulador! 🎉

## ✅ Verificación

Si todo está bien, deberías ver:
- Una pantalla con "Your Flights"
- Un botón "+" en la esquina superior derecha
- Un mensaje "No flights yet" si no hay vuelos

## 🐛 Problemas comunes

### "Cannot find 'Flight' in scope"
- Verifica que todos los archivos estén en el target correcto
- Selecciona cada archivo y en el panel derecho, verifica que esté marcado el target

### "Value of type has no member"
- Verifica que el Deployment Target sea iOS 17.0
- Limpia el build: **Product** → **Clean Build Folder** (⌘⇧K)

### La app no compila
1. **Limpia:** Product → Clean Build Folder (⌘⇧K)
2. **Reconstruye:** Product → Build (⌘B)
3. Si persiste, cierra Xcode y vuelve a abrir

## 📱 Probar la app

1. Click en el botón **+** para agregar un vuelo
2. Prueba las diferentes opciones:
   - **Import from Wallet** (usará datos mock)
   - **Scan ticket** (usará datos mock)
   - **Enter flight number** (entrada manual)

3. Agrega un vuelo y luego:
   - Click en el vuelo para ver detalles
   - La app simulará delays después de hacer tracking
   - Verás la elegibilidad de compensación si hay delay

## 🎉 ¡Listo!

Tu app está funcionando. Todos los servicios están usando datos mock, así que puedes probar todas las funcionalidades sin necesidad de APIs reales.


