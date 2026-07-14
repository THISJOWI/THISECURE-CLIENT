import 'package:flutter/material.dart';

class LdapStatusIndicator extends StatelessWidget {
  final bool isConnected;

  const LdapStatusIndicator({super.key, required this.isConnected});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.green : Colors.red,
            boxShadow: [
              BoxShadow(
                color: (isConnected ? Colors.green : Colors.red).withValues(alpha: 0.5),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isConnected ? 'LDAP Conectado' : 'LDAP Desconectado',
          style: TextStyle(
            fontSize: 13,
            color: isConnected ? Colors.green[700] : Colors.red[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
