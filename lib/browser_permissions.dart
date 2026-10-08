import 'dart:js_interop';

import 'package:permission_handler/permission_handler.dart';
import 'package:web/web.dart' as web;

import 'permissions.dart';

class BrowserPermissions implements PermissionGateway {
  @override
  Future<MicPermission> query() async {
    if (!web.window.isSecureContext) return MicPermission.restricted;
    // Consultar no abre el diálogo. Algunos navegadores no admiten esta consulta.
    try {
      final status = await Permission.microphone.status;
      if (status.isGranted) return MicPermission.granted;
      if (status.isPermanentlyDenied) return MicPermission.blocked;
      if (status.isRestricted) return MicPermission.restricted;
      return MicPermission.unknown;
    } catch (_) {
      return MicPermission.unknown;
    }
  }

  @override
  Future<MicPermission> request() async {
    if (!web.window.isSecureContext) return MicPermission.restricted;
    try {
      // Se solicita desde el botón. Se cierran las pistas de esta comprobación;
      // record abrirá su propia captura al iniciar la grabación.
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(web.MediaStreamConstraints(audio: true.toJS))
          .toDart;
      for (final track in stream.getTracks().toDart) {
        track.stop();
      }
      return MicPermission.granted;
    } catch (error) {
      // Las excepciones de getUserMedia llegan como objetos JavaScript.
      final jsError = error as JSObject;
      if (jsError.isA<web.DOMException>()) {
        final domError = jsError as web.DOMException;
        if (domError.name == 'NotAllowedError') {
          final current = await query();
          return current == MicPermission.blocked
              ? MicPermission.blocked
              : MicPermission.denied;
        }
        if (domError.name == 'SecurityError') return MicPermission.restricted;
        if (domError.name == 'NotFoundError') {
          throw StateError(
            'No se encontró un micrófono. Conecta uno y vuelve a intentar.',
          );
        }
        if (domError.name == 'NotReadableError') {
          throw StateError(
            'El micrófono no está disponible. Revisa el sistema y otras aplicaciones.',
          );
        }
      }
      throw StateError(
        'No se pudo acceder al micrófono. Revisa HTTPS, permisos y el dispositivo.',
      );
    }
  }
}
