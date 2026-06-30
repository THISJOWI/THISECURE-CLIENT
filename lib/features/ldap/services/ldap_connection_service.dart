import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:thisjowi/core/api.dart';
import 'package:thisjowi/services/token_manager.dart';

enum LdapTestStep { tcpConnection, bind, searchBaseDn }

class LdapTestStepResult {
  final LdapTestStep step;
  final bool success;
  final String message;

  LdapTestStepResult({required this.step, required this.success, required this.message});
}

class LdapTestResult {
  final bool overallSuccess;
  final List<LdapTestStepResult> steps;
  final String? firstError;

  LdapTestResult({required this.overallSuccess, required this.steps, this.firstError});
}

class LdapConnectionService {
  TokenManager get _tokenManager => TokenManager();

  Future<LdapTestResult> testConnection({
    required String host,
    required String port,
    required String bindDn,
    required String baseDn,
    required String password,
  }) async {
    final steps = <LdapTestStepResult>[];
    final ldapUrl = 'ldap://$host:$port';

    final portNum = int.tryParse(port) ?? 389;

    // Step 1: TCP connection
    try {
      final socket = await Socket.connect(host, portNum,
          timeout: const Duration(seconds: 10));
      socket.destroy();
      steps.add(LdapTestStepResult(
        step: LdapTestStep.tcpConnection,
        success: true,
        message: 'Servidor LDAP alcanzable en $host:$port',
      ));
    } on SocketException catch (e) {
      steps.add(LdapTestStepResult(
        step: LdapTestStep.tcpConnection,
        success: false,
        message: 'No se puede conectar a $host:$port: ${e.message}',
      ));
      return LdapTestResult(
        overallSuccess: false,
        steps: steps,
        firstError: 'Host no alcanzable. Verifica la dirección y el puerto.',
      );
    } catch (e) {
      steps.add(LdapTestStepResult(
        step: LdapTestStep.tcpConnection,
        success: false,
        message: 'Error de conexión: $e',
      ));
      return LdapTestResult(
        overallSuccess: false,
        steps: steps,
        firstError: 'Error inesperado al conectar con el servidor.',
      );
    }

    // Step 2 & 3: Delegate to backend for Bind + Base DN search
    final token = await _tokenManager.getToken();
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/organizations/test-connection'),
            headers: {
              'Content-Type': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'ldapUrl': ldapUrl,
              'ldapBaseDn': baseDn,
              'ldapBindDn': bindDn,
              'ldapBindPassword': password,
            }),
          )
          .timeout(const Duration(seconds: 30));

      final body = jsonDecode(response.body);
      final success = response.statusCode == 200 && body['success'] == true;

      if (bindDn.isNotEmpty) {
        if (success) {
          steps.add(LdapTestStepResult(
            step: LdapTestStep.bind,
            success: true,
            message: 'Bind exitoso',
          ));
        } else {
          steps.add(LdapTestStepResult(
            step: LdapTestStep.bind,
            success: false,
            message: body['message'] ?? 'Bind fallido',
          ));
          return LdapTestResult(
            overallSuccess: false,
            steps: steps,
            firstError: 'Credenciales LDAP inválidas. Verifica Bind DN y contraseña.',
          );
        }
      }

      if (success && baseDn.isNotEmpty) {
        steps.add(LdapTestStepResult(
          step: LdapTestStep.searchBaseDn,
          success: true,
          message: 'Base DN encontrada',
        ));
      } else if (baseDn.isNotEmpty) {
        steps.add(LdapTestStepResult(
          step: LdapTestStep.searchBaseDn,
          success: false,
          message: body['message'] ?? 'Base DN no encontrada',
        ));
        return LdapTestResult(
          overallSuccess: false,
          steps: steps,
          firstError: 'Base DN no encontrada. Verifica la ruta.',
        );
      }

      return LdapTestResult(overallSuccess: true, steps: steps);
    } on SocketException {
      return LdapTestResult(
        overallSuccess: false,
        steps: steps,
        firstError: 'No se puede conectar al backend desde el cliente.',
      );
    } catch (e) {
      steps.add(LdapTestStepResult(
        step: LdapTestStep.bind,
        success: false,
        message: e.toString(),
      ));
      return LdapTestResult(
        overallSuccess: false,
        steps: steps,
        firstError: 'Error de conexión con el servidor.',
      );
    }
  }
}
