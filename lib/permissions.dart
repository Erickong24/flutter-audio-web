enum MicPermission { unknown, granted, denied, blocked, restricted }

abstract class PermissionGateway {
  Future<MicPermission> query();
  Future<MicPermission> request();
}

String permissionMessage(MicPermission status) => switch (status) {
  MicPermission.unknown => 'Pulsa Grabar para solicitar acceso al micrófono.',
  MicPermission.granted => 'Micrófono autorizado. Puedes grabar.',
  MicPermission.denied =>
    'Acceso rechazado. Puedes volver a intentar cuando quieras.',
  MicPermission.blocked => 'Acceso bloqueado. Permite el micrófono en los ajustes del sitio y comprueba de nuevo.',
  MicPermission.restricted => 'Acceso restringido. Usa HTTPS o localhost y revisa las políticas del navegador.',
};
