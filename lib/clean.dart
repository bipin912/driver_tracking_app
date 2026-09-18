// cleanup_script.dart (run via Cloud Function or admin tool)
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> cleanupUsersCollection() async {
  final users = await FirebaseFirestore.instance.collection('users').get();

  final batch = FirebaseFirestore.instance.batch();
  int cleaned = 0;

  for (var doc in users.docs) {
    final data = doc.data();
    final updates = <String, FieldValue>{};

    // Delete fullName if it exists
    if (data.containsKey('fullName')) {
      updates['fullName'] = FieldValue.delete();
    }

    // Optional: Delete display_name if you're standardizing on displayName
    // if (data.containsKey('display_name') && data.containsKey('displayName')) {
    //   updates['display_name'] = FieldValue.delete();
    // }

    if (updates.isNotEmpty) {
      batch.update(doc.reference, updates);
      cleaned++;
    }
  }

  if (cleaned > 0) {
    await batch.commit();
    print('🧹 Cleaned $cleaned user documents');
  }
}