# Proyecto Tema Frontend

Guía de pruebas paso a paso: [docs/README_PRUEBAS.md](docs/README_PRUEBAS.md)

Frontend de Proyecto Tema, construido con Flutter, Riverpod, go_router y Dio.
Incluye autenticación, usuarios, servicios y configuración de evidencias en
versiones de proceso, con navegación por rol, cliente HTTP común y tratamiento
de errores.

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
			app_error_view.dart                Error seguro y acción de reintento.
			integration_status_card.dart       Presentación genérica de una integración.
			placeholder_page.dart              Página temporal de funcionalidad.
			status_chip.dart                   Etiqueta visual con estado textual.
			.gitkeep                            Marcador de carpeta.
	features/
		auth/.gitkeep                         Reserva para autenticación.
		home/.gitkeep                         Reserva para inicio.
		processes/
			model/                              Árbol de proceso y evidencias.
			data/                               Repositorio de procesos y catálogo.
			viewmodel/                          Listado, detalle y editor.
			view/                               Estructura y selector de catálogo.
		services/.gitkeep                     Reserva para servicios.
		integrations/
			model/                              Fuentes y estados de integración.
			data/                               DTO, repositorio y provider.
			viewmodel/                          Carga y prueba de estados.
			view/                               Pantalla y presentación visual.
		verifications/.gitkeep                Reserva para verificaciones.
```

El router vive en `lib/app/router/`, el tema en `lib/app/theme/app_theme.dart`,
el cliente común en `lib/core/network/` y el manejo de errores en
`lib/core/errors/` y `lib/core/network/api_exception_mapper.dart`.

## Qué se hizo

- **Proyecto y dependencias:** `pubspec.yaml` declara Flutter, `flutter_riverpod`
	`^3.4.3`, `go_router` `^18.0.2`, Dio `^5.11.1` e intl `^0.20.3`. El lockfile
	existe, está versionado y se actualiza con `flutter pub get`. La única
	dependencia directa de desarrollo es `flutter_test`, necesaria para los
	tests; no se agregaron paquetes de mocking.
- **Entrada y tema:** `main.dart` inicia con `ProviderScope`. `app.dart` enlaza
	`MaterialApp.router`, el router y el tema centralizado.
- **Navegación:** las rutas de procesos permiten consultar procesos y versiones,
	abrir estructuras y editar evidencias en borradores con permisos por rol.
	Integraciones tiene una pantalla funcional para Administrador. Otras áreas
	aún incluyen placeholders. La ruta no encontrada muestra
	un error y un botón para volver al
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
	resultados y revisión humana de M2 aún no están implementados ni se tratan
	como errores HTTP.
- **Pruebas:** se verifican rutas, permisos, sesión, layout, Bearer presente y
	ausente, y mapeo de errores sin backend real.
- **Verificaciones M2 (selector de tickets):** `/verifications/new` usa el
	endpoint `POST /verifications/preview` para obtener `ticketSelectionGroups`,
	separa la lógica por `groupId` y valida el comportamiento para `ONE` y
	`MULTIPLE` sin inferir relaciones por nombre. La selección se envía en
	`ticketSelections` con el formato `[{ groupId, ticketIds: [...] }]`, y el
	botón de inicio queda habilitado solo cuando se cumple la selección
	obligatoria del grupo. La búsqueda de tickets realiza
	`GET /services/{serviceId}/tickets` con paginación. El flujo no crea un
	selector alternativo ni inventa grupos cuando la API no devuelve tickets.
- **Progreso de ejecución (WBS 7.3.3 · TC-186):** `/verifications/{runId}`
	consulta `GET /verifications/{runId}` con el `ApiClient` compartido. El
	backend es la fuente de verdad: Flutter presenta estado y progreso recibidos,
	no ejecuta controles ni calcula resultados de cumplimiento. La carga inicial
	muestra un spinner de página; las actualizaciones no reemplazan la pantalla
	y se indican discretamente como «Actualizando…».
- **Integraciones (WBS 5.3.5):** `/settings/integrations` consulta
	`GET /integrations/status` y prueba lectura mediante `POST /integrations/test`
	con `ApiClient`. Los tests sustituyen `IntegrationsRepository` por un fake de
	Riverpod, sin red ni backend. La prueba integrada con Spring Boot está **No
	verificado** hasta que existan esos endpoints. «Disponible» describe el estado
	general de la conexión; no confirma el acceso a carpetas o proyectos por
	servicio.

## Rutas

Todas las rutas salvo `/login` están bajo el shell autenticado. Sin sesión, una
ruta protegida redirige a `/login`; un Lector que solicita una ruta exclusiva
de Administrador vuelve a `/`.

| Ruta | Nombre | Sin sesión | Lector | Administrador | Estado |
|---|---|---|---|---|---|
| `/login` | `login` | Permitida | Redirige a `/` | Redirige a `/` | Temporal |
| `/` | `home` | Redirige a `/login` | Permitida | Permitida | Temporal |
| `/processes` | `processes` | Redirige a `/login` | Permitida | Permitida | Funcional |
| `/processes/:id` | `process-details` | Redirige a `/login` | Permitida | Permitida | Funcional |
| `/processes/:id/history` | `process-history` | Redirige a `/login` | Permitida | Permitida | Funcional |
| `/processes/:processId/versions/:versionId/structure` | `process-structure` | Redirige a `/login` | Consulta | Edición solo en borrador | Funcional |
| `/services` | `services` | Redirige a `/login` | Permitida | Permitida | Temporal |
| `/verifications` | `verifications` | Redirige a `/login` | Permitida | Permitida | Temporal |
| `/verifications/new` | `new-verification` | Redirige a `/login` | Redirige a `/` | Permitida | Funcional |
| `/verifications/:runId` | `verification-details` | Redirige a `/login` | Permitida | Permitida | Funcional |
| `/verifications/:runId/results` | `verification-results` | Redirige a `/login` | Permitida | Permitida | Temporal |
| `/settings/integrations` | `integrations` | Redirige a `/login` | Redirige a `/` | Permitida | Funcional |

Los nombres y paths están en `lib/app/router/route_names.dart`. Las rutas
exclusivas de Administrador están en `RouteNames.adminOnlyPaths`; para agregar
otra, incorporá su path a ese set. El redirect consulta el helper
`RouteNames.isAdminOnly`. `/verifications/new` está declarada antes de
`/verifications/:runId`, por lo que el path estático no se captura como un
detalle.

## Progreso de ejecución (WBS 7.3.3 · TC-186)

La pantalla de detalle reemplaza el placeholder de `/verifications/{runId}`.
Puede abrirse desde el flujo de inicio cuando `POST /verifications` devuelve
un `id`, o directamente usando la URL. En ambos casos el `runId` de la ruta es
la identidad de la consulta; no depende de estado de navegación previo.

### Contrato y capas

La implementación conserva el flujo **vista → ViewModel → repositorio →
ApiClient**:

| Capa | Archivo(s) | Responsabilidad |
|---|---|---|
| Vista | `lib/features/verifications/view/verification_run_page.dart` | Muestra carga, datos, estado, progreso, errores recuperables y acciones. No hace HTTP ni decide resultados. |
| ViewModel | `lib/features/verifications/viewmodel/verification_run_view_model.dart` | Se asocia al `runId`, carga inicialmente, serializa refrescos, maneja el polling y libera el temporizador. |
| Contrato de repositorio | `lib/features/verifications/data/verification_repository.dart` | Declara `getVerification(runId)`. |
| Repositorio HTTP | `lib/features/verifications/data/verification_repository_impl.dart` | Ejecuta `GET /verifications/{runId}`, traduce 404 y mapea errores/respuesta. |
| DTO y mapeo | `lib/features/verifications/data/dto/verification_history_dtos.dart` | Convierte el JSON `VerificationRun` y `progress` al modelo de UI. |
| Modelos | `lib/features/verifications/model/verification_history_models.dart` | Define estados, progreso y datos de una ejecución. |
| Ruta | `lib/app/router/app_router.dart` | Construye `VerificationRunPage` con el parámetro `runId`. |

El `ApiClient` agrega el JWT de la sesión cuando existe; la vista no recibe ni
manipula el token. El formato de respuesta esperado sigue el esquema
`VerificationRun` del OpenAPI del proyecto: `id`, `serviceId`,
`processVersionId`, `scope`, `status`, `progress`, `startedAt` y, cuando
corresponda, `macroActivityId`, `note`, `finishedAt` y `failureMessage`.
`progress` contiene `processed`, `total` y `reviewRequired`. Los campos de
identidad o contexto que el backend devuelva no se convierten en nombres
legibles por inferencia.

### Estados y ciclo de vida del polling

| Estado recibido | Texto en pantalla | Comportamiento |
|---|---|---|
| `QUEUED` | En espera | Consulta periódica activa. |
| `RUNNING` | En curso | Consulta periódica activa. |
| `COMPLETED` | Finalizada | Detiene el polling y habilita el acceso a resultados. |
| `FAILED` | Fallida | Detiene el polling, muestra `failureMessage` si existe y ofrece salir o iniciar una ejecución nueva. |

El ViewModel consulta inmediatamente al cargarse. Mientras el estado sea
`QUEUED` o `RUNNING`, vuelve a consultar cada tres segundos (valor configurable
por `verificationRunPollingIntervalProvider`). No inicia una solicitud si la
anterior sigue pendiente. Al llegar a un estado terminal cancela el timer; el
provider auto-dispose cancela el mismo al abandonar la ruta. Los estados
desconocidos se presentan como «Estado no reconocido» y no se consideran
pollables.

### Progreso y datos visibles

- Siempre se muestra `processed` y `total` como «N de M registros procesados».
- Si `total > 0`, se muestra barra determinada y porcentaje derivado del
	progreso recibido. Para `processed=4` y `total=10` se presenta «4 de 10» y
	«40 %».
- Si `total = 0`, la barra es indeterminada y se indica «Progreso
	indeterminado»; no se calcula ni se muestra un porcentaje.
- `reviewRequired` se presenta como «Requieren revisión: N». No se denomina
	errores ni incumplimientos y no modifica el estado técnico de la ejecución.
- La pantalla presenta alcance («Proceso completo» o «Macroactividad» con el
	ID informado), fecha/hora de inicio, identificador, IDs de servicio y versión
	del proceso, y nota si existe. Muestra la fecha/hora de finalización solo si
	el backend devuelve `finishedAt`. Las fechas se presentan en hora local.

### Errores y acciones

- Una falla al cargar por primera vez se muestra como error de página con
	reintento. Si responde `404`, el mensaje informa que la ejecución no existe o
	no se encuentra.
- Una falla al actualizar conserva el último estado conocido, muestra «No se
	pudo actualizar» y ofrece «Reintentar». Un error HTTP/de red no se representa
	como el estado funcional `FAILED`.
- Si el backend devuelve `FAILED`, se informa `failureMessage` cuando viene en
	la respuesta. Se ofrecen volver a Verificaciones y, para Administrador,
	iniciar una nueva verificación. No se reenvía la solicitud anterior: cada
	inicio crea otra ejecución.
- Si el backend devuelve `COMPLETED`, «Ver resultados» navega a
	`/verifications/{runId}/results`. Esa ruta sigue siendo placeholder hasta
	implementar WBS 7.3.4, y la pantalla lo advierte expresamente; el enlace no
	implica que los resultados ya estén implementados.

### Alcance pendiente de integración

La capa Flutter queda cubierta con respuestas simuladas. El recorrido real
contra Spring Boot no está verificado mientras no estén disponibles los
endpoints backend para iniciar y consultar ejecuciones. Esto no cambia el
alcance del ticket: no se implementan aquí el worker/backend, historial
7.3.7, resultados 7.3.4, decisiones humanas ni cancelación de ejecuciones.

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
- `test/features/processes/`: cubre serialización de evidencia, operaciones y
  orden, guardado/recarga, permisos y el contrato HTTP del catálogo.
- `test/features/integrations/`: cubre estados, fuentes, repositorio, carga,
	reintento, prueba exitosa/fallida, doble envío y layout móvil/escritorio con
	un repositorio falso.
- `test/features/verifications/verification_run_test.dart` y
	`verification_repository_impl_test.dart`: cubren progreso, polling serial y
	ciclo de vida, estados terminales, errores recuperables, presentación de
	estados y mapeo de `GET /verifications/{runId}`.
- `test/core/widgets/integration_status_widgets_test.dart`: cubre `StatusChip`,
	`IntegrationStatusCard` y el botón de reintento de `AppErrorView`.

Las sesiones de prueba se inyectan con overrides del provider de sesión. El
cliente HTTP permite inyectar `apiHttpClientAdapterProvider`; las pruebas usan
un adaptador falso que devuelve respuestas locales, sin llamar a un backend ni
a la red.

## Verificación

`flutter pub get`:

```text
Got dependencies!
5 packages have newer versions incompatible with dependency constraints.
```

`flutter analyze` (validación TC-186):

```text
Analyzing Repositorio-frontend-TEMA...
No issues found!
```

`flutter test` (suite completa, validación TC-186):

```text
00:47 +167: All tests passed!
```

Las pruebas usan repositorios/adaptadores simulados y no acreditan que el
backend responda a los endpoints de inicio y consulta.

`flutter run -d chrome`:

```text
Launching lib\main.dart on Chrome in debug mode...
Waiting for connection from debug service on Chrome...             45,3s
Flutter run key commands.
Starting application from main method in:
org-dartlang-app:///web_entrypoint.dart.
Application finished.
```

Chrome se inició sin error y el servicio de depuración quedó disponible. El
total de tests indicado arriba corresponde a la última ejecución real.

## Cómo continuar

El recorrido previsto para una funcionalidad nueva es:

```text
Page -> ViewModel -> Repository -> ApiClient
```

Esquema ilustrativo para una funcionalidad futura:

```dart
import 'package:proyecto_tema_frontend/core/network/api_client.dart';

final class ExampleRepository {
	ExampleRepository(this._apiClient);

	final ApiClient _apiClient;

	Future<Response<dynamic>> load() => _apiClient.get('/example');
}
```

Creá Page, ViewModel, modelos y repositorios dentro de la carpeta de
`lib/features/` correspondiente. Después reemplazá el `PlaceholderPage` de la
ruta correspondiente en `lib/app/router/app_router.dart`. Las páginas y
ViewModels no instancian Dio ni escriben URLs del backend; los repositorios
usan `ApiClient` desde `apiClientProvider`. Los estilos compartidos se
centralizan en `lib/app/theme/app_theme.dart`.

## Pendiente y fuera de alcance

Para la tarea **4.2.1** quedan pendientes el formulario y flujo real de login,
obtención/emisión del JWT, persistencia segura y sesión real. También queda por
definir allí la integración de la sesión real con los permisos de navegación.

Fuera del alcance de esta base: gestión de usuarios, formularios de procesos y
servicios, ejecución de verificaciones y evidencia/historial.

La prueba integrada con Spring Boot para las conexiones de Drive y Redmine está
**No verificado** hasta que el backend implemente `GET /integrations/status` y
`POST /integrations/test`. La interfaz se desarrolla y prueba con un repositorio
falso sustituible por Riverpod; no llama directamente a esos servicios.

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
- Para WBS 5.3.5, `IntegrationStatusCard` se ubica en `core/widgets` según la
	guía visual v1.3 y recibe datos ya resueltos, sin importar la feature. Los
	estados usan los tonos semánticos existentes (`success`, `warning`, `danger`,
	`info`); la ausencia de fuente usa tono neutro. No fue necesario agregar
	tokens ni modificar `app_theme.dart`.
- Un estado recibido desconocido produce un `UnexpectedFailure` con mensaje
	seguro; una fuente desconocida se ignora y queda representada como «Sin
	información». La especificación OpenAPI indicada no estaba disponible en el
	entorno, por lo que se implementó el contrato resumido en la tarea. La prueba
	integrada queda pendiente hasta que existan los endpoints del backend.
