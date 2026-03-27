import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/bookings/screens/business_profile_screen.dart';
import '../config/app_config.dart';
import '../widgets/qr_inventory_dialog.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../main.dart'; // adjust path if needed

class AppMenu extends StatelessWidget {
  const AppMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: Colors.white,
      icon: const Icon(Icons.more_vert, color: Colors.white),
      onSelected: (value) async {
        if (value == "qr") {
          String businessId = await getBusinessId();

          /// 🔥 IMPORTANT: CHANGE THIS DOMAIN LATER
          String url =
              "https://inventory-web-gte4.onrender.com/?id=" + businessId;

          showDialog(
            context: context,
            builder: (_) => QRInventoryDialog(url: url),
          );
        }
        if (value == "profile") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const BusinessProfileScreen(),
            ),
          );
        }

        if (value == "logout") {
          await FirebaseAuth.instance.signOut();
        }

        if (value == "language") {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.white,
              title: const Text("Select Language"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text("English"),
                    onTap: () {
                      MyApp.setLocale(context, const Locale('en'));
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text("हिंदी"),
                    onTap: () {
                      MyApp.setLocale(context, const Locale('hi'));
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          );
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: "qr",
          child: Text(AppLocalizations.of(context)!.generateQr),
        ),
        PopupMenuItem(
          value: "profile",
          child: Text(AppLocalizations.of(context)!.businessProfile),
        ),
        PopupMenuItem(
          value: "logout",
          child: Text(AppLocalizations.of(context)!.logout),
        ),
        PopupMenuItem(
          value: "language",
          child: Text(AppLocalizations.of(context)!.language),
        ),
      ],
    );
  }
}
