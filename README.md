# Flight Compensation iOS App

Una app premium de iOS para compensación por retrasos de vuelos, inspirada en el diseño de Flighty.

## 🚀 Configuración Rápida

### Opción 1: Usar el Script (Recomendado)

```bash
./setup.sh
```

Sigue las instrucciones que aparecen en pantalla.

### Opción 2: Configuración Manual

1. **Abre Xcode** (versión 15.0 o superior)

2. **Crea un nuevo proyecto:**
   - File → New → Project
   - Selecciona **iOS** → **App**
   - Configuración:
     - Product Name: `FlightCompensation`
     - Interface: **SwiftUI**
     - Language: **Swift**
     - Minimum iOS: **17.0**
   - Guarda el proyecto en esta carpeta

3. **Agrega los archivos:**
   - En Xcode, elimina el `ContentView.swift` por defecto si existe
   - Arrastra la carpeta completa `FlightCompensation` al proyecto
   - ⚠️ **IMPORTANTE:** Desmarca "Copy items if needed"
   - Selecciona "Create groups"

4. **Configura el proyecto:**
   - Ve a las Settings del proyecto
   - Deployment Target: iOS 17.0
   - Verifica que SwiftUI esté habilitado

5. **Ejecuta la app:**
   - Selecciona un simulador (iPhone 15 Pro recomendado)
   - Presiona ⌘R o haz clic en Run

## 📱 Características

- ✅ Seguimiento de vuelos en tiempo real
- ✅ Cálculo automático de elegibilidad EU261/UK261
- ✅ Múltiples formas de agregar vuelos:
  - Importar desde Apple Wallet
  - Escanear ticket
  - Entrada manual
- ✅ Interfaz limpia inspirada en Flighty
- ✅ Animaciones suaves y nativas
- ✅ Arquitectura MVVM

## 🏗️ Estructura del Proyecto

```
FlightCompensation/
├── App/              # Punto de entrada y dependencias
├── Models/           # Modelos de datos
├── Services/         # Servicios y lógica de negocio
├── ViewModels/       # ViewModels (MVVM)
├── Views/            # Vistas SwiftUI
└── Utilities/        # Utilidades y extensiones
```

## 🔧 Requisitos

- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

## 📝 Notas

- Los servicios están usando datos mock por defecto
- El motor de elegibilidad EU261 está completamente implementado
- La integración con WalletKit está preparada pero necesita implementación real

## 🐛 Troubleshooting

**Error: "Cannot find type 'Flight' in scope"**
- Asegúrate de que todos los archivos están agregados al target del proyecto

**Error: "Value of type 'X' has no member 'Y'"**
- Verifica que el Deployment Target sea iOS 17.0

**La app no compila:**
- Limpia el build: Product → Clean Build Folder (⌘⇧K)
- Reconstruye: Product → Build (⌘B)


