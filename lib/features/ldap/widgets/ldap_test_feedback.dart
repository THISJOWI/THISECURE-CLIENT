import 'package:flutter/material.dart';
import 'package:thisjowi/features/ldap/services/ldap_connection_service.dart';

class LdapTestFeedback extends StatelessWidget {
  final LdapTestResult result;

  const LdapTestFeedback({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result.overallSuccess
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: result.overallSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (result.firstError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.firstError!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ...result.steps.map((step) => _buildStepRow(step)),
          if (result.overallSuccess)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Conexión LDAP exitosa',
                    style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepRow(LdapTestStepResult step) {
    final label = switch (step.step) {
      LdapTestStep.tcpConnection => 'Conexión TCP',
      LdapTestStep.bind => 'Autenticación (Bind)',
      LdapTestStep.searchBaseDn => 'Búsqueda Base DN',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            step.success ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: step.success ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text('$label: ${step.message}', style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
