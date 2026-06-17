import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/core/providers/otp_provider.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/components/liquid_glass.dart';
import 'package:thisjowi/components/password_generator_dialog.dart';
import 'package:thisjowi/services/otpService.dart';
import 'package:thisjowi/screens/notes/EditNoteScreen.dart';
import 'package:thisjowi/screens/otp/OtpQrScannerScreen.dart';
import 'package:thisjowi/utils/DialogUtils.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/data/repository/passwordsRepository.dart';
import 'package:thisjowi/data/repository/notes_repository.dart';

class GlobalActions {
  static Future<void> createPassword(BuildContext context,
      {VoidCallback? onSuccess}) async {
    final repository = context.read<PasswordsRepository>();

    final titleController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final websiteController = TextEditingController();
    bool obscurePassword = true;

    Widget buildField({
      required TextEditingController controller,
      required String label,
      IconData? icon,
      bool isPassword = false,
      bool obscure = false,
      VoidCallback? onToggleObscure,
      VoidCallback? onGenerate,
    }) {
      final suffixWidgets = <Widget>[];
      if (isPassword) {
        suffixWidgets.add(
          IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            onPressed: onToggleObscure,
          ),
        );
      }
      if (onGenerate != null) {
        suffixWidgets.add(
          IconButton(
            icon: Icon(
              Icons.auto_awesome,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              size: 20,
            ),
            onPressed: onGenerate,
          ),
        );
      }
      return TextField(
        controller: controller,
        obscureText: obscure,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), size: 20)
              : null,
          suffixIcon: suffixWidgets.isEmpty
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: suffixWidgets,
                ),
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
        ),
      );
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Center(
          child: SizedBox(
            width: 400,
            child: Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: LiquidGlass.wrap(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                      child: Text('Add Password'.i18n,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            buildField(
                              controller: titleController,
                              label: 'Title'.i18n,
                              icon: Icons.title,
                            ),
                            const SizedBox(height: 16),
                            buildField(
                              controller: usernameController,
                              label: 'Username'.i18n,
                              icon: Icons.person,
                            ),
                            const SizedBox(height: 16),
                            buildField(
                              controller: passwordController,
                              label: 'Password'.i18n,
                              icon: Icons.lock,
                              isPassword: true,
                              obscure: obscurePassword,
                              onToggleObscure: () => setDialogState(() => obscurePassword = !obscurePassword),
                              onGenerate: () async {
                                final generated =
                                    await PasswordGeneratorDialog.show(context);
                                if (generated != null && generated.isNotEmpty) {
                                  passwordController.text = generated;
                                  setDialogState(() => obscurePassword = false);
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            buildField(
                              controller: websiteController,
                              label: 'Website'.i18n,
                              icon: Icons.link,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withValues(alpha: 0.8),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(context, false),
                            child: Text('Cancel'.i18n),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Add'.i18n),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                context,
                borderRadius: 16,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (result == true) {
      final title = titleController.text.trim();
      final password = passwordController.text.trim();

      if (title.isEmpty || password.isEmpty) {
        if (context.mounted) {
          ErrorSnackBar.show(context, 'Title and password are required'.i18n);
        }
        return;
      }

      if (context.mounted) {
        final data = {
          'title': title,
          'username': usernameController.text.trim(),
          'password': password,
          'website': websiteController.text.trim(),
        };
        final saveResult = await repository.addPassword(data);

        if (saveResult['success'] == true) {
          ErrorSnackBar.showSuccess(context, 'Password added'.i18n);
          if (onSuccess != null) onSuccess();
        } else {
          if (context.mounted) {
            ErrorSnackBar.show(context, saveResult['message'] ?? 'Error saving password'.i18n);
          }
        }
      }
    }
  }

  static Future<void> quickGeneratePassword(BuildContext context) async {
    await PasswordGeneratorDialog.show(context);
  }

  static Future<void> createNote(BuildContext context,
      {VoidCallback? onSuccess}) async {
    final repository = context.read<NotesRepository>();
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditNoteScreen(
          notesRepository: repository,
        ),
      ),
    );
    if (created == true && onSuccess != null) {
      onSuccess();
    }
  }

  static Future<void> createMessage(BuildContext context,
      {VoidCallback? onSuccess}) {
    return DialogUtils.showNewMessageDialog(context, onSuccess: onSuccess);
  }

  static Future<void> createOtp(BuildContext context,
      {VoidCallback? onSuccess}) async {
    final otpService = OtpService();

    final nameController = TextEditingController();
    final issuerController = TextEditingController();
    final secretController = TextEditingController();

    Widget buildTextField({
      required TextEditingController controller,
      required String label,
      String? hint,
    }) {
      return TextField(
        controller: controller,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          ),
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
        ),
      );
    }

    // Show Dialog
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => Center(
        child: SizedBox(
          width: 400,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: LiquidGlass.wrap(
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Text('Add OTP'.i18n,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          buildTextField(
                            controller: nameController,
                            label: 'Account name'.i18n,
                            hint: 'user@example.com',
                          ),
                          const SizedBox(height: 16),
                          buildTextField(
                            controller: issuerController,
                            label: 'Issuer'.i18n,
                            hint: 'Google, GitHub...',
                          ),
                          const SizedBox(height: 16),
                          buildTextField(
                            controller: secretController,
                            label: 'Secret key'.i18n,
                            hint: 'JBSWY3DPEHPK3PXP',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).colorScheme.onSurface,
                          side: BorderSide(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5), width: 3),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.qr_code_scanner, size: 20),
                        label: Text('Scan QR'.i18n),
                        onPressed: () async {
                          final scanned = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const OtpQrScannerScreen(),
                            ),
                          );
                          if (scanned == true) {
                            Navigator.of(context, rootNavigator: true).pop(true);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'.i18n),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          onPressed: () async {
                            final name = nameController.text.trim();
                            final issuer = issuerController.text.trim();
                            final secret = secretController.text.trim();
                            if (name.isEmpty || secret.isEmpty) {
                              ErrorSnackBar.showWarning(context, 'Name and secret are required'.i18n);
                              return;
                            }
                            final provider = context.read<OtpProvider>();
                            final success = await provider.addOtpEntry({
                              'name': name,
                              'issuer': issuer,
                              'secret': secret,
                              'type': 'totp',
                              'algorithm': 'SHA1',
                              'digits': 6,
                              'period': 30,
                            });
                            if (success) {
                              onSuccess?.call();
                              if (context.mounted) Navigator.pop(context, true);
                            } else {
                              if (context.mounted) {
                                ErrorSnackBar.show(context, provider.errorMessage.isNotEmpty
                                    ? provider.errorMessage
                                    : 'Error adding OTP'.i18n);
                              }
                            }
                          },
                          child: Text('Add'.i18n),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              context,
              borderRadius: 16,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && onSuccess != null) {
      onSuccess();
    }
  }
}
