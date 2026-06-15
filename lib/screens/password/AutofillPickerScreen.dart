import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:thisjowi/core/service_locator.dart';
import 'package:thisjowi/data/models/password_entry.dart';
import 'package:thisjowi/data/repository/passwordsRepository.dart';
import 'package:thisjowi/services/autofillService.dart';
import 'package:thisjowi/services/biometricService.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/components/error_bar.dart';

class AutofillPickerScreen extends StatefulWidget {
  final AutofillRequest request;

  const AutofillPickerScreen({super.key, required this.request});

  @override
  State<AutofillPickerScreen> createState() => _AutofillPickerScreenState();
}

class _AutofillPickerScreenState extends State<AutofillPickerScreen> {
  late final PasswordsRepository _passwordsRepository;
  final AutofillService _autofillService = AutofillService();
  final BiometricService _biometricService = BiometricService();

  List<PasswordEntry> _passwords = [];
  bool _isLoading = true;
  bool _isAuthenticated = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    final sl = ServiceLocator();
    _passwordsRepository = sl.passwordsRepository;
    // Try to pre-fill search with the app name
    _searchQuery = widget.request.appName;
    _authenticate();
  }

  Future<void> _authenticate() async {
    final canCheck = await _biometricService.canCheckBiometrics();
    if (!canCheck) {
      setState(() => _isAuthenticated = true);
      _loadPasswords();
      return;
    }

      final success = await _biometricService.authenticate(
        localizedReason: 'Verify your identity to access THISECURE'.i18n,
      );

    if (success) {
      if (mounted) {
        setState(() => _isAuthenticated = true);
        _loadPasswords();
      }
    } else {
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _loadPasswords() async {
    setState(() => _isLoading = true);

    final result = await _passwordsRepository.getAllPasswords();

    if (!mounted) return;

    if (result['success'] == true) {
      final passwords = result['data'] as List<PasswordEntry>? ?? [];
      setState(() {
        _passwords = passwords;
        _isLoading = false;
      });
    } else {
      setState(() {
        _passwords = [];
        _isLoading = false;
      });
      ErrorSnackBar.show(
          context, result['message'] ?? 'Error loading passwords');
    }
  }

  List<PasswordEntry> get _filteredPasswords {
    if (_searchQuery.isEmpty) return _passwords;
    final query = _searchQuery.toLowerCase();
    return _passwords
        .where((p) =>
            p.title.toLowerCase().contains(query) ||
            p.username.toLowerCase().contains(query) ||
            p.website.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _selectCredential(PasswordEntry entry) async {
    final success = await _autofillService.provideAutofillCredentials(
      username: entry.username,
      password: entry.password,
    );

    if (success && mounted) {
      // In a real app, you might want to show a success message or just close
      Navigator.of(context).pop();
    } else if (mounted) {
      ErrorSnackBar.show(context, 'Error al proporcionar credenciales');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('${'Autofill for'.i18n} ${widget.request.appName}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: !_isAuthenticated
          ? const Center(child: Text('Esperando autenticación...'))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E).withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(25),
                          border:
                              Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: TextField(
                          autofocus: _searchQuery.isEmpty,
                          controller: TextEditingController(text: _searchQuery)
                            ..selection = TextSelection.fromPosition(
                                TextPosition(offset: _searchQuery.length)),
                          onChanged: (value) =>
                              setState(() => _searchQuery = value),
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                          decoration: InputDecoration(
                            hintText: 'Search passwords'.i18n,
                            hintStyle: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                fontSize: 16),
                            prefixIcon: Icon(Icons.search,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                size: 22),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.request.isSaveRequest)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.save, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${'Do you want to save credentials for'.i18n} ${widget.request.appName}?',
                                  style: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (widget.request.username != null)
                                  Text(
                                    'Usuario: ${widget.request.username}',
                                    style: TextStyle(
                                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                                        fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              // Logic to save the credential is not yet implemented in repo
                              ErrorSnackBar.showInfo(context,
                                  'Funcionalidad de guardado próximamente');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text('Save'.i18n),
                          )
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredPasswords.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No matching passwords found'.i18n,
                                    style:
                                        TextStyle(color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                  if (_searchQuery.isNotEmpty)
                                    TextButton(
                                      onPressed: () =>
                                          setState(() => _searchQuery = ''),
                                      child: const Text('Mostrar todos'),
                                    )
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredPasswords.length,
                              itemBuilder: (context, index) {
                                final entry = _filteredPasswords[index];
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                                      child: Icon(Icons.account_circle,
                                          color: Theme.of(context).colorScheme.primary),
                                    ),
                                    title: Text(
                                      entry.title,
                                      style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          '${'User'.i18n}: ${entry.username}',
                                          style: TextStyle(
                                              color: Theme.of(context).colorScheme.onSurface
                                                  .withValues(alpha: 0.8),
                                              fontSize: 13),
                                        ),
                                        if (entry.website.isNotEmpty)
                                          Text(
                                            entry.website,
                                            style: TextStyle(
                                                color: Theme.of(context).colorScheme.onSurface
                                                    .withValues(alpha: 0.4),
                                                fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                    trailing: Icon(Icons.chevron_right,
                                        color: Theme.of(context).colorScheme.onSurface),
                                    onTap: () =>
                                        _showSelectionConfirmation(entry),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
    );
  }

  void _showSelectionConfirmation(PasswordEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Confirmar autorrelleno',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Se usarán estas credenciales para ${widget.request.appName}:',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Text(entry.username,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context); // Close bottom sheet
                  _selectCredential(entry);
                },
                child: const Text('AUTORRELLENAR',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text('Cancel'.i18n),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
