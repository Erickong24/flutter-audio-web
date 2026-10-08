import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';

abstract class AudioBackend {
  Stream<double> get levels;
  Stream<PlayerState> get playerStates;
  Stream<RecordState> get recordStates;
  Future<void> start();
  Future<String?> finish();
  Future<void> play(String url);
  Future<void> pause();
  Future<void> stop();
  Future<void> dispose();
}

class WebAudioBackend implements AudioBackend {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  @override
  Stream<double> get levels => _recorder
      .onAmplitudeChanged(const Duration(milliseconds: 120))
      .map((value) => value.current);
  @override
  Stream<PlayerState> get playerStates => _player.onPlayerStateChanged;
  @override
  Stream<RecordState> get recordStates => _recorder.onStateChanged();
  @override
  Future<void> start() async {
    await _player.stop();
    if (!await _recorder.isEncoderSupported(AudioEncoder.wav)) {
      throw StateError(
        'Este navegador no permite grabar WAV. Prueba un navegador actualizado.',
      );
    }
    // WAV evita depender de AAC/Opus del navegador. La ruta no se usa en Web.
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: 'grabacion.wav',
    );
  }

  @override
  Future<String?> finish() => _recorder.stop();
  @override
  Future<void> play(String url) async {
    if (_player.state == PlayerState.paused) {
      await _player.resume();
    } else {
      // stop() devuelve una URL blob local, no una ruta del sistema de archivos.
      await _player.play(UrlSource(url, mimeType: 'audio/wav'));
    }
  }

  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> stop() => _player.stop();
  @override
  Future<void> dispose() async {
    await _player.dispose();
    await _recorder.dispose();
  }
}
