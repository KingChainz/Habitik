# Habitik 🌿

Habitik es una aplicación móvil gamificada diseñada en **Flutter** que promueve hábitos ecológicos y sostenibles dentro del hogar. Conecta a los miembros de la familia bajo un mismo grupo para competir de manera colaborativa, registrar evidencias de sus acciones ecológicas, realizar un seguimiento del consumo de servicios públicos y aprender sobre el cuidado del medio ambiente a través de juegos interactivos.

La aplicación utiliza un backend en tiempo real para gestionar usuarios, racha diaria, validaciones y sincronización familiar.

## 🚀 Características Principales

- **Dashboard Familiar 🏠:** Visualiza el progreso del grupo familiar, nivel de conciencia ecológica de cada miembro y racha colectiva.
- **Eco-Retos & Validaciones 🚿:** Misiones diarias y desafíos ecológicos. Los miembros suben evidencias (fotos) y el Jefe de Familia aprueba o rechaza los retos para liberar recompensas.
- **Trivia Infinita 🧠:** Juego interactivo de preguntas y respuestas sobre ecología, reciclaje y sostenibilidad para ganar XP y monedas.
- **Eco-Puzzle 🎯:** Minijuego de clasificación de residuos donde los usuarios aprenden a separar correctamente orgánicos, plásticos, papel, vidrio y residuos peligrosos.
- **Eco-Wordle 🔤:** Minijuego diario de adivinar palabras relacionadas al ecosistema y la preservación ambiental con compra de pistas.
- **Seguimiento de Consumo (Luz y Agua) 📊:** Registro digital de boletas de servicios con estadísticas del gasto familiar y establecimiento de metas de ahorro.
- **Tienda de Recompensas 🎁:** Los miembros canjean monedas acumuladas por premios reales definidos dentro del núcleo familiar (ej. "Tarde de películas", "Exención de lavar platos").
- **Sistema de Logros Dinámicos 🏆:** Desbloqueo automático de insignias y recompensas al cumplir hitos clave (primer registro, racha de constancia, nivel 5, etc.).

## 🏗️ Arquitectura y Estructura del Código

El proyecto sigue una estructura limpia y modular estructurada bajo el directorio `lib/`:

```
lib/
├── config/             # Configuración global, temas visuales y estilos.
├── constants/          # Constantes estáticas del negocio (preguntas, palabras).
├── models/             # Modelos de datos serializados (UserProfile, TaskItem, etc.).
├── providers/          # Gestión del estado de la app mediante Provider (Auth, Bill, Task, etc.).
├── screens/            # Pantallas y vistas principales de la aplicación.
│   └── games/          # Desafíos y minijuegos desacoplados (ducha, trivia, puzzle, wordle, etc.).
├── services/           # Servicios de API y comunicación con Supabase y bases de datos.
└── widgets/            # Componentes y widgets interactivos reutilizables.
```

## 🛠️ Configuración del Proyecto

### Requisitos Previos

- Flutter SDK (versión recomendada `>= 3.0.0`)
- Servidor backend operativo (Express + Base de datos)

### Instalar dependencias

```bash
flutter pub get
```

### Configuración de Variables de Envío

Copia el archivo de plantilla `.env.example` como `.env` en la raíz del proyecto y completa con tus credenciales de servidor y servicios de Google:

```bash
cp .env.example .env
```

### Ejecutar la Aplicación

Para correr el proyecto en modo de desarrollo inyectando los secretos de forma segura desde el archivo `.env`:

```bash
flutter run --dart-define-from-file=.env
```

Para generar la build de producción para Android:

```bash
flutter build apk --dart-define-from-file=.env
```
