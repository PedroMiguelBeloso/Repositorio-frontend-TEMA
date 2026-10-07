# TC-190 · Ubicación de reglas de dominio en frontend

Esta tarea implementa el historial de ejecuciones de M2 en Flutter. La regla de diseño de dominio se aplica en la medida correspondiente al frontend; no se modifica el dominio, aplicación, controladores ni persistencia del backend.

| Regla / invariante | Ubicación | Por qué |
|---|---|---|
| Un estado técnico debe conservar su valor de API y su texto visible; `COMPLETED` significa que la ejecución terminó, no que el resultado de cumplimiento sea positivo. | `VerificationRunStatus` | El significado del estado pertenece al modelo y evita strings mágicos o que la UI lo interprete de forma distinta. La vista solo asigna el tono visual. |
| Los valores de alcance `PROCESS` y `MACRO_ACTIVITY` tienen una representación de negocio estable. | `VerificationScope` | El modelo concentra la traducción entre contrato y lenguaje de la interfaz. |
| `processed` y `total` representan progreso técnico; no se permite un progreso negativo ni `processed > total`. | `RunProgress.fromValues` | El modelo protege la invariante y expone operaciones derivadas (`fraction`, `fractionLabel`) sin trasladar la regla a cada widget. |
| Una ejecución identifica el proceso/version mediante `processVersionId`; si el servicio M1 contiene esa asignación, puede resolverse su nombre legible. | `Service.processForVersion` | La operación de búsqueda dentro de la entidad `Service` pertenece al modelo, no al ViewModel como recorrido de atributos. |
| El historial se pagina con los valores entregados por `PageInfo`. | `VerificationHistoryViewModel` | La paginación es estado/orquestación de pantalla: consulta el repositorio con `page`/`size`, respeta `totalPages` y no calcula cantidades ficticias. |
| El filtro permitido es exclusivamente `serviceId`; al cambiarlo se vuelve a la página 0. | `VerificationHistoryViewModel` + `VerificationRepository` | El ViewModel coordina la interacción; el repositorio encapsula el contrato HTTP. No se inventan filtros no definidos por OpenAPI. |
| El orden de cada página es exactamente el entregado por la API. | `VerificationHistoryPage` | No se agrega `sort`, ni se reordena localmente, porque OpenAPI no define un parámetro de orden. |
| Una actualización nunca inserta una fila local que el backend todavía no devolvió. | `VerificationHistoryViewModel.refresh` | La fuente de verdad de las ejecuciones es el repositorio/backend. |
| La autorización visual Admin/Lector se refleja en la vista, pero no sustituye autorización de backend. | `VerificationHistoryPage` + router existente | La UI oculta `Nueva verificación` para Lector; el backend sigue siendo la autoridad final. |

## Responsabilidades por capa

- **Modelo:** invariantes y operaciones propias de `VerificationRunStatus`, `VerificationScope`, `RunProgress` y `Service`.
- **Repositorio:** HTTP, parámetros, DTO y mapeo hacia modelos (`GET /verifications`).
- **ViewModel:** estado remoto de la pantalla, paginación, filtro, refresh, retry y protección frente a respuestas obsoletas.
- **View:** composición visual, responsive, navegación y uso de componentes compartidos.

La tarea es exclusivamente frontend. Por eso no cambia reglas de aplicación del backend, DTOs/controladores Spring, transacciones ni restricciones de base de datos. Las invariantes de concurrencia y autorización que deben resistir solicitudes simultáneas continúan perteneciendo al backend y a la persistencia.
