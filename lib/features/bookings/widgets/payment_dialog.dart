import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void showPaymentDialog(
  BuildContext context,
  DocumentReference bookingRef,
  double currentPaid,
  double grandTotal,
) {
  TextEditingController controller = TextEditingController();
  bool isSavingPayment = false;

  showDialog(
    context: context,
    builder: (_) {
  return StatefulBuilder(
    builder: (context, setState) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text(AppLocalizations.of(context)!.enterPaymentAmount),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.paymentAmount,
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1E4FA3),
            ),
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF1E4FA3),
            ),
            child: isSavingPayment
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(AppLocalizations.of(context)!.save),
            onPressed: isSavingPayment
                ? null
                : () async {
                    if (isSavingPayment) return;

                    setState(() {
                      isSavingPayment = true;
                    });
                    double amount = double.tryParse(controller.text) ?? 0;

                    double remaining = grandTotal - currentPaid;

                    if (amount > remaining) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content:
                              Text(AppLocalizations.of(context)!.paymentExceed),
                        ),
                      );
                      return;
                    }

                    double newTotalPaid = currentPaid + amount;

                    if (amount > remaining) {
                      bool confirm = await showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: Colors.white,
                              title: Text(
                                  AppLocalizations.of(context)!.advanceExceed),
                              content: Text(
                                  AppLocalizations.of(context)!.advanceConfirm),
                              actions: [
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E4FA3),
                                  ),
                                  child: Text(
                                      AppLocalizations.of(context)!.cancel),
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E4FA3),
                                  ),
                                  child: Text(
                                      AppLocalizations.of(context)!.confirm),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                          ) ??
                          false;

                      if (!confirm) return;
                    }

                    await bookingRef.update({
                      "totalPaid": newTotalPaid,
                    });

                    await bookingRef.collection("payments").add({
                      "amount": amount,
                      "type": "payment",
                      "timestamp": Timestamp.now(),
                    });

                    Navigator.pop(context);

                    setState(() {
                      isSavingPayment = false;
                    });
                  },
          ),
        ],
      );
    },
  );
    }
  );
}
