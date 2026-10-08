import 'permissions.dart';

// Solo permite ejecutar pruebas de interfaz en la máquina de desarrollo.
class BrowserPermissions implements PermissionGateway {
  @override
  Future<MicPermission> query() async => MicPermission.restricted;
  @override
  Future<MicPermission> request() async => MicPermission.restricted;
}
