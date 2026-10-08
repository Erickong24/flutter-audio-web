import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

import 'audio_backend.dart';
import 'permissions.dart';

class AudioController extends ChangeNotifier {
  AudioController(this.permissions, this.audio) {
    _subscriptions.add(
      audio.levels.listen(
        (db) {
          level = db.isFinite ? ((db + 60) / 60).clamp(0.0, 1.0) : 0;
          _update();
        },
        onError: (_) {
          level = 0;
          _update();
        },
      ),
    );
    _subscriptions.add(
      audio.playerStates.listen(
        (value) {
          playerState = value;
          if (value == PlayerState.completed) {
            message = 'Reproducción finalizada. Puedes escucharla de nuevo.';
          }
          _update();
        },
        onError: (_) {
          message = 'Error de reproducción. Intenta de nuevo.';
          _update();
        },
      ),
    );
    _subscriptions.add(
      audio.recordStates.listen(
        (value) {
          // Una interrupción no debe dejar el contador avanzando como si grabara.
          if (recording && value != RecordState.record) {
            _clock.stop();
            recording = false;
            message = 'La captura se interrumpió. Pulsa Detener para finalizar el audio.';
            _update();
          }
        },
        onError: (_) {
          message = 'Error en la captura. Finaliza e intenta de nuevo.';
          _update();
        },
      ),
    );
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_clock.isRunning) _update();
    });
  }
  final PermissionGateway permissions;
  final AudioBackend audio;
  final _subscriptions = <StreamSubscription<dynamic>>[];
  final _clock = Stopwatch();
  late final Timer _timer;
  bool _closed = false;
  bool busy = false;
  bool recording = false;
  bool captureOpen = false;
  double level = 0;
  String? url;
  String message = permissionMessage(MicPermission.unknown);
  MicPermission permission = MicPermission.unknown;
  PlayerState playerState = PlayerState.stopped;
  Duration get elapsed => _clock.elapsed;
  String get time =>
      '${elapsed.inMinutes.toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
  void _update() {
    if (!_closed) notifyListeners();
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (busy || _closed) return;
    busy = true;
    _update();
    try {
      await action();
    } catch (error) {
      message = 'No se completó la operación: $error';
    } finally {
      busy = false;
      _update();
    }
  }

  Future<void> checkPermission() => _guard(() async {
    permission = await permissions.query();
    message = permissionMessage(permission);
  });

  Future<void> toggleRecording() => _guard(() async {
    if (captureOpen) {
      final result = await audio.finish();
      _clock.stop();
      recording = false;
      captureOpen = false;
      level = 0;
      if (result == null) {
        throw StateError('No se obtuvo una grabación. Intenta de nuevo.');
      }
      url = result;
      message = 'Grabación lista. Pulsa Reproducir para escucharla.';
      return;
    }
    permission = await permissions.request();
    if (_closed) return;
    message = permissionMessage(permission);
    if (permission != MicPermission.granted) return;
    await audio.start();
    if (_closed) {
      await audio.finish();
      return;
    }
    url = null;
    _clock.reset();
    _clock.start();
    recording = true;
    captureOpen = true;
    message = 'Grabando. Pulsa Detener cuando termines.';
  });

  Future<void> playPause() => _guard(() async {
    if (url == null || captureOpen) return;
    if (playerState == PlayerState.playing) {
      await audio.pause();
      message = 'Reproducción en pausa.';
    } else {
      await audio.play(url!);
      message = 'Reproduciendo tu grabación.';
    }
  });
  Future<void> stopPlayback() => _guard(() async {
    await audio.stop();
    message = 'Reproducción detenida.';
  });
  @override
  void dispose() {
    _closed = true;
    _timer.cancel();
    _clock.stop();
    for (final sub in _subscriptions) {
      unawaited(sub.cancel());
    }
    unawaited(audio.dispose().catchError((Object _) {}));
    super.dispose();
  }
}
