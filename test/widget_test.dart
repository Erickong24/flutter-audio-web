import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:audio_web/audio_backend.dart';
import 'package:audio_web/audio_controller.dart';
import 'package:audio_web/permissions.dart';
import 'package:audio_web/main.dart';

class FakePermission implements PermissionGateway {
  MicPermission value = MicPermission.granted;
  @override
  Future<MicPermission> query() async => value;
  @override
  Future<MicPermission> request() async => value;
}

class FakeAudio implements AudioBackend {
  int starts = 0;
  bool fail = false;
  final states = StreamController<PlayerState>.broadcast();
  @override
  Stream<double> get levels => const Stream.empty();
  @override
  Stream<PlayerState> get playerStates => states.stream;
  @override
  Stream<RecordState> get recordStates => const Stream.empty();
  @override
  Future<void> start() async {
    if (fail) throw StateError('Sin dispositivo');
    starts++;
  }

  @override
  Future<String?> finish() async => 'blob:test';
  @override
  Future<void> play(String url) async => states.add(PlayerState.playing);
  @override
  Future<void> pause() async => states.add(PlayerState.paused);
  @override
  Future<void> stop() async => states.add(PlayerState.stopped);
  @override
  Future<void> dispose() async => states.close();
}

void main() {
  for (final permission in [
    MicPermission.denied,
    MicPermission.blocked,
    MicPermission.restricted,
  ]) {
    test('No captura con permiso $permission', () async {
      final p = FakePermission()..value = permission;
      final audio = FakeAudio();
      final c = AudioController(p, audio);
      await c.toggleRecording();
      expect(audio.starts, 0);
      expect(c.recording, false);
      expect(c.message, permissionMessage(permission));
      c.dispose();
    });
  }
  test('Grabar, finalizar, reproducir, pausar y detener', () async {
    final c = AudioController(FakePermission(), FakeAudio());
    await c.toggleRecording();
    expect(c.recording, true);
    await c.toggleRecording();
    expect(c.url, 'blob:test');
    expect(c.recording, false);
    await c.playPause();
    await Future<void>.delayed(Duration.zero);
    expect(c.playerState, PlayerState.playing);
    await c.playPause();
    await Future<void>.delayed(Duration.zero);
    expect(c.playerState, PlayerState.paused);
    await c.stopPlayback();
    await Future<void>.delayed(Duration.zero);
    expect(c.playerState, PlayerState.stopped);
    c.dispose();
  });
  test('Error de hardware libera el bloqueo de interfaz', () async {
    final audio = FakeAudio()..fail = true;
    final c = AudioController(FakePermission(), audio);
    await c.toggleRecording();
    expect(c.busy, false);
    expect(c.recording, false);
    expect(c.message, contains('Sin dispositivo'));
    c.dispose();
  });
  testWidgets('Interfaz móvil: controles y ayuda sin desbordamiento', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = AudioController(FakePermission(), FakeAudio());
    await tester.pumpWidget(MaterialApp(home: AudioPage(controller: c)));
    expect(find.text('Micrófono y audio'), findsOneWidget);
    await tester.tap(find.text('Grabar'));
    await tester.pump();
    expect(find.text('Detener grabación'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
