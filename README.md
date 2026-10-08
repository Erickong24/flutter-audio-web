# Micrófono y audio · Flutter Web

Ejemplo SS603: grabación temporal WAV, duración, nivel aproximado, reproducción, pausa y detención. Aplicación diseñada exclusivamente para el navegador.

## Requisitos e instalación

Flutter 3.47.0 / Dart 3.13.0 utilizados en esta entrega; navegador moderno con micrófono y permiso del sistema. Conserva `pubspec.lock`.

```sh
flutter pub get
flutter run -d chrome --web-port 5319
```

Alternativa para elegir navegador:

```sh
flutter run -d web-server --web-hostname localhost --web-port 5319
```

Abre `http://localhost:5319`. En producción sirve `build/web` por HTTPS. No uses HTTP desde una IP de red para probar el micrófono. Si la página está en un iframe, revisa Permissions-Policy y `allow="microphone"` en el documento anfitrión.

```sh
flutter analyze
flutter test
flutter build web
```

## Uso

1. Pulsa Grabar y responde al diálogo del navegador.
2. Observa contador y nivel; pulsa Detener grabación.
3. Pulsa Reproducir, Pausar, Continuar y Detener audio.
4. Para probar rechazo, restablece el permiso del sitio, vuelve a Grabar y rechaza. La persistencia del rechazo depende del navegador.
5. Para probar bloqueo, bloquea el micrófono en los ajustes del sitio; pulsa Comprobar permiso y Grabar. La app no debe iniciar captura.
6. Pulsa Ajustes del sitio para ver las instrucciones de recuperación. Permite de nuevo y comprueba el estado.

Una nueva grabación reemplaza la anterior. Recargar pierde el audio. No hay descarga, persistencia ni envío de la nota a un servidor. La resolución y frecuencia reales de captura dependen del navegador. La barra representa dBFS escalados entre aproximadamente −60 y 0, no presión acústica.

## Permisos de Web

| Caso | Respuesta |
|---|---|
| Permitido | Captura solo después de pulsar Grabar. |
| Rechazado | Mensaje y reintento voluntario. |
| Bloqueado | Instrucciones para ajustar el permiso del sitio. |
| Restringido / contexto inseguro | Revisar HTTPS, navegador y políticas. |
| Consulta no soportada | Estado desconocido; intentar la solicitud real. |

`permission_handler` consulta el permiso; la solicitud usa `getUserMedia` mediante `web` para distinguir errores de dispositivo. El navegador no garantiza distinguir rechazo temporal de bloqueo, ni identificar todas las restricciones. `openAppSettings()` no se utiliza. `path_provider` no es dependencia directa: no soporta Web.

## Estructura

```text
lib/main.dart                 Interfaz responsiva y ayuda
lib/audio_controller.dart     Estados y coordinación
lib/audio_backend.dart        record + audioplayers
lib/permissions.dart          Contrato, estados y mensajes
lib/browser_permissions.dart  Consulta y getUserMedia
lib/permissions_stub.dart     Adaptador para pruebas sin navegador
test/widget_test.dart         Flujo, rechazo, errores y tamaño móvil
web/                          Punto de entrada generado por Flutter
```

Las pruebas usan dobles de hardware y cubren estados, permisos y errores.
