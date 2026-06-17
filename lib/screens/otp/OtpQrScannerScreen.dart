import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:thisjowi/core/providers/otp_provider.dart';
import 'package:thisjowi/i18n/translations.dart';
import 'package:thisjowi/components/error_bar.dart';

class OtpQrScannerScreen extends StatefulWidget {
  const OtpQrScannerScreen({super.key});

  @override
  State<OtpQrScannerScreen> createState() => _OtpQrScannerScreenState();
}

class _OtpQrScannerScreenState extends State<OtpQrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _processCode(String code) async {
    if (scanned) return;
    setState(() {
      scanned = true;
    });
    
    if (code.startsWith('otpauth://')) {
      final success = await context.read<OtpProvider>().addOtpFromUri(code);
      if (mounted) {
        if (success) {
          ErrorSnackBar.showSuccess(context, 'OTP added'.i18n);
          Navigator.pop(context, true);
        } else {
          ErrorSnackBar.show(	context, context.read<OtpProvider>().errorMessage);
          Navigator.pop(context, false);
        }
      }
    } else {
      if (mounted) {
        ErrorSnackBar.show(context, 'Invalid QR'.i18n);
        Navigator.pop(context, false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (BarcodeCapture capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processCode(barcode.rawValue!);
                  return;
                }
              }
            },
            errorBuilder: (context, error) {
              return Center(
                child: Text(
                  "Error: %s".i18n.fill([error.errorCode.toString()]),
                  style: const TextStyle(color: Colors.white),
                ),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      IconButton(
                        icon: ValueListenableBuilder(
                          valueListenable: _controller,
                          builder: (context, state, child) {
                            switch (state.torchState) {
                              case TorchState.off:
                                return const Icon(Icons.flash_off, color: Colors.grey);
                              case TorchState.on:
                                return const Icon(Icons.flash_on, color: Colors.yellow);
                              default:
                                return const Icon(Icons.flash_off, color: Colors.grey);
                            }
                          },
                        ),
                        onPressed: () => _controller.toggleTorch(),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  "Scan QR Code".i18n,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
