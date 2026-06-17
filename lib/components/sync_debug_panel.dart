import 'package:flutter/material.dart';
import '../data/local/database.dart';
import '../services/connectivityService.dart';

class SyncDebugPanel extends StatefulWidget {
  const SyncDebugPanel({super.key});

  @override
  State<SyncDebugPanel> createState() => _SyncDebugPanelState();
}

class _SyncDebugPanelState extends State<SyncDebugPanel> {
  final AppDatabase _db = AppDatabase.instance();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  bool _isLoading = false;
  Map<String, dynamic>? _syncResult;
  Map<String, int> _pendingCounts = {};

  @override
  void initState() {
    super.initState();
    _loadPendingCounts();
  }

  Future<void> _loadPendingCounts() async {
    setState(() => _isLoading = true);
    
    try {
      // Contar notas pendientes
      final pendingNotes = await (_db.select(_db.notes)
        ..where((n) => n.syncStatus.equals('pending')))
        .get();
      final notesCount = pendingNotes.length;
      
      // Contar passwords pendientes
      final pendingPasswords = await (_db.select(_db.passwords)
        ..where((p) => p.syncStatus.equals('pending')))
        .get();
      final passwordsCount = pendingPasswords.length;
      
      // Contar registros en queue
      final pendingRegistrations = await (_db.select(_db.syncQueue)
        ..where((s) => s.entityType.equals('registration')))
        .get();
      final queueCount = pendingRegistrations.length;
      
      // Contar OTP pendientes
      final pendingOtp = await (_db.select(_db.otpEntries)
        ..where((o) => o.syncStatus.isIn(['pending', 'error', 'deleted'])))
        .get();
      final otpCount = pendingOtp.length;
      
      setState(() {
        _pendingCounts = {
          'notes': notesCount,
          'passwords': passwordsCount,
          'registrations': queueCount,
          'otp': otpCount,
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading pending counts: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _forceSyncNow() async {
    setState(() {
      _isLoading = true;
      _syncResult = null;
    });
    
    print('🔄 Forzando sincronización manual... (DISABLED)');
    
    // Simulate sync delay
    await Future.delayed(const Duration(seconds: 1));
    
    final result = {'success': true, 'message': 'Sync is disabled'};
    
    setState(() {
      _syncResult = result;
      _isLoading = false;
    });
    
    // Recargar contadores
    await _loadPendingCounts();
  }
  @override
  Widget build(BuildContext context) {
    final isOnline = _connectivityService.isOnline;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Row(
            children: [
              const Icon(Icons.sync, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Panel de Sincronización',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Icon(
                isOnline ? Icons.wifi : Icons.wifi_off,
                color: isOnline ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: isOnline ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const Divider(height: 24),
          
          // Datos pendientes
          if (_isLoading && _pendingCounts.isEmpty)
            const Center(child: CircularProgressIndicator())
          else ...[
            _buildPendingItem('Notes', _pendingCounts['notes'] ?? 0, Icons.note),
            const SizedBox(height: 8),
            _buildPendingItem('Passwords', _pendingCounts['passwords'] ?? 0, Icons.lock),
            const SizedBox(height: 8),
            _buildPendingItem('OTP', _pendingCounts['otp'] ?? 0, Icons.security),
            const SizedBox(height: 8),
            _buildPendingItem('Registros', _pendingCounts['registrations'] ?? 0, Icons.person_add),
          ],
          
          const Divider(height: 24),
          
          // Botón de sincronización manual
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _forceSyncNow,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.sync),
              label: Text(_isLoading ? 'Sincronizando...' : 'Sincronizar Ahora'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Resultado de la última sincronización
          if (_syncResult != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _syncResult!['success'] == true
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _syncResult!['success'] == true
                      ? Colors.green
                      : Colors.red,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _syncResult!['success'] == true
                            ? Icons.check_circle
                            : Icons.error,
                        color: _syncResult!['success'] == true
                            ? Colors.green
                            : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _syncResult!['success'] == true
                            ? 'Sincronización Exitosa'
                            : 'Error en Sincronización',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _syncResult!['success'] == true
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (_syncResult!['notes'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Notes: ${_syncResult!['notes']['synced'] ?? 0} sync, ${_syncResult!['notes']['failed'] ?? 0} fail',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if (_syncResult!['passwords'] != null) ...[
                    Text(
                      'Passwords: ${_syncResult!['passwords']['synced'] ?? 0} sync, ${_syncResult!['passwords']['failed'] ?? 0} fail',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if (_syncResult!['registrations'] != null) ...[
                    Text(
                      'Registros: ${_syncResult!['registrations']['synced'] ?? 0} sync, ${_syncResult!['registrations']['failed'] ?? 0} fail',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                  if (_syncResult!['otp'] != null) ...[
                    Text(
                      'OTP: ${_syncResult!['otp']['synced'] ?? 0} sync, ${_syncResult!['otp']['failed'] ?? 0} fail',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingItem(String label, int count, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: count > 0 ? Colors.orange.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count pendiente${count != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: count > 0 ? Colors.orange.shade700 : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}
