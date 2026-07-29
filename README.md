# SaaS de Pedido de Comida

Sistema completo de gestión de pedidos para negocios de comida, compuesto por:
- **App iOS (Swift)** — Para tomar pedidos desde dispositivos Apple
- **Panel Web** — Administración, cocina, cobro e inventario
- **Visor de Pedidos** — Pantalla de visualización en tiempo real

##  Estructura del Proyecto

```
COMIDA/
├── COMIDA/              # App iOS (Swift + SwiftUI)
│   └── COMIDA/
│       ├── Models.swift
│       ├── ViewModels/
│       └── Views/
├── web/                 # Panel Web (HTML + JS + Firebase)
│   ├── index.html       # Menú / toma de pedidos
│   ├── admin.html       # Administración
│   ├── cobro.html       # Punto de cobro
│   ├── inventory.html   # Inventario
│   ├── pos.html         # POS
│   ├── viewer.html      # Visor de cocina
│   └── js/
│       └── firebase-config.example.js
├── VisorPedidos/        # Visor de pedidos en tiempo real
├── firebase.json        # Configuración Firebase Hosting
├── firestore.rules      # Reglas de seguridad Firestore
└── .firebaserc          # Proyecto Firebase activo
```

##  Configuración Inicial

### 1. Clonar el repositorio
```bash
git clone https://github.com/josueordonz-sys/SaaS-de-pedido-de-comida-.git
cd SaaS-de-pedido-de-comida-
```

### 2. Configurar Firebase (Web)
```bash
cp web/js/firebase-config.example.js web/js/firebase-config.js
```
Edita `firebase-config.js` con tus credenciales de Firebase Console.

### 3. Configurar Firebase (iOS / Swift)
1. Descarga `GoogleService-Info.plist` desde [Firebase Console](https://console.firebase.google.com)
2. Colócalo en `COMIDA/COMIDA/GoogleService-Info.plist`

>  **Nunca** subas `firebase-config.js` ni `GoogleService-Info.plist` al repositorio.

##  Seguridad

Los siguientes archivos están **excluidos del repositorio** por contener credenciales:
- `web/js/firebase-config.js` — API Key del proyecto web
- `COMIDA/COMIDA/GoogleService-Info.plist` — Credenciales iOS
- `.env` y variantes

Consulta `.gitignore` para la lista completa.

##  Tecnologías

| Componente | Tecnología |
|-----------|-----------|
| App iOS   | Swift, SwiftUI, Firebase iOS SDK |
| Web Panel | HTML5, CSS3, JavaScript, Firebase Web SDK v10 |
| Backend   | Firebase Firestore, Firebase Hosting |

##  Licencia

Proyecto privado — Todos los derechos reservados.
