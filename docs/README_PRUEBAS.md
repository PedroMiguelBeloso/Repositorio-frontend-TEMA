# Guía de pruebas paso a paso — Proyecto Tema Frontend

Esta guía quedó escrita para seguirla en Windows PowerShell, sin perder nada del README principal y con evidencia real del proyecto actual.

> Este repositorio usa Flutter 3.47.5 stable y Dart 3.13.x. La última verificación ejecutada en este workspace dio `flutter analyze` limpio y `flutter test` con 110 tests pasados.

## 1) Antes de empezar

### 1.1 Abrir la terminal en la carpeta del proyecto

```powershell
cd C:\dev\proyecto_tema_frontend
```

### 1.2 Verificar SDK y ruta real de Flutter

```powershell
where.exe flutter
flutter --version
```

Resultado esperado real en este proyecto:

```text
C:\flutter\flutter\bin\flutter.bat
Flutter 3.47.5 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 6a19cca564 (2 weeks ago) • 2026-09-17 14:13:22 -0400
Engine • hash ab598368592da0064197e2bc15c7f5b0a2c6bb1f (revision af7e796e16) (15days ago) • 2026-09-16 18:09:59.000Z
Tools • Dart 3.13.4 • DevTools 2.60.0
```

Si `where.exe flutter` muestra una ruta dentro de OneDrive o de una carpeta protegida, se debe corregir la instalación antes de seguir. No se debe seguir con un SDK distinto al indicado por el proyecto.

### 1.3 Verificar rama y estado

```powershell
git branch --show-current
git status
```

Resultado esperado real:

```text
feature/wbs-5-3-5-estado-disponibilidad-fuentes
On branch feature/wbs-5-3-5-estado-disponibilidad-fuentes
Your branch is up to date with 'origin/feature/wbs-5-3-5-estado-disponibilidad-fuentes'.

nothing to commit, working tree clean
```

### 1.4 Resolver dependencias

```powershell
flutter pub get
```

Resultado esperado real:

```text
Resolving dependencies...
Downloading packages...
Got dependencies!
5 packages have newer versions incompatible with dependency constraints.
```

> No se agregaron paquetes nuevos. La dependencia de desarrollo existente sigue siendo `flutter_test`.

---

## 2) Pruebas automáticas

### 2.1 Análisis estático

```powershell
flutter analyze
```

Resultado esperado real:

```text
Analyzing proyecto_tema_frontend...
No issues found! (ran in 4.6s)
```

### 2.2 Suite completa

```powershell
flutter test
```

Resultado esperado real:

```text
00:16 +110: All tests passed!
```

La cifra real en esta última ejecución es: 110 tests.

### 2.3 Ejecutar un archivo concreto

```powershell
flutter test test/core/network/api_client_test.dart
```

Resultado esperado real: se ejecuta solo ese archivo y se reportan los tests incluidos.

### 2.4 Ejecutar un test por nombre

```powershell
flutter test --name "does not add an Authorization header without a session token"
```

Resultado esperado real: solo se ejecuta el test cuyo nombre coincide con ese texto.

### 2.5 Cobertura

```powershell
flutter test --coverage
```

Resultado esperado real en este proyecto: funciona si el entorno puede generar el reporte; si falla por entorno, se marca como “No verificado”. En este workspace no se exigió un reporte de cobertura para cerrar la tarea.

### 2.6 Mapa de tests del repo

| Archivo | Qué cubre | Comando |
|---|---|---|
| `test/widget_test.dart` | router, rutas protegidas, permisos por rol, redirects, layout | `flutter test test/widget_test.dart` |
| `test/core/network/api_client_test.dart` | token Bearer y ausencia del header sin sesión | `flutter test test/core/network/api_client_test.dart` |
| `test/core/network/api_exception_mapper_test.dart` | mapeo de errores HTTP y Problem Detail | `flutter test test/core/network/api_exception_mapper_test.dart` |
| `test/core/widgets/async_content_test.dart` | loading, error con retry y estado vacío | `flutter test test/core/widgets/async_content_test.dart` |
| `test/core/widgets/integration_status_widgets_test.dart` | `StatusChip`, `IntegrationStatusCard` y error view | `flutter test test/core/widgets/integration_status_widgets_test.dart` |
| `test/features/integrations/integration_status_dto_test.dart` | mapeo de estados, fuente, message y checkedAt | `flutter test test/features/integrations/integration_status_dto_test.dart` |
| `test/features/integrations/integrations_view_model_test.dart` | carga, retry, prueba exitosa, falla, doble envío, fuente ausente | `flutter test test/features/integrations/integrations_view_model_test.dart` |
| `test/features/integrations/integrations_page_test.dart` | pantalla de Integraciones, estados, contenido, botón, loading | `flutter test test/features/integrations/integrations_page_test.dart` |
| `test/features/integrations/integrations_repository_impl_test.dart` | repositorio con `ApiClient` y contract HTTP | `flutter test test/features/integrations/integrations_repository_impl_test.dart` |

> La carpeta `test/features/processes` y `test/features/services` sigue cubriendo procesos, servicios y permisos del resto del frontend. No se modificó ese código.

### 2.7 Cómo leer un fallo

Cuando un test falla, lo importante es leer tres cosas:

1. El nombre del test que falló.
2. El `Expected` y el `Actual`.
3. El archivo y la línea exacta en la salida.

Ejemplo real de lectura útil:

```text
Expected: <...>
Actual: <...>
```

Luego se revisa el archivo indicado y se busca el assert específico. En este proyecto, la forma de verificar roles y redirecciones es por `ProviderScope` con sesión simulada y `appRouterProvider`.

---

## 3) Arrancar la app

### 3.1 Verificar dispositivos

```powershell
flutter devices
```

Esto sirve para confirmar si Chrome aparece como dispositivo disponible para `flutter run -d chrome`.

### 3.2 Ejecutar la app

```powershell
flutter run -d chrome
```

Salida real verificada en este workspace:

```text
Launching lib\main.dart on Chrome in debug mode...
Waiting for connection from debug service on Chrome...             45,2s

Flutter run key commands.
r Hot reload.
R Hot restart.
h List all available interactive commands.
d Detach (terminate "flutter run" but leave application running).
c Clear the screen
q Quit (terminate the application on the device).

This app is linked to the debug service: ws://127.0.0.1:56214/e2n7NiDprnM=/ws
Debug service listening on ws://127.0.0.1:56214/e2n7NiDprnM=/ws
A Dart VM Service on Chrome is available at: http://127.0.0.1:56214/e2n7NiDprnM=
The Flutter DevTools debugger and profiler on Chrome is available at:
http://127.0.0.1:56214/e2n7NiDprnM=/devtools/?uri=ws://127.0.0.1:56214/e2n7NiDprnM=/ws
Starting application from main method in:
org-dartlang-app:///web_entrypoint.dart.
[HTTP] POST /api/v1/auth/login status=network duration=34ms
[HTTP] POST /api/v1/auth/login status=network duration=12ms

Application finished.
```

### 3.3 Cerrar la app

En la terminal de Flutter, escribir:

```powershell
q
```

### 3.4 Hot Reload y Hot Restart

Dentro del proceso de `flutter run -d chrome` se puede usar:

- `r` para hot reload.
- `R` para hot restart.
- `h` para ver las opciones disponibles.

### 3.5 Consola del navegador

Para ver logs de navegador, abrir DevTools del Chrome con F12 y entrar a la pestaña Console. En esta app, es normal ver llamadas de red de login y de la API si el backend está levantado o si la app intenta contactarlo.

---

## 4) Pruebas manuales en el navegador

### 4.1 Rutas reales y comportamiento

La app usa `GoRouter` con `ShellRoute` y guardas de sesión. Los datos reales del código están en:

- `lib/app/router/app_router.dart`
- `lib/app/router/route_names.dart`
- `lib/core/auth/session.dart`
- `lib/core/auth/session_provider.dart`

La sesión por defecto es `null`. La app redirige a `/login` si no hay sesión válida. La restricción por rol se hace con `RouteNames.isAdminOnly()`.

| Ruta | Usuario | Resultado esperado |
|---|---|---|
| `/login` | sin sesión | permite entrar al login |
| `/` | sin sesión | redirige a `/login` |
| `/settings/integrations` | sin sesión | redirige a `/login` |
| `/settings/integrations` | Lector | redirige a `/` |
| `/settings/integrations` | Administrador | página real de Integraciones |
| `/cualquier-cosa` | cualquier usuario autenticado | pantalla de error con “Página no encontrada” y botón “Volver al inicio” |

### 4.2 Cómo comprobar roles sin inventar una login a mano

No existe un flujo de login manual verificado en esta app que permita entrar a mano como Administrador o Lector desde la UI. El comportamiento por rol se verifica en tests con sesión simulada, inyectando `Session(role: UserRole.administrator)` o `Session(role: UserRole.reader)` mediante `ProviderScope` y `sessionProvider` override.

Los tests reales para roles y rutas son:

- `test/widget_test.dart`
- `flutter test test/widget_test.dart`

### 4.3 Pantalla Integraciones (`/settings/integrations`)

La pantalla real de Integraciones está en `lib/features/integrations/view/integrations_page.dart`.

Lo que debe verse en la app si no hay backend conectado:

- error de carga seguro con el botón **Reintentar**;
- no se muestran detalles técnicos;
- no se convierten fuentes a `UNAVAILABLE` por un error de comunicación.

Los estados visibles de la feature se validan con los tests:

- `test/features/integrations/integration_status_dto_test.dart`
- `test/features/integrations/integrations_view_model_test.dart`
- `test/features/integrations/integrations_page_test.dart`
- `test/core/widgets/integration_status_widgets_test.dart`

Comandos para correrlos:

```powershell
flutter test test/features/integrations/integration_status_dto_test.dart
flutter test test/features/integrations/integrations_view_model_test.dart
flutter test test/features/integrations/integrations_page_test.dart
flutter test test/core/widgets/integration_status_widgets_test.dart
```

### 4.4 Botón “Probar integraciones”

Se valida en los tests del ViewModel y de la página:

- `test/features/integrations/integrations_view_model_test.dart`
- `test/features/integrations/integrations_page_test.dart`

El comportamiento real esperado es:

- botón habilitado mientras no hay llamada en curso;
- mientras corre, se muestra progreso y se deshabilita;
- si la llamada ya está en curso, no se dispara otra;
- la acción usa `POST /integrations/test` y actualiza los estados al terminar.

### 4.5 Responsive

Abrir la app en Chrome y cambiar el tamaño del viewport:

- ancho ≈ 360 px: cards apiladas verticalmente;
- ancho ≈ 1200 px: cards en fila horizontal;
- sin desbordes visibles en texto o botón;
- la navegación cambia de inferior a lateral según `AppScaffold`.

Para simular mobile en Chrome: F12 → Toggle device toolbar -> iPhone/Pixel.

### 4.6 Estado por texto, no solo color

Cada tarjeta debe mostrar:

- nombre de la fuente;
- estado en español con texto además de color;
- fecha con formato legible;
- `message` solo si el backend lo envía;
- “Sin información” si la fuente no existe en la respuesta.

Esto se ve en:

- `lib/core/widgets/integration_status_card.dart`
- `lib/core/widgets/status_chip.dart`

---

## 5) Probar la URL de la API

### 5.1 Ejecutar con otra base URL

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://otro-host:9999/api/v1
```

Esto reemplaza el valor por defecto que se define en `lib/core/config/environment.dart`.

### 5.2 Confirmar la URL en el navegador

Con F12 → Network o Console, se puede comprobar a qué host están apuntando las llamadas HTTP de la app.

### 5.3 Sin backend

La app no se rompe necesariamente y muestra mensajes seguros. Si la API no responde, la capa de errores de `AppFailure`/`ApiExceptionMapper` debe cubrir la falla sin exponer trazas ni JSON crudo.

### 5.4 CORS

Si se prueba contra un backend de Spring Boot desde Flutter Web, el backend debe permitir el origen de la app. Si no lo permite, se observará un error de red o CORS en el navegador.

---

## 6) Revisiones de código con búsquedas

### 6.1 `localhost` solo en `environment.dart`

```powershell
Get-ChildItem -Path 'lib' -Recurse -File | Select-String -Pattern 'localhost' -CaseSensitive:$false
```

Resultado esperado real:

```text
lib\core\config\environment.dart:4: 'http://localhost:8080/api/v1',
```

### 6.2 Sin ganchos de color directos en feature ni widgets compartidos

```powershell
Get-ChildItem -Path 'lib/features','lib/core/widgets' -Recurse -File | Select-String -Pattern 'Color\(0x|Colors\.' -CaseSensitive:$false
```

Resultado esperado real: no debe aparecer ningún match en esas rutas.

### 6.3 Sin `package:dio` en app ni feature Pages/ViewModels

```powershell
Get-ChildItem -Path 'lib/features','lib/app' -Recurse -File | Select-String -Pattern 'package:dio' -CaseSensitive:$false
```

Resultado esperado real: no aparece `package:dio` en `lib/features` ni `lib/app`, salvo el layer de infraestructura `core/network` que sí lo usa.

### 6.4 Sin credenciales o tokens escritos a mano

```powershell
Get-ChildItem -Path 'lib' -Recurse -File | Select-String -Pattern 'password|Bearer |eyJ' -CaseSensitive:$false
```

Resultado esperado real: sin coincidencias.

### 6.5 `pubspec.lock` sin cambios inesperados

```powershell
git diff -- pubspec.lock
```

Resultado esperado real: no salida.

---

## 7) Checklist antes de subir

- [x] `flutter analyze` limpio.
- [x] `flutter test` verde con la cifra real.
- [x] `flutter run -d chrome` arrancó.
- [x] README no se modificó más que con un enlace a la guía nueva.
- [x] No aparecen `.vscode/settings.json`, `OneDrive`, `C:\src`, `C:\Users` en `git status`.
- [x] La rama actual es `feature/wbs-5-3-5-estado-disponibilidad-fuentes`.
- [x] El PR debe apuntar a `dev`.

---

## 8) Problemas frecuentes

| Síntoma | Causa | Solución |
|---|---|---|
| `where.exe flutter` muestra una ruta de OneDrive | SDK instalado en carpeta no soportada | Instalar Flutter fuera de OneDrive y ajustar `PATH` |
| La terminal de VS Code usa otra versión | PATH local distinto al de la terminal normal | Verificar `where.exe flutter` y cerrar/reabrir la terminal |
| `pubspec.lock` cambia con otro SDK | `flutter pub get` corrió con una versión distinta | `git restore pubspec.lock` y volver a usar el SDK correcto |
| Chrome no aparece en `flutter devices` | Chrome no instalado o no está disponible para Flutter | Instalar Chrome o revisar el dispositivo activo |
| `Author identity unknown` | falta configuración de Git | `git config --global user.name` y `git config --global user.email` |
| `authentication failed` | credenciales de Git no configuradas | Verificar acceso al repo remoto y el token/SSH |
| “nothing to commit” | ya está todo guardado | Revisar `git status` |
| Un test falla | error real en lógica o en la prueba | Aislar con `flutter test --name "..."` y leer Expected/Actual |

---

## 9) Resultado de la última verificación

| Item | Valor real |
|---|---|
| Fecha | 2026-10-02 |
| Flutter | 3.47.5 |
| Dart | 3.13.4 |
| `flutter analyze` | `No issues found! (ran in 3.9s)` |
| `flutter test` | `00:15 +110: All tests passed!` |
| `flutter run -d chrome` | Verificado; app arrancó y cerró con `q` |
| Prueba integrada Spring Boot | No verificado |

### Nota importante

La prueba integrada con Spring Boot quedó marcada como “No verificado” porque este entorno no tiene el backend con los endpoints `/integrations/status` y `/integrations/test` desplegados. La app se valida con repositorio falso y tests de integración del frontend, sin depender de una red real.

---

## 10) Archivos relevantes del proyecto

- `lib/app/router/app_router.dart` — redirect, rutas autenticadas, rutas admin-only.
- `lib/app/router/route_names.dart` — nombres y paths centralizados.
- `lib/core/auth/session.dart` — validación de sesión y rol.
- `lib/core/auth/session_provider.dart` — provider de sesión con `null` por defecto.
- `lib/core/widgets/async_content.dart` — carga/error/vacío.
- `lib/core/widgets/app_error_view.dart` — error seguro con reintento.
- `lib/core/widgets/integration_status_card.dart` — card compartida de estado.
- `lib/core/widgets/status_chip.dart` — chip semántico.
- `lib/features/integrations/...` — modelo, DTO, repositorio, ViewModel y pantalla.
- `test/features/integrations/...` — tests reales del WBS 5.3.5.

---

## 11) Cierre

Esta guía quedó escrita con la evidencia real ejecutada en el workspace. Si algo cambia en el backend o en el SDK, debe volver a verificarse antes de usarla como referencia oficial.
