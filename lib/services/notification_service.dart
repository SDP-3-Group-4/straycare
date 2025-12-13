import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'; // Explicit import if needed, but usually material covers it
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:googleapis_auth/auth_io.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Register Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Foreground Message Handler
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
          'Message also contained a notification: ${message.notification}',
        );
      }
    });

    // 4. Handle Message Opened App
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('A new onMessageOpenedApp event was published!');
    });

    // 5. Get and Print Token
    await getToken();
  }

  Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $token');
      if (token != null) {
        await _saveTokenToDatabase(token);
      }
      return token;
    } catch (e) {
      debugPrint('Error fetching FCM token: $e');
      return null;
    }
  }

  Future<void> _saveTokenToDatabase(String token) async {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'fcmToken': token,
      });
      debugPrint('FCM Token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
      try {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
      } catch (e2) {
        debugPrint('Error saving FCM token fallback: $e2');
      }
    }
  }

  // Handle initial message if app was terminated and opened via notification
  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage = await _firebaseMessaging
        .getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }
  }

  void _handleMessage(RemoteMessage message) {
    if (message.data['type'] == 'chat') {
      // Navigate to chat screen logic here
    }
  }

  // ---------------------------------------------------------------------------
  // Client-Side Notification Sending (Demo Use Only)
  // ---------------------------------------------------------------------------
  Future<void> sendNotification({
    required String recipientToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // 1. Load the Service Account Key from .env
      final String serviceAccountString =
          dotenv.env['GOOGLE_SERVICE_ACCOUNT_JSON'] ?? '';

      if (serviceAccountString.isEmpty) {
        debugPrint('Error: GOOGLE_SERVICE_ACCOUNT_JSON not found in .env');
        return;
      }

      final serviceAccountJson = jsonDecode(serviceAccountString);

      final credentials = ServiceAccountCredentials.fromJson(
        serviceAccountJson,
      );
      final projectId = serviceAccountJson['project_id'];

      // 2. Get Authenticated Client
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(credentials, scopes);

      // 3. Construct Message
      final url =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';

      final message = {
        'message': {
          'token': recipientToken,
          'notification': {'title': title, 'body': body},
          'data': data ?? {},
        },
      };

      // 4. Send Request
      final response = await client.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully!');
      } else {
        debugPrint('Failed to send notification: ${response.body}');
      }

      client.close();
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}
