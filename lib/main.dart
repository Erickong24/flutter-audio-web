import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

import 'audio_backend.dart';
import 'audio_controller.dart';
import 'permissions_stub.dart'
    if (dart.library.js_interop) 'browser_permissions.dart';

void main() => runApp(const AudioApp());

class AudioApp extends StatelessWidget {
  const AudioApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Micrófono y audio · SS603',
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF175CD3)),
      scaffoldBackgroundColor: const Color(0xFFF4F7FC),
    ),
    home: const AudioPage(),
  );
}

class AudioPage extends StatefulWidget {
  const AudioPage({super.key, this.controller});
  final AudioController? controller;
  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  late final AudioController c =
      widget.controller ??
      AudioController(BrowserPermissions(), WebAudioBackend());
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  void _help() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Recuperar acceso al micrófono'),
      content: const Text(
        'Abre el icono de ajustes junto a la dirección del navegador. '
        'En Permisos del sitio, permite el micrófono. Vuelve y pulsa Comprobar permiso. '
        'Si es necesario, recarga la página: se perderá la grabación temporal. '
        'Si hay una política de tu institución, contacta al administrador. '
        'La app no puede abrir ni cambiar estos ajustes por ti.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Laboratorio de audio'),
      actions: [
        IconButton(
          onPressed: _help,
          tooltip: 'Ayuda de permisos',
          icon: const Icon(Icons.help_outline),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListenableBuilder(
              listenable: c,
              builder: (context, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'SS603 · FLUTTER WEB',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Micrófono y audio',
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Graba, revisa y reproduce una nota de voz. El audio permanece en esta pestaña.',
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            c.recording ? Icons.mic : Icons.mic_none,
                            size: 48,
                            color: c.recording
                                ? const Color(0xFFB42318)
                                : const Color(0xFF175CD3),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            c.time,
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          Text(
                            c.recording
                                ? 'Grabando'
                                : c.captureOpen
                                ? 'Captura interrumpida'
                                : 'Listo',
                          ),
                          const SizedBox(height: 20),
                          Semantics(
                            label: 'Nivel de audio',
                            value: '${(c.level * 100).round()} por ciento',
                            child: LinearProgressIndicator(
                              value: c.level,
                              minHeight: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Nivel aproximado · dBFS, no decibelios acústicos',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    liveRegion: true,
                    child: Text(c.message, key: const Key('message')),
                  ),
                  if (c.busy) ...[
                    const SizedBox(height: 8),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: c.busy ? null : c.toggleRecording,
                    icon: Icon(c.captureOpen ? Icons.stop : Icons.mic),
                    label: Text(c.captureOpen ? 'Detener grabación' : 'Grabar'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: c.busy || c.url == null || c.captureOpen
                            ? null
                            : c.playPause,
                        icon: Icon(
                          c.playerState == PlayerState.playing
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        label: Text(
                          c.playerState == PlayerState.playing
                              ? 'Pausar'
                              : c.playerState == PlayerState.paused
                              ? 'Continuar'
                              : 'Reproducir',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: c.busy || c.url == null || c.captureOpen
                            ? null
                            : c.stopPlayback,
                        icon: const Icon(Icons.stop),
                        label: const Text('Detener audio'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      TextButton(
                        onPressed: c.busy || c.captureOpen
                            ? null
                            : c.checkPermission,
                        child: const Text('Comprobar permiso'),
                      ),
                      TextButton(
                        onPressed: _help,
                        child: const Text('Ajustes del sitio'),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text(
                    'WAV · mono · solicitud de 44,1 kHz\nHTTPS o localhost · sin cargas al servidor\nUna nueva grabación reemplaza la anterior. Recargar elimina el audio.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
