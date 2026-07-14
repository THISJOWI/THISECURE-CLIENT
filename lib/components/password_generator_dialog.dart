import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/password_generator_service.dart';
import '../i18n/translations.dart';
import 'liquid_glass.dart';

class PasswordGeneratorDialog {
  static Future<String?> show(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: _PasswordGeneratorSheet(),
      ),
    );
  }
}

class _PasswordGeneratorSheet extends StatefulWidget {
  @override
  State<_PasswordGeneratorSheet> createState() =>
      _PasswordGeneratorSheetState();
}

class _PasswordGeneratorSheetState extends State<_PasswordGeneratorSheet> {
  double _length = 16;
  bool _useUppercase = true;
  bool _useLowercase = true;
  bool _useNumbers = true;
  bool _useSymbols = false;

  String _password = '';

  bool get _anyCharTypeOn =>
      _useUppercase || _useLowercase || _useNumbers || _useSymbols;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    setState(() {
      _password = PasswordGeneratorService.generate(
        length: _length.round(),
        useUppercase: _useUppercase,
        useLowercase: _useLowercase,
        useNumbers: _useNumbers,
        useSymbols: _useSymbols,
      );
    });
  }

  void _cancel() => Navigator.pop(context);
  void _confirm() => Navigator.pop(context, _password);

  Color _strengthColor(double fraction) {
    if (fraction < 0.25) return Colors.red;
    if (fraction < 0.4) return Colors.orange;
    if (fraction < 0.6) return Colors.yellow.shade700;
    if (fraction < 0.8) return Colors.lightGreen;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final hasPassword = _password.isNotEmpty;
    final info = PasswordGeneratorService.strengthInfo(_password);
    final fraction = PasswordGeneratorService.strengthFraction(_password);
    final strengthColor = hasPassword ? _strengthColor(fraction) : Colors.grey;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LiquidGlass.wrap(
          Form(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Generate Password'.i18n,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      tooltip: 'Close'.i18n,
                      onPressed: _cancel,
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context)
                          .scaffoldBackgroundColor
                          .withValues(alpha: 0.3),
                    ),
                  ),
                  child: TextField(
                    readOnly: true,
                    controller: TextEditingController(text: _password),
                    style: TextStyle(
                      color: hasPassword
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.4),
                      fontSize: 18,
                      fontFamily: 'monospace',
                      letterSpacing: 1.5,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Generated password',
                      hintText: 'No characters selected'.i18n,
                      hintStyle: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.4),
                        fontSize: 14,
                        letterSpacing: 0,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: hasPassword ? 0.6 : 0.2),
                              size: 20,
                            ),
                            onPressed: hasPassword ? _generate : null,
                            tooltip: 'Regenerate'.i18n,
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.copy,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: hasPassword ? 0.6 : 0.2),
                              size: 20,
                            ),
                            onPressed: hasPassword
                                ? () {
                                    Clipboard.setData(
                                      ClipboardData(text: _password),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Password copied'.i18n),
                                      ),
                                    );
                                  }
                                : null,
                            tooltip: 'Copy'.i18n,
                            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: hasPassword ? fraction : 0,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation(strengthColor),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasPassword
                      ? '${info.label.i18n} (${info.bits.toStringAsFixed(0)} bits)'
                      : info.label.i18n,
                  style: TextStyle(
                    color: strengthColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Text(
                      'Password Length'.i18n,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _length.round().toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      '8',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: _length,
                        min: 8,
                        max: 64,
                        divisions: 56,
                        activeColor: Theme.of(context).colorScheme.onSurface,
                        onChanged: (v) => setState(() => _length = v),
                        onChangeEnd: (_) => _generate(),
                      ),
                    ),
                    Text(
                      '64',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                _buildSwitchTile(
                  label: 'Uppercase'.i18n,
                  subtitle: 'A-Z',
                  value: _useUppercase,
                  onChanged: (v) => _toggleCharType(
                    _useUppercase,
                    (val) => _useUppercase = val,
                    v,
                  ),
                ),
                const SizedBox(height: 4),
                _buildSwitchTile(
                  label: 'Lowercase'.i18n,
                  subtitle: 'a-z',
                  value: _useLowercase,
                  onChanged: (v) => _toggleCharType(
                    _useLowercase,
                    (val) => _useLowercase = val,
                    v,
                  ),
                ),
                const SizedBox(height: 4),
                _buildSwitchTile(
                  label: 'Numbers'.i18n,
                  subtitle: '0-9',
                  value: _useNumbers,
                  onChanged: (v) => _toggleCharType(
                    _useNumbers,
                    (val) => _useNumbers = val,
                    v,
                  ),
                ),
                const SizedBox(height: 4),
                _buildSwitchTile(
                  label: 'Symbols'.i18n,
                  subtitle: r'!@#$%^&*',
                  value: _useSymbols,
                  onChanged: (v) => _toggleCharType(
                    _useSymbols,
                    (val) => _useSymbols = val,
                    v,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: hasPassword ? _confirm : null,
                    icon: const Icon(Icons.check, size: 18),
                    label: Text('Use Password'.i18n),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.onSurface,
                      foregroundColor: Theme.of(context).scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      disabledBackgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                      disabledForegroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          context,
          padding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  void _toggleCharType(
    bool current,
    ValueChanged<bool> setter,
    bool newValue,
  ) {
    if (!newValue && !_anyCharTypeOn) {
      return;
    }
    setter(newValue);
    _generate();
  }

  Widget _buildSwitchTile({
    required String label,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.5),
            fontSize: 11,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: Theme.of(context).colorScheme.onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        dense: true,
      ),
    );
  }
}
