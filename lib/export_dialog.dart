import 'package:flutter/material.dart';

class ExportBottomSheet extends StatelessWidget {
  final Future<void> Function() onPDF;
  final Future<void> Function() onCSV;
  final Future<void> Function() onShareText;

  const ExportBottomSheet({
    super.key,
    required this.onPDF,
    required this.onCSV,
    required this.onShareText,
  });

  static Future<void> show(
    BuildContext context, {
    required Future<void> Function() onPDF,
    required Future<void> Function() onCSV,
    required Future<void> Function() onShareText,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => ExportBottomSheet(
          onPDF: onPDF, onCSV: onCSV, onShareText: onShareText),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text('Export Report',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            _tile(
              context,
              icon: Icons.picture_as_pdf,
              color: Colors.red,
              title: 'Download as PDF',
              subtitle: 'Professional formatted report',
              onTap: () {
                Navigator.pop(context);
                onPDF();
              },
            ),
            const Divider(height: 1),
            _tile(
              context,
              icon: Icons.table_chart,
              color: Colors.green,
              title: 'Download as CSV',
              subtitle: 'Open in Excel / Google Sheets',
              onTap: () {
                Navigator.pop(context);
                onCSV();
              },
            ),
            const Divider(height: 1),
            _tile(
              context,
              icon: Icons.share,
              color: Colors.blue,
              title: 'Share Summary',
              subtitle: 'WhatsApp, Email, Social Media…',
              onTap: () {
                Navigator.pop(context);
                onShareText();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context,
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
          backgroundColor: color.withOpacity(.12),
          child: Icon(icon, color: color)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
