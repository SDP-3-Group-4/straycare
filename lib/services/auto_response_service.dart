import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:straycare_demo/features/create_post/repositories/post_repository.dart';
import 'package:straycare_demo/features/notifications/repositories/notification_repository.dart';
import 'package:straycare_demo/services/ai_service.dart';

class AutoResponseService {
  final PostRepository _postRepository;
  final AIService _aiService;
  final NotificationRepository _notificationRepository;
  static bool _hasRun = false;

  AutoResponseService({
    PostRepository? postRepository,
    AIService? aiService,
    NotificationRepository? notificationRepository,
  }) : _postRepository = postRepository ?? PostRepository(),
       _aiService = aiService ?? AIService(),
       _notificationRepository =
           notificationRepository ?? NotificationRepository();

  Future<void> checkAndRespondToRescuePosts() async {
    // Wait for network/auth to settle on startup
    await Future.delayed(const Duration(seconds: 5));

    // Only run once per session to avoid spamming/loops
    // if (_hasRun) return;
    // _hasRun = true;

    // Use SharedPreferences to limit checking frequency (e.g. once every 10 mins)
    final prefs = await SharedPreferences.getInstance();
    final lastRun = prefs.getInt('last_ai_check_timestamp') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    // 10 minutes debounce
    // if (now - lastRun < 1000 * 60 * 10) {
    //   print('AutoResponseService: Skipping check (debounced)');
    //   return;
    // }
    await prefs.setInt('last_ai_check_timestamp', now);

    print('AutoResponseService: Checking for rescue posts...');

    try {
      final timeThreshold = DateTime.now().subtract(const Duration(hours: 2));

      print('AutoResponseService: Querying posts older than $timeThreshold');

      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where(
            'category',
            isEqualTo: 'Rescue',
          ) // Matches User Requirement (Capitalized)
          .where('commentsCount', isEqualTo: 0)
          .where('createdAt', isLessThan: Timestamp.fromDate(timeThreshold))
          .limit(3)
          .get();

      print(
        'AutoResponseService: Found ${snapshot.docs.length} candidate posts.',
      );

      if (snapshot.docs.isEmpty) {
        print('AutoResponseService: No matching posts found.');
        return;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data();

        // Skip if already processed or skipped
        final status = data['aiResponseStatus'] as String? ?? 'pending';
        if (status != 'pending') {
          print(
            'AutoResponseService: Skipping post ${doc.id} because status is "$status"',
          );
          continue;
        }

        final postId = doc.id;
        final content = data['content'] as String? ?? '';

        if (content.isEmpty) {
          await _postRepository.updateAiStatus(postId, 'skipped');
          continue;
        }

        print('AutoResponseService: Analyzing post $postId...');
        print(
          'AutoResponseService: Sending content to AI: "${content.length > 50 ? content.substring(0, 50) + '...' : content}"',
        ); // Log snippet

        // Ask AI
        final aiAdvice = await _aiService.getRescuePostAdvice(content);
        print(
          'AutoResponseService: AI Response Raw: "$aiAdvice"',
        ); // Log EXACT response

        if (aiAdvice == 'NO_RESPONSE' || aiAdvice.isEmpty) {
          print('AutoResponseService: AI decided NOT to respond.');
          await _postRepository.updateAiStatus(postId, 'skipped');
        } else {
          print('AutoResponseService: Posting AI comment: "$aiAdvice"');

          final disclaimer =
              "\n\n**Disclaimer**: I am an experimental AI bot. This advice is not a substitute for professional veterinary care. Please consult a vet immediately for emergencies.";
          final finalComment = aiAdvice + disclaimer;

          // Post comment
          await _postRepository.addComment(postId, {
            'content': finalComment,
            'userId':
                'ai_vet_bot_system_user', // Changed from authorId to userId to match CommentBottomSheet expectation if needed, though repo likely handles it. Let's stick to consistent keys.
            'userName':
                'StrayCare AI Vet', // FIXED: 'authorName' -> 'userName' to match reader
            'userAvatarUrl':
                'assets/images/botx.jpg', // Changed key to 'userAvatarUrl'
            'isSystemComment': true,
          });

          // Send notification to the post author
          try {
            final authorId = data['authorId'];
            if (authorId != null) {
              await _notificationRepository.sendNotification(
                toUserId: authorId,
                fromUserId: 'ai_vet_bot_system_user',
                type: 'comment',
                message: 'shared advice on your rescue post',
                relatedId: doc.id,
              );
              print('Notification sent to author ($authorId).');
            }
          } catch (e) {
            print('Error sending bot notification: $e');
          }

          // Mark processed
          await _postRepository.updateAiStatus(postId, 'processed');
        }
      }
    } catch (e) {
      final errorStr = e.toString();
      print('AutoResponseService Error: $errorStr');

      if (errorStr.contains('failed-precondition')) {
        print('---------------------------------------------------');
        print('CRITICAL FIRESTORE ERROR: MISSING INDEX');
        print(
          'Please check the logs above for a URL starting with https://console.firebase.google.com/...',
        );
        print('Click that link to create the required composite index.');
        print('---------------------------------------------------');
      } else if (errorStr.contains('GaiException') ||
          errorStr.contains('UnknownHostException')) {
        print('---------------------------------------------------');
        print('CRITICAL NETWORK ERROR: EMULATOR HAS NO INTERNET');
        print('Firestore cannot be reached. Auto-Response will retry later.');
        print('---------------------------------------------------');
      }
    }
  }
}
