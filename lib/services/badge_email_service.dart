import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import '../features/home/models/user_model.dart';
import '../features/home/models/badges_model.dart';

class BadgeEmailService {
  /// Analyzes user progress against available badges and triggers rewards
  static Future<void> checkAndSendBadge(UserModel user, List<BadgesModel> allBadges) async {
    for (var badge in allBadges) {
      // 1. Skip if the user has already earned this specific badge
      if (user.earnedBadges.contains(badge.title)) continue;

      // 2. Extract requirements from the badge model
      final req = badge.requirement;
      final String category = req['category'] ?? '';
      final int requiredValue = req['value'] ?? 0;
      
      // 3. Compare requirement against user's lifetime category counts
      int userValue = user.categoryCounts[category] ?? 0;

      if (userValue >= requiredValue) {
        debugPrint("🏆 Milestone Met: ${badge.title}. Sending Certificate...");

        // 4. Trigger the professional certificate email (Async/Background)
        _sendCertificateEmail(user.email, user.username, badge);
        
        // 5. Update Firestore: Add to earned list and award bonus points
        try {
          await FirebaseFirestore.instance.collection('users').doc(user.id).update({
            'earnedBadges': FieldValue.arrayUnion([badge.title]),
            'ecoPoints': FieldValue.increment(badge.pointReward),
          });
        } catch (e) {
          debugPrint("❌ Failed to update badge status in Firestore: $e");
        }
      }
    }
  }

  /// Sends a professionally formatted HTML "Digital Certificate" email
  static Future<void> _sendCertificateEmail(String email, String name, BadgesModel badge) async {
    // Ensure .env variables are present before proceeding
    final String? smtpUser = dotenv.env['MAIL_USERNAME'];
    final String? smtpPass = dotenv.env['MAIL_PASSWORD'];

    if (smtpUser == null || smtpPass == null) {
      debugPrint("❌ SMTP Error: Missing MAIL_USERNAME or MAIL_PASSWORD in .env");
      return;
    }

    final smtpServer = gmail(smtpUser, smtpPass);

    final message = Message()
      ..from = Address(smtpUser, 'EcoScan Impact Team')
      ..recipients.add(email)
      ..subject = '🏆 Achievement Unlocked: ${badge.title} Certificate'
      ..html = '''
        <!DOCTYPE html>
        <html>
        <body style="margin: 0; padding: 20px; background-color: #F4F9F5; font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;">
          <div style="max-width: 600px; margin: 0 auto; background-color: #ffffff; border: 8px double #1B5E20; padding: 40px; text-align: center; border-radius: 10px;">
            
            <div style="margin-bottom: 20px;">
              <p style="text-transform: uppercase; letter-spacing: 5px; color: #1B5E20; font-weight: bold; margin: 0;">Certificate of Achievement</p>
              <div style="width: 50px; height: 2px; background-color: #4CAF50; margin: 15px auto;"></div>
            </div>

            <p style="font-size: 18px; color: #555; font-style: italic;">This is to certify that</p>
            
            <h1 style="font-size: 32px; color: #1B5E20; margin: 10px 0; border-bottom: 1px solid #eee; display: inline-block; padding-bottom: 5px;">$name</h1>
            
            <p style="font-size: 18px; color: #555; margin-top: 10px;">has successfully unlocked the prestigious badge</p>

            <div style="margin: 30px 0;">
              <img src="${badge.iconUrl}" width="140" height="140" alt="Badge Icon" style="border-radius: 50%; border: 4px solid #F4F9F5; box-shadow: 0 4px 15px rgba(0,0,0,0.1);">
            </div>

            <h2 style="font-size: 26px; color: #333; margin: 0;">${badge.title}</h2>
            <p style="font-size: 16px; color: #666; max-width: 400px; margin: 10px auto 20px auto; line-height: 1.5;">${badge.description}</p>

            <div style="background-color: #F4F9F5; padding: 20px; border-radius: 8px; margin-top: 30px;">
              <p style="margin: 0; font-size: 14px; color: #1B5E20; font-weight: bold;">EARNED REWARD</p>
              <p style="margin: 5px 0 0 0; font-size: 24px; color: #4CAF50; font-weight: bold;">+${badge.pointReward} EcoPoints</p>
            </div>

            <p style="margin-top: 40px; font-size: 12px; color: #999;">Issued by EcoScan Sustainability Platform • ${DateTime.now().year}</p>
          </div>
        </body>
        </html>
      ''';

    try {
      // Fire and forget: We don't await the actual SMTP send to keep UI snappy
      send(message, smtpServer);
    } catch (e) {
      debugPrint("❌ SMTP Send Error: $e");
    }
  }
}