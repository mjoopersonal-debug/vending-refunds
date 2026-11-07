import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'main.dart' show pink;

class RefundListScreen extends StatelessWidget {
  final String status;
  const RefundListScreen({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isPending = status == 'Pending';
    return Scaffold(
      appBar: AppBar(
        title: Text(isPending ? 'Pending Refunds' : 'Done Refunds'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('refunds')
            .where('status', isEqualTo: status)
            .orderBy('time', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error: ${snap.error}', textAlign: TextAlign.center),
            ));
          }
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snap.data!.docs;
          if (docs.isEmpty) {
            return Center(child: Text('No $status refunds', style: const TextStyle(color: pink, fontSize: 16)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final doc = docs[i];
              final d = doc.data() as Map<String, dynamic>;
              final phone = (d['phone'] ?? '').toString();
              final upi = (d['upiId'] ?? '').toString();
              final issue = (d['issue'] ?? '').toString();
              final time = d['time'] is Timestamp
                  ? (d['time'] as Timestamp).toDate().toLocal().toString().substring(0, 16)
                  : '';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(phone, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('UPI: $upi', style: const TextStyle(color: Colors.black87)),
                      Text('Issue: $issue', style: const TextStyle(color: Colors.black87)),
                      Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      if (isPending) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: Colors.green),
                              onPressed: () => _openWhatsApp(phone, upi),
                              child: const Text('WhatsApp'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: () => _markDone(doc.reference),
                              child: const Text('Mark Done'),
                            ),
                          ),
                        ]),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

Future<void> _openWhatsApp(String phone, String upi) async {
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 10) digits = '91$digits';
  final msg = Uri.encodeComponent(
      'Hi, this is Softies Vending about your refund. We are processing it to UPI ID $upi.');
  await launchUrl(Uri.parse('https://wa.me/$digits?text=$msg'),
      mode: LaunchMode.externalApplication);
}

Future<void> _markDone(DocumentReference ref) async {
  await ref.update({'status': 'Done'});
}
