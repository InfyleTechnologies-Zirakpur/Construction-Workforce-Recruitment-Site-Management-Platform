import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/models/models.dart';
import '../repositories/worker_repository.dart';

sealed class LoadState<T> {
  const LoadState();
}

class Idle<T> extends LoadState<T> {
  const Idle();
}

class Loading<T> extends LoadState<T> {
  const Loading();
}

class Loaded<T> extends LoadState<T> {
  const Loaded(this.data);
  final T data;
}

class Failed<T> extends LoadState<T> {
  const Failed(this.message);
  final String message;
}

class JobsCubit extends Cubit<LoadState<List<Job>>> {
  JobsCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  void reset() => emit(const Idle());
  Future<void> load([String? query]) async {
    emit(const Loading());
    try {
      emit(Loaded(await _repo.fetchJobs(query: query)));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> apply(String id, {Map<String, dynamic>? details}) async {
    await _repo.apply(id, details: details);
    await load();
  }

  Future<void> save(String id) async {
    await _repo.save(id);
    await load();
  }

  Future<void> withdraw(String applicationId, {String? jobId}) async {
    await _repo.withdrawApplication(applicationId, jobId: jobId);
    await load();
  }

  Future<void> report({required String jobId, required String reason}) async {
    await _repo.reportJob(jobId: jobId, reason: reason);
    // don't necessarily need to reload for a report, but we could.
  }
}

class ProfileCubit extends Cubit<LoadState<WorkerProfile>> {
  ProfileCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  void reset() => emit(const Idle());
  Future<void> load() async {
    emit(const Loading());
    try {
      emit(Loaded(await _repo.profile()));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> update(Map<String, dynamic> body) async {
    emit(const Loading());
    try {
      final updatedProfile = await _repo.updateProfile(body);
      try {
        const storage = FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        );
        if (updatedProfile.name.isNotEmpty) {
          await storage.write(key: 'companyName', value: updatedProfile.name);
          await storage.write(key: 'fullName', value: updatedProfile.name);
          await storage.write(key: 'name', value: updatedProfile.name);
        }
      } catch (_) {}
      emit(Loaded(updatedProfile));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }
  Future<String?> uploadPhoto({required List<int> bytes, required String filename}) async {
    try { return await _repo.uploadProfilePhoto(bytes: bytes, filename: filename); } catch (_) { return null; }
  }
  Future<Map<String, dynamic>?> uploadDocument({required List<int> bytes, required String filename, required String type}) async {
    try { return await _repo.uploadDocument(bytes: bytes, filename: filename, type: type); } catch (_) { return null; }
  }
}

class AttendanceCubit extends Cubit<LoadState<List<Attendance>>> {
  AttendanceCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  Future<void> load() async {
    emit(const Loading());
    try {
      emit(Loaded(await _repo.attendance()));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> checkIn() async {
    await _repo.checkIn();
    await load();
  }

  Future<void> checkOut() async {
    await _repo.checkOut();
    await load();
  }
}

class DashboardCubit extends Cubit<LoadState<Map<String, dynamic>>> {
  DashboardCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  void reset() => emit(const Idle());
  Future<void> load() async {
    emit(const Loading());
    try {
      emit(Loaded(await _repo.dashboard()));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }
}

class AuthCubit extends Cubit<LoadState<Map<String, dynamic>>> {
  AuthCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  Future<void> requestOtp(String phone) async {
    emit(const Loading());
    try {
      final res = await _repo.requestOtp(phone);
      // Forward backend flags (isNewUser) so OTP screen / login can use them.
      emit(Loaded(<String, dynamic>{'otpSent': true, ...res}));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    emit(const Loading());
    try {
      // Wipe any stale session from a previous number BEFORE storing the
      // new one — prevents old profile/jobs leaking into a fresh login.
      try {
        await const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
        ).deleteAll();
      } catch (_) {}
      final data = await _repo.verifyOtp(phone: phone, otp: otp);
      // Persist tokens for ApiClient
      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      if (data['accessToken'] != null) await storage.write(key: 'accessToken', value: data['accessToken'].toString());
      if (data['refreshToken'] != null) await storage.write(key: 'refreshToken', value: data['refreshToken'].toString());
      await storage.write(key: 'role', value: 'job_seeker');
      await storage.write(key: 'phone', value: phone);
      // Persist profile-completeness so splash / re-open routes correctly.
      final worker = data['worker'] ?? data['user'];
      bool? completeFlag;
      if (data['isProfileComplete'] is bool) {
        completeFlag = data['isProfileComplete'] as bool;
      } else if (data['isNewUser'] is bool) {
        completeFlag = !(data['isNewUser'] as bool);
      } else if (worker is Map && worker['isProfileComplete'] is bool) {
        completeFlag = worker['isProfileComplete'] as bool;
      } else if (worker is Map && worker['isNewUser'] is bool) {
        completeFlag = !(worker['isNewUser'] as bool);
      }
      if (completeFlag != null) {
        await storage.write(key: 'profileComplete', value: completeFlag.toString());
      }
      // Persist userId for conversation message ownership detection
      final user = data['worker'] ?? data['user'];
      if (user is Map && user['id'] != null) {
        await storage.write(key: 'userId', value: user['id'].toString());
      }
      emit(Loaded(data));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> logout({String? fcmToken}) async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    try {
      // Resolve FCM token + refresh token BEFORE wiping storage
      // so the backend can deactivate the device + invalidate session
      // (updates job_seeker / company presence state server-side).
      String? tokenToSend = fcmToken;
      if (tokenToSend == null || tokenToSend.isEmpty) {
        try {
          tokenToSend = await storage.read(key: 'fcmDeviceToken');
        } catch (_) {}
      }
      await _repo.logout(fcmToken: tokenToSend);
    } catch (_) {
      // Server logout is best-effort — still clear local session.
    }
    try {
      await storage.deleteAll();
    } catch (_) {}
    // Reset auth state so Login/Otp listeners don't react to stale Loaded.
    emit(const Idle());
  }

  /// Reset to idle without touching storage (e.g. after navigation).
  void reset() => emit(const Idle());
}

class MessagesCubit extends Cubit<LoadState<List<Conversation>>> {
  MessagesCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  void reset() => emit(const Idle());
  Future<void> load() async { emit(const Loading()); try { emit(Loaded(await _repo.conversations())); } catch (e) { emit(Failed(e.toString())); } }
  Future<void> send(String conversationId, String text) async { await _repo.sendMessage(conversationId, text); await load(); }
}

class NotificationsCubit extends Cubit<LoadState<List<WorkerNotification>>> {
  NotificationsCubit(this._repo) : super(const Idle());
  final WorkerRepository _repo;
  void reset() => emit(const Idle());
  Future<void> load() async {
    emit(const Loading());
    try {
      emit(Loaded(await _repo.notifications()));
    } catch (e) {
      emit(Failed(e.toString()));
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _repo.markNotificationRead(id);
    } catch (_) {}
    await load();
  }

  Future<void> markAllRead() async {
    try {
      await _repo.markAllNotificationsRead();
    } catch (_) {}
    await load();
  }
}

class FeedCubit extends Cubit<LoadState<List<FeedPost>>> {
  FeedCubit([WorkerRepository? repo])
      : _repo = repo ?? WorkerRepository(),
        super(const Idle()) {
    load();
  }

  final WorkerRepository _repo;

  List<FeedPost> _posts = [];

  Future<void> load({String? search, String? tag, bool refresh = false}) async {
    if (!refresh && state is! Loaded) {
      emit(const Loading());
    }

    try {
      final res = await _repo.fetchPosts(page: 1, limit: 50, search: search, tag: tag);
      final items = res['items'] as List<FeedPost>? ?? [];

      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final savedCompName = await storage.read(key: 'companyName');

      final enriched = items.map((p) {
        bool myPost = p.isMyPost;
        String effectiveName = p.authorName;

        // If company role and saved company name is known
        if (savedCompName != null && savedCompName.isNotEmpty) {
          if (effectiveName.isNotEmpty && effectiveName.trim().toLowerCase() == savedCompName.trim().toLowerCase()) {
            myPost = true;
          }
          if (myPost && (effectiveName.isEmpty || effectiveName == 'Verified Partner')) {
            effectiveName = savedCompName;
          }
        }

        if (effectiveName.isEmpty) {
          effectiveName = 'Verified Partner';
        }

        return p.copyWith(
          isMyPost: myPost,
          authorName: effectiveName,
        );
      }).toList();

      _posts = enriched;
      emit(Loaded(List.unmodifiable(_posts)));
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [FeedCubit] Network fetch failed: $e');
      if (_posts.isEmpty) {
        emit(Loaded(const []));
      } else {
        emit(Loaded(List.unmodifiable(_posts)));
      }
    }
  }

  Future<void> addPost({
    required String content,
    String? location,
    String? taggedTitle,
    String? authorName,
    String? authorRole,
  }) async {
    final title = (taggedTitle != null && taggedTitle.trim().isNotEmpty)
        ? taggedTitle.trim()
        : 'Site Report';

    try {
      final newPost = await _repo.createPost(
        title: title,
        description: content.trim(),
        location: location?.trim(),
        tags: taggedTitle != null ? [taggedTitle.trim()] : null,
      );
      final enrichedPost = newPost.copyWith(
        authorName: (authorName != null && authorName.trim().isNotEmpty)
            ? authorName.trim()
            : (newPost.authorName.isNotEmpty ? newPost.authorName : 'Company'),
        authorRole: (authorRole != null && authorRole.trim().isNotEmpty) ? authorRole.trim() : newPost.authorRole,
        isMyPost: true,
      );
      _posts.insert(0, enrichedPost);
      emit(Loaded(List.unmodifiable(_posts)));
      return;
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [FeedCubit] createPost API error: $e, adding locally');
    }

    final localPost = FeedPost(
      id: 'feed_${DateTime.now().millisecondsSinceEpoch}',
      authorName: (authorName != null && authorName.trim().isNotEmpty) ? authorName.trim() : 'Company',
      authorRole: (authorRole != null && authorRole.trim().isNotEmpty) ? authorRole.trim() : 'Hiring Employer',
      content: content.trim(),
      location: (location != null && location.trim().isNotEmpty) ? location.trim() : null,
      taggedTitle: (taggedTitle != null && taggedTitle.trim().isNotEmpty) ? taggedTitle.trim() : null,
      createdAt: DateTime.now(),
      isMyPost: true,
      likesCount: 0,
      commentsCount: 0,
      sharesCount: 0,
      isLiked: false,
      comments: const [],
    );

    _posts.insert(0, localPost);
    emit(Loaded(List.unmodifiable(_posts)));
  }

  Future<void> updatePost(String postId, {String? description, String? location, String? title}) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    try {
      final updated = await _repo.updatePost(postId, description: description, location: location, title: title);
      _posts[index] = updated;
      emit(Loaded(List.unmodifiable(_posts)));
      return;
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [FeedCubit] updatePost API error: $e');
    }

    // Local fallback update
    final current = _posts[index];
    _posts[index] = current.copyWith(
      content: description ?? current.content,
      location: location ?? current.location,
      taggedTitle: title ?? current.taggedTitle,
    );
    emit(Loaded(List.unmodifiable(_posts)));
  }

  Future<void> deletePost(String postId) async {
    _posts.removeWhere((p) => p.id == postId);
    emit(Loaded(List.unmodifiable(_posts)));

    try {
      await _repo.deletePost(postId);
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [FeedCubit] deletePost API error: $e');
    }
  }

  Future<void> toggleLike(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final current = _posts[index];
    final newIsLiked = !current.isLiked;
    final newCount = newIsLiked ? current.likesCount + 1 : (current.likesCount > 0 ? current.likesCount - 1 : 0);

    _posts[index] = current.copyWith(
      isLiked: newIsLiked,
      likesCount: newCount,
    );
    emit(Loaded(List.unmodifiable(_posts)));

    try {
      final res = await _repo.toggleLikePost(postId);
      _posts[index] = _posts[index].copyWith(
        isLiked: res['isLiked'] as bool? ?? newIsLiked,
        likesCount: res['likesCount'] as int? ?? newCount,
      );
      emit(Loaded(List.unmodifiable(_posts)));
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [FeedCubit] toggleLike API error: $e');
    }
  }

  Future<void> incrementShare(String postId) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final current = _posts[index];
    _posts[index] = current.copyWith(
      sharesCount: current.sharesCount + 1,
    );
    emit(Loaded(List.unmodifiable(_posts)));

    try {
      final newShares = await _repo.sharePost(postId);
      _posts[index] = _posts[index].copyWith(sharesCount: newShares);
      emit(Loaded(List.unmodifiable(_posts)));
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [FeedCubit] incrementShare API error: $e');
    }
  }

  Future<List<PostComment>> fetchComments(String postId) async {
    try {
      final res = await _repo.fetchComments(postId, page: 1, limit: 50);
      final items = res['items'] as List<PostComment>? ?? [];

      const storage = FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );
      final role = await storage.read(key: 'role');
      final savedCompName = await storage.read(key: 'companyName');
      final savedFullName = await storage.read(key: 'fullName');
      final savedName = await storage.read(key: 'name');
      final resolvedUser = (savedCompName?.isNotEmpty == true)
          ? savedCompName!
          : ((savedFullName?.isNotEmpty == true)
              ? savedFullName!
              : ((savedName?.isNotEmpty == true)
                  ? savedName!
                  : (role == 'company' ? 'Company' : 'Me')));

      final enriched = items.map((c) {
        String effectiveName = c.authorName;
        if (c.isMine || effectiveName.isEmpty || effectiveName == 'User Comment' || effectiveName == 'Verified User' || effectiveName == 'You' || effectiveName == 'Me') {
          if (c.isMine) {
            effectiveName = resolvedUser;
          } else if (effectiveName.isEmpty) {
            effectiveName = 'Verified User';
          }
        }
        return c.copyWith(authorName: effectiveName);
      }).toList();

      return enriched;
    } catch (e) {
      
      print('⚠️ [FeedCubit] fetchComments API error: $e');
      final index = _posts.indexWhere((p) => p.id == postId);
      if (index != -1) return _posts[index].comments;
      return [];
    }
  }

  Future<void> addComment(
    String postId, {
    required String text,
    String? parentCommentId,
    String? authorName,
    String? authorRole,
  }) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final currentPost = _posts[index];

    PostComment? networkComment;
    try {
      networkComment = await _repo.addComment(postId, text);
    } catch (e) {
      // ignore: avoid_print
      print('⚠️ [FeedCubit] addComment API error: $e');
    }

    final finalAuthorName = (authorName != null && authorName.trim().isNotEmpty)
        ? authorName.trim()
        : (networkComment?.authorName.isNotEmpty == true ? networkComment!.authorName : 'Company');

    final newComment = (networkComment ??
        PostComment(
          id: 'c_${DateTime.now().millisecondsSinceEpoch}',
          authorName: finalAuthorName,
          authorRole: (authorRole != null && authorRole.trim().isNotEmpty) ? authorRole.trim() : 'Hiring Employer',
          text: text.trim(),
          createdAt: DateTime.now(),
          isMine: true,
          replies: const [],
        )).copyWith(
          authorName: finalAuthorName,
          isMine: true,
        );

    final updatedComments = List<PostComment>.from(currentPost.comments);

    if (parentCommentId == null) {
      updatedComments.add(newComment);
    } else {
      final parentIdx = updatedComments.indexWhere((c) => c.id == parentCommentId);
      if (parentIdx != -1) {
        final parent = updatedComments[parentIdx];
        final updatedReplies = List<PostComment>.from(parent.replies)..add(newComment);
        updatedComments[parentIdx] = parent.copyWith(replies: updatedReplies);
      } else {
        updatedComments.add(newComment);
      }
    }

    _posts[index] = currentPost.copyWith(
      comments: updatedComments,
      commentsCount: currentPost.commentsCount + 1,
    );

    emit(Loaded(List.unmodifiable(_posts)));
  }
}


