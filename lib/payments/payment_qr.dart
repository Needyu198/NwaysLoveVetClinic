import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

bool isDemoPaymentQr(String payload, String providerMode) =>
    providerMode == 'development_payload' || payload.startsWith('MMQR|');

/// This temporary KBZPay QR is amount-specific; replace it with a dynamic
/// merchant QR when the clinic's real payment integration is available.
const temporaryPersonalPaymentQrAsset =
    'assets/payments/kbzpay_temporary_qr_50000.png';
const temporaryPersonalPaymentQrAmount = 50000;

class PaymentQr extends StatefulWidget {
  const PaymentQr({
    super.key,
    required this.imageDataUrl,
    required this.expiresAt,
    this.personalRecipient,
    this.useTemporaryImage = false,
    required this.amount,
  });

  final String imageDataUrl;
  final DateTime expiresAt;
  final String? personalRecipient;
  final bool useTemporaryImage;
  final int amount;

  @override
  State<PaymentQr> createState() => _PaymentQrState();
}

class _PaymentQrState extends State<PaymentQr> {
  Timer? _expiry;
  Uint8List? _image;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(PaymentQr oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageDataUrl != widget.imageDataUrl ||
        oldWidget.expiresAt != widget.expiresAt) {
      _load();
    }
  }

  void _load() {
    _expiry?.cancel();
    final remaining = widget.expiresAt.difference(DateTime.now());
    if (remaining > Duration.zero) {
      _expiry = Timer(remaining, () => setState(() {}));
    }
    const prefix = 'data:image/png;base64,';
    _image = null;
    if (widget.imageDataUrl.startsWith(prefix)) {
      try {
        _image = base64Decode(widget.imageDataUrl.substring(prefix.length));
      } on FormatException {
        // Show the same unavailable state as a missing image.
      }
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.expiresAt.isAfter(DateTime.now())) {
      return const Text('This payment QR has expired.');
    }
    const unavailable = Text('Payment QR unavailable. Refresh the payment.');
    final showTemporaryImage = widget.useTemporaryImage;
    if (!showTemporaryImage && _image == null) return unavailable;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTemporaryImage)
          Image.asset(
            temporaryPersonalPaymentQrAsset,
            width: 260,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            semanticLabel: 'Temporary KBZPay payment QR',
            errorBuilder: (context, error, stackTrace) => unavailable,
          )
        else
          Image.memory(
            _image!,
            width: 240,
            height: 240,
            filterQuality: FilterQuality.none,
            semanticLabel: 'Invoice payment QR',
            errorBuilder: (context, error, stackTrace) => unavailable,
          ),
        if (widget.personalRecipient != null)
          if (widget.useTemporaryImage)
            Text(
              'Scan with KBZPay and verify the recipient and the ${widget.amount} MMK amount before confirming.',
              textAlign: TextAlign.center,
            )
          else
            Text(
              'Scan with KBZPay, check the recipient ${widget.personalRecipient}, '
              'and enter ${widget.amount} MMK. Keep the transfer receipt for the clinic.',
              textAlign: TextAlign.center,
            )
        else if (widget.useTemporaryImage)
          Text(
            'Temporary KBZPay QR. Verify the recipient and confirm the amount is ${widget.amount} MMK before paying.',
            textAlign: TextAlign.center,
          )
        else
          const Text(
            'Scan with KBZPay and check the amount before confirming.',
          ),
      ],
    );
  }
}
