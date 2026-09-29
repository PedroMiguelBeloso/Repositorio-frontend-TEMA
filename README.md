# Proyecto Tema Frontend

Base de infraestructura para el frontend de Proyecto Tema, construida con
Flutter, Riverpod, go_router y Dio. Incluye navegación con permisos por rol,
sesión en memoria, cliente HTTP común y tratamiento de errores. Las
funcionalidades reales de autenticación, procesos, servicios y verificaciones
se desarrollarán en tareas posteriores.

## Requisitos

- SDK verificado: Flutter 3.47.5 stable y Dart 3.13.4.
- Para ejecutar en web: Chrome.
- `flutter doctor` debe estar sin errores para la plataforma elegida.
- Trabajá desde la carpeta del proyecto, no desde ubicaciones protegidas del
	sistema como `C:\Windows\System32`.

## Puesta en marcha

Ejecutá estos comandos desde la raíz del repositorio:

| Comando | Qué hace |
|---|---|
| `flutter pub get` | Resuelve e instala las dependencias fijadas en `pubspec.lock`. |
| `flutter analyze` | Ejecuta el análisis estático de Dart/Flutter. |
| `flutter test` | Ejecuta todos los tests automatizados. |
| `flutter test --coverage` | Ejecuta los tests y genera `coverage/lcov.info`. |
| `flutter test test/core/network/api_client_test.dart` | Ejecuta un archivo específico de tests. |
| `flutter test --name="Bearer header"` | Filtra tests por expresión regular en el nombre (`--name=<regexp>` en Flutter 3.47.5). |
| `flutter run -d chrome` | Ejecuta la app en Chrome. |
| `flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1` | Ejecuta en Chrome con una URL de API explícita. |
| `flutter build web` | Compila la app web en `build/web`. |

## Configuración de ambientes

`API_BASE_URL` se obtiene en `lib/core/config/environment.dart` mediante
`String.fromEnvironment`. El valor predeterminado verificado es
`http://localhost:8080/api/v1`. Cambiá el destino al ejecutar o compilar; no
hace falta editar código fuente:

```sh
# Local
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api/v1

# Staging (URL de ejemplo; reemplazar por la URL real del ambiente)
flutter run -d chrome --dart-define=API_BASE_URL=https://api-staging.example.com/api/v1

# Producción (URL de ejemplo; reemplazar por la URL real del ambiente)
flutter run -d chrome --dart-define=API_BASE_URL=https://api.example.com/api/v1
```

Las URLs de staging y producción anteriores son ejemplos; no se verificó que
existan o estén disponibles. No incluyas credenciales ni tokens en
`--dart-define`. Al probar un backend desde Flutter Web, el backend debe
permitir el origen de la app mediante CORS.

## Estructura del proyecto

Árbol actual de `lib/` y responsabilidad de sus archivos:

```text
lib/
	main.dart                              Arranque con ProviderScope.
	app/
		app.dart                             MaterialApp.router, tema y router.
		router/
			app_router.dart                    Rutas, guards, shell y error de navegación.
			route_names.dart                   Nombres y paths centralizados.
		theme/
			app_theme.dart                     ColorScheme, tipografía y estilos Material 3.
	core/
		auth/
			session.dart                       Modelo de sesión y rol.
			session_provider.dart              Estado de sesión; null por defecto.
		config/
			environment.dart                   Configuración de API_BASE_URL.
		errors/
			app_failure.dart                   Jerarquía sellada de fallos de UI.
		network/
			api_client.dart                    Construcción de Dio, timeouts e interceptores.
			api_client_provider.dart           Dio compartido vía Riverpod y adaptador inyectable.
			api_exception_mapper.dart          Mapeo de Dio/ProblemDetail a AppFailure.
		utils/
			.gitkeep                            Reserva para utilidades compartidas.
		widgets/
			app_scaffold.dart                  Navegación adaptable y filtrada por rol.
			async_content.dart                 Estados reutilizables de carga/error/vacío.
			placeholder_page.dart              Página temporal de funcionalidad.
			.gitkeep                            Marcador de carpeta.
	features/
		auth/.gitkeep                         Reserva para autenticación.
		home/.gitkeep                         Reserva para inicio.
		processes/.gitkeep                    Reserva para procesos.
		services/.gitkeep                     Reserva para servicios.
		integrations/.gitkeep                 Reserva para integraciones.
		verifications/.gitkeep                Reserva para verificaciones.
```

El router vive en `lib/app/router/`, el tema en `lib/app/theme/app_theme.dart`,
el cliente común en `lib/core/network/` y el manejo de errores en
`lib/core/errors/` y `lib/core/network/api_exception_mapper.dart`.

## Qué se hizo

- **Proyecto y dependencias:** `pubspec.yaml` declara Flutter, `flutter_riverpod`
	`^3.3.2`, `go_router` `^17.5.0`, Dio `^5.11.1` e intl `^0.20.3`. El lockfile
	existe, está versionado y se actualiza con `flutter pub get`. La única
	dependencia directa de desarrollo es `flutter_test`, necesaria para los
	tests; no se agregaron paquetes de mocking.
- **Entrada y tema:** `main.dart` inicia con `ProviderScope`. `app.dart` enlaza
	`MaterialApp.router`, el router y el tema centralizado.
- **Navegación:** están configuradas las 11 rutas de la tabla inferior. Las
	páginas funcionales son placeholders con título y «Funcionalidad en
	desarrollo». La ruta no encontrada muestra un error y un botón para volver al
	inicio. `AppScaffold` usa `NavigationBar` en pantallas angostas y
	`NavigationRail` en anchas. Sin sesión se redirige a `/login`; Lector no puede
	acceder a Integraciones ni crear verificaciones. Las rutas de Administrador
	están centralizadas en `RouteNames.adminOnlyPaths`. El router escucha cambios
	del provider de sesión.
- **Sesión:** `Session` representa rol Lector o Administrador y token opcional;
	`sessionProvider` inicia con `null` (sin sesión). Las sesiones simuladas se
	inyectan en los tests mediante overrides.
- **Ambiente y HTTP:** `apiClientProvider` suministra el cliente Dio compartido,
	con timeout de conexión de 10 segundos y recepción de 30 segundos. El
	interceptor añade Bearer solo si hay token. En debug registra método, ruta,
	estado y duración, sin headers ni cuerpos.
- **Errores:** `AppFailure` es una jerarquía sellada. `ApiExceptionMapper`
	diferencia red, 401, 403, 400/422, 409, 5xx y respuestas inesperadas; para
	Problem Detail prioriza `detail`, luego `title` y finalmente un mensaje
	seguro. `AsyncContent` ofrece carga, error/reintento y vacío. Los estados de
	negocio de M2 no están implementados ni tratados como errores HTTP.
- **Pruebas:** se verifican rutas, permisos, sesión, layout, Bearer presente y
	ausente, y mapeo de errores sin backend real.

## Rutas

Todas las rutas salvo `/login` están bajo el shell autenticado. Sin sesión, una
ruta protegida redirige a `/login`; un Lector que solicita una ruta exclusiva
de Administrador vuelve a `/`.

| Ruta | Nombre | Sin sesión | Lector | Administrador | Estado |
|---|---|---|---|---|---|
| `/login` | `login` | Permitida | Redirige a `/` | Redirige a `/` | Temporal |
| `/` | `home` | Redirige a `/login` | Permitida | Permitida | Temporal |
| `/processes` | `processes` | Redirige a `/login` | Permitida | Permitida | Temporal |
| `/processes/:id` | `process-details` | Redirige a `/login` | Permitida | Permitida | Temporal |
| `/processes/:id/history` | `process-history` | Redirige a `/login` | Permitida | Permitida | Temporal |
| `/services` | `services` | Redirige a `/login` | Permitida | Permitida | Temporal |
| `/verifications` | `verifications` | Redirige a `/login` | Permitida | Permitida | Temporal |
| `/verifications/new` | `new-verification` | Redirige a `/login` | Redirige a `/` | Permitida | Temporal |
| `/verifications/:runId` | `verification-details` | Redirige a `/login` | Permitida | Permitida | Temporal |
| `/verifications/:runId/results` | `verification-results` | Redirige a `/login` | Permitida | Permitida | Temporal |
| `/settings/integrations` | `integrations` | Redirige a `/login` | Redirige a `/` | Permitida | Temporal |

Los nombres y paths están en `lib/app/router/route_names.dart`. Las rutas
exclusivas de Administrador están en `RouteNames.adminOnlyPaths`; para agregar
otra, incorporá su path a ese set. El redirect consulta el helper
`RouteNames.isAdminOnly`. `/verifications/new` está declarada antes de
`/verifications/:runId`, por lo que el path estático no se captura como un
detalle.

## Testing

- `test/widget_test.dart`: resuelve rutas conocidas, muestra error para ruta
	desconocida, verifica redirects, roles, refresh de sesión y layouts angosto y
	ancho.
- `test/core/network/api_client_test.dart`: comprueba Bearer con token y
	ausencia del header sin token mediante un `HttpClientAdapter` falso.
- `test/core/network/api_exception_mapper_test.dart`: verifica 401, 403,
	400/422, 409, 503, fallo de red y lectura de Problem Detail con campos
	opcionales ausentes; también cuerpos nulos, vacíos/no mapa y rechazo de
	detalles técnicos.
- `test/core/widgets/async_content_test.dart`: verifica carga, error con
	callback de reintento y estado vacío.

Las sesiones de prueba se inyectan con overrides del provider de sesión. El
cliente HTTP permite inyectar `apiHttpClientAdapterProvider`; las pruebas usan
un adaptador falso que devuelve respuestas locales, sin llamar a un backend ni
a la red.

## Verificación

Evidencia final recolectada el 2026-09-29 con Flutter 3.47.5 stable y Dart
3.13.4.

`flutter pub get`:

```text
Got dependencies!
12 packages have newer versions incompatible with dependency constraints.
```

`flutter analyze`:

```text
Analyzing proyecto_tema_frontend...
No issues found! (ran in 1.4s)
```

`flutter test`:

```text
00:02 +0: C:/dev/proyecto_tema_frontend/test/core/network/api_client_test.dart: adds the current session token as a Bearer header
[HTTP] GET /api/v1/private-resource status=200 duration=26ms
00:02 +1: C:/dev/proyecto_tema_frontend/test/core/network/api_client_test.dart: does not add an Authorization header without a session token
[HTTP] GET /api/v1/public-resource status=200 duration=2ms
00:05 +28: All tests passed!
```

`flutter run -d chrome --web-hostname 127.0.0.1 --web-port 8765`:

```text
Launching lib\main.dart on Chrome in debug mode...
Waiting for connection from debug service on Chrome...             25,6s
Flutter run key commands.
Starting application from main method in:
org-dartlang-app:///web_entrypoint.dart.
Application finished.
```

Chrome mostró `http://127.0.0.1:8765/#/login` sin errores de consola. La
sesión interactiva se cerró con `q`; la ruta inicial sin sesión también está
afirmada por los tests de navegación.

## Cómo continuar

El recorrido previsto para una funcionalidad nueva es:

```text
Page -> ViewModel -> Repository -> ApiClient
```

Esquema ilustrativo (las capas de feature todavía no están implementadas):

```dart
import 'package:dio/dio.dart';

final class ExampleRepository {
	ExampleRepository(this._client);

	final Dio _client;

	Future<Response<dynamic>> load() => _client.get('/example');
}
```

Creá Page, ViewModel, modelos y repositorios dentro de la carpeta de
`lib/features/` correspondiente. Después reemplazá el `PlaceholderPage` de la
ruta correspondiente en `lib/app/router/app_router.dart`. Las páginas y
ViewModels no instancian Dio ni escriben URLs del backend; los repositorios
usan el cliente común de `apiClientProvider`. Los estilos compartidos se
centralizan en `lib/app/theme/app_theme.dart`.

## Pendiente y fuera de alcance

Para la tarea **4.2.1** quedan pendientes el formulario y flujo real de login,
obtención/emisión del JWT, persistencia segura y sesión real. También queda por
definir allí la integración de la sesión real con los permisos de navegación.

Fuera del alcance de esta base: gestión de usuarios, formularios de procesos y
servicios, conexiones con Drive o Redmine, ejecución de verificaciones y diseño
final de pantallas.

Observaciones verificables:

- Los tests verifican bodies nulos, vacíos, no mapa y mapas con claves no
	string.

## Decisiones tomadas

- Se usa `ShellRoute` para compartir `AppScaffold` entre rutas autenticadas;
	`/login` queda fuera del shell.
- Las rutas exclusivas de Administrador se declaran en
	`RouteNames.adminOnlyPaths`; el redirect las comprueba con
	`RouteNames.isAdminOnly` y envía al Lector a `/`.
- `AppFailure` es una jerarquía sellada para distinguir categorías de error;
	el mapper descarta detalles técnicos identificables antes de mostrarlos.
- La URL tiene un único valor predeterminado en `Environment`; se puede
	reemplazar con `--dart-define`.
- El adaptador HTTP se inyecta por provider y se reemplaza en tests. No se
	agregó una dependencia de mocking; `flutter_test` es la única dependencia
	directa de desarrollo.
- No se agregaron sesiones simuladas en el arranque normal: el provider comienza
	sin sesión.
