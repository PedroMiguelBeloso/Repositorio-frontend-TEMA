# Proyecto Tema Frontend

Base de la aplicación Flutter para el frontend de Proyecto Tema. Las rutas de
las funcionalidades todavía son temporales; no se requiere un backend para
iniciar la aplicación ni ejecutar los tests.

## Requisitos

- Flutter stable con Dart `^3.11.5` (verificado con Flutter 3.41.8 y Dart 3.11.5).
- Chrome para ejecutar la versión web. Android/iOS y Windows requieren además
	sus toolchains nativos respectivos.

Verificá la instalación con `flutter --version` y `flutter doctor`.

## Instalar, analizar y ejecutar

Desde la raíz del repositorio:

```sh
flutter pub get
flutter analyze
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1
```

`API_BASE_URL` se lee en `lib/core/config/environment.dart`. Si no se informa,
se usa `http://localhost:8080/api/v1`. Para apuntar a otro ambiente, cambiá el
valor de `--dart-define` al ejecutar o compilar; no hace falta editar páginas ni
repositorios. No incluyas credenciales en ese valor.

Al probar contra el backend desde Flutter Web, el backend debe permitir el
origen de la aplicación mediante CORS.

## Estructura

- `lib/main.dart`: arranque dentro de `ProviderScope`.
- `lib/app/app.dart`: `MaterialApp.router` con el tema y router.
- `lib/app/router/`: paths y nombres centralizados, redirects de sesión y
	navegación responsive.
- `lib/app/theme/app_theme.dart`: paleta, tipografía y estilos Material 3.
- `lib/core/auth/`: sesión nullable, sin usuario por defecto; la sesión real
	corresponde a la tarea 4.2.1.
- `lib/core/network/`: instancia compartida de Dio, encabezado Bearer y mapeo
	de excepciones.
- `lib/core/errors/` y `lib/core/widgets/`: fallos presentables y estados async
	comunes.
- `lib/features/`: espacio independiente para páginas, ViewModels, modelos y
	repositorios de cada funcionalidad.

El flujo previsto para una funcionalidad es:

```text
Page -> ViewModel -> Repository -> ApiClient (Dio)
```

Las páginas y ViewModels no deben crear clientes HTTP ni definir URLs del
backend. Los repositorios consumen `apiClientProvider`. En modo debug el cliente
registra solo método, ruta, estado y duración; no registra headers, cuerpos ni
credenciales.

## Próximas funcionalidades

Las rutas actuales muestran título y «Funcionalidad en desarrollo». Al iniciar
una funcionalidad, agregá su implementación dentro de la carpeta
correspondiente en `lib/features/` y reemplazá el `PlaceholderPage` asociado en
`lib/app/router/app_router.dart`. Conservá la lógica de navegación y autorización
en el router/scaffold, y la lógica de presentación en su Page y ViewModel.

Los tests de red usan un `HttpClientAdapter` falso y no requieren un backend.
Las sesiones de Administrador y Lector usadas en tests se inyectan mediante
overrides de Riverpod.

## Tarea 4.2.1

Queda pendiente implementar el formulario y flujo real de login, la obtención y
emisión del JWT, y la persistencia segura de la sesión. Esta base no contiene
credenciales ni inicia como Administrador.
