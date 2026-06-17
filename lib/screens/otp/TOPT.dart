import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/core/providers/otp_provider.dart';
import 'package:thisjowi/core/providers/sync_provider.dart';
import 'package:thisjowi/data/models/otp_entry.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/services/otpService.dart';
import 'package:thisjowi/components/error_bar.dart';
import 'package:thisjowi/components/button.dart';
import 'package:thisjowi/utils/GlobalActions.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with WidgetsBindingObserver {
  final OtpService _otpService = OtpService();
  late OtpProvider _otpProvider;
  VoidCallback? _syncListener;
  Timer? _globalTickTimer;
  final ValueNotifier<int> _tickNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _otpProvider = context.read<OtpProvider>();

    _globalTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickNotifier.value++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOtpData();
      _listenToSyncEvents();
      _otpProvider.startAutoRefresh();
    });
  }

  void _listenToSyncEvents() {
    try {
      final syncProvider = context.read<SyncProvider>();
      _syncListener = () {
        if (syncProvider.lastEventInfo.startsWith('otp/')) {
          _otpProvider.silentRefresh();
        }
      };
      syncProvider.addListener(_syncListener!);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && mounted) {
      _loadOtpData();
      try {
        _listenToSyncEvents();
        _otpProvider.startAutoRefresh();
      } catch (e) {}
    } else if (state == AppLifecycleState.paused && mounted) {
      try {
        if (_syncListener != null) {
          context.read<SyncProvider>().removeListener(_syncListener!);
          _syncListener = null;
        }
        _otpProvider.stopAutoRefresh();
      } catch (e) {}
    }
  }

  void _loadOtpData() {
    if (mounted) {
      try {
        _otpProvider.loadEntries();
      } catch (e) {}
    }
  }

  @override
  void dispose() {
    _globalTickTimer?.cancel();
    _tickNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (_syncListener != null) {
      try {
        context.read<SyncProvider>().removeListener(_syncListener!);
      } catch (_) {}
      _syncListener = null;
    }
    _otpProvider.stopAutoRefresh();
    super.dispose();
  }

  void _copyCode(OtpEntry entry) {
    if (!mounted) return;
    try {
      final code = _otpService.generateTotp(
        secret: entry.secret,
        digits: entry.digits,
        period: entry.period,
        algorithm: entry.algorithm,
      );
      Clipboard.setData(ClipboardData(text: code));
      if (!mounted) return;
      try {
        ErrorSnackBar.showSuccess(context, 'Code copied'.i18n);
      } catch (e) {}
    } catch (e) {
      if (!mounted) return;
      try {
        ErrorSnackBar.show(context, 'Invalid secret key'.i18n);
      } catch (e) {}
    }
  }

  Future<void> _refreshFromServer() async {
    if (!mounted) return;
    try {
      await _otpProvider.loadEntries();
    } catch (e) {}
  }

  Future<void> _deleteEntry(OtpEntry entry) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AlertDialog(
          backgroundColor: Theme.of(context).cardColor.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
          title: Text('Delete OTP?'.i18n,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          content: Text(
            'Are you sure you want to delete "${entry.issuer.isNotEmpty ? entry.issuer : entry.name}"?',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context, false),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Cancel'.i18n),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Delete'.i18n),
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      final success = await _otpProvider.deleteOtpEntry(
        entry.id,
        serverId: entry.serverId,
      );
      if (!mounted) return;
      try {
        if (success) {
          ErrorSnackBar.showSuccess(context, 'OTP deleted'.i18n);
        } else {
          ErrorSnackBar.show(context, _otpProvider.errorMessage);
        }
      } catch (e) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: Theme.of(context).brightness == Brightness.dark
            ? Brightness.dark
            : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ListenableBuilder(
          listenable: Listenable.merge([_otpProvider, _tickNotifier]),
          builder: (context, _) {
            final otpProvider = _otpProvider;
            return Stack(
              children: [
                Container(color: Theme.of(context).scaffoldBackgroundColor),
                SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Row(
                          children: [
                            Icon(Icons.security,
                                color: Theme.of(context).colorScheme.primary, size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Authenticator'.i18n,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              decoration: BoxDecoration(
                                color: (Theme.of(context).brightness == Brightness.light
                                    ? const Color(0xFFF5F5F5)
                                    : const Color(0xFF2A2A2A)),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: TextField(
                                onChanged: (value) {
                                  otpProvider.setSearchQuery(value);
                                },
                                style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Search'.i18n,
                                  hintStyle: TextStyle(
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                      fontSize: 16),
                                  prefixIcon: Icon(Icons.search,
                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                                      size: 22),
                                  suffixIcon: otpProvider.searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.close,
                                              color: Theme.of(context).colorScheme.onSurface
                                                  .withValues(alpha: 0.6),
                                              size: 20),
                                          onPressed: () {
                                            otpProvider.clearSearch();
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: otpProvider.isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                    color: Theme.of(context).colorScheme.primary))
                            : otpProvider.filteredEntries.isEmpty
                                ? _buildEmptyState()
                                : RefreshIndicator(
                                    onRefresh: _refreshFromServer,
                                    color: Theme.of(context).colorScheme.primary,
                                    child: ListView.builder(
                                      padding: const EdgeInsets.fromLTRB(
                                          20, 0, 20, 150),
                                      itemCount:
                                          otpProvider.filteredEntries.length,
                                      itemBuilder: (context, index) => _OtpCard(
                                        entry:
                                            otpProvider.filteredEntries[index],
                                        onCopy: () => _copyCode(
                                            otpProvider.filteredEntries[index]),
                                        onDelete: () => _deleteEntry(
                                            otpProvider.filteredEntries[index]),
                                        tick: _tickNotifier.value,
                                      ),
                                    ),
                                  ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 130.0,
                  right: 16.0,
                  child: ExpandableActionButton(
                    onCreatePassword: () =>
                        GlobalActions.createPassword(context),
                    onCreateNote: () => GlobalActions.createNote(context),
                    onCreateOtp: () => GlobalActions.createOtp(context,
                        onSuccess: _refreshFromServer),
                    onCreateMessage: () => GlobalActions.createMessage(context),
                    onCreatePasskey: () =>
                        GlobalActions.createPasskey(context),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.security,
            size: 80,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'No OTP entries yet'.i18n,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first authenticator code'.i18n,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpCard extends StatelessWidget {
  final OtpEntry entry;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final int tick;

  const _OtpCard({
    required this.entry,
    required this.onCopy,
    required this.onDelete,
    required this.tick,
  });

  int get _remainingSeconds {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return entry.period - (now % entry.period);
  }

  double get _progress {
    return (entry.period - _remainingSeconds) / entry.period;
  }

  Color get _progressColor {
    if (_remainingSeconds > 10) {
      return Colors.green;
    } else if (_remainingSeconds > 5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String get _initial {
    final text = entry.issuer.isNotEmpty ? entry.issuer : entry.name;
    return text.isNotEmpty ? text.substring(0, 1).toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    String code;
    try {
      final service = OtpService();
      code = service.generateTotp(
        secret: entry.secret,
        digits: entry.digits,
        period: entry.period,
        algorithm: entry.algorithm,
      );
    } catch (_) {
      code = 'INVALID';
    }
    final isValid = code != 'INVALID';
    final formattedCode = isValid && code.length == 6
        ? '${code.substring(0, 3)} ${code.substring(3, 6)}'
        : code;

    if (!isValid) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color.fromRGBO(40, 30, 30, 1.0),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.error_outline, color: Colors.red, size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invalid OTP Entry'.i18n,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Secret key is corrupted'.i18n,
                      style: TextStyle(
                        color: Colors.red.withValues(alpha: 0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.red.withValues(alpha: 0.5),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: (Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : const Color(0xFF2A2A2A))
                .withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              _initial,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.issuer.isNotEmpty ? entry.issuer : entry.name,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (entry.issuer.isNotEmpty)
                                Text(
                                  entry.name,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            formattedCode,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                value: _progress,
                                strokeWidth: 3,
                                backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(_progressColor),
                              ),
                            ),
                            Text(
                              '$_remainingSeconds',
                              style: TextStyle(
                                color: _progressColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tap to copy'.i18n,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                            fontSize: 12,
                          ),
                        ),
                      ],
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
}
