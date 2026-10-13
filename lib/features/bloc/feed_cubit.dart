import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/models/models.dart';
import '../repositories/worker_repository.dart';
import 'worker_blocs.dart';

class FeedCubit extends Cubit<LoadState<List<FeedPost>>> {
  FeedCubit([WorkerRepository? repo])
      : _repo = repo ?? WorkerRepository(),
        super(const Idle()) {
    load();
  }

  final WorkerRepository _repo;

  List<FeedPost> _posts = [];

  Future<void> load({String? search, String? tag, bool refresh = false}) async {
    if (!refresh && (state is! Loaded || _posts.isEmpty)) {
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
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      authorName: (authorName != null && authorName.trim().isNotEmpty) ? authorName.trim() : 'Company',
      authorRole: (authorRole != null && authorRole.trim().isNotEmpty) ? authorRole.trim() : 'Verified General Contractor',
      content: content.trim(),
      location: location?.trim(),
      taggedTitle: taggedTitle?.trim(),
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

  Future<void> editPost(
    String postId, {
    String? description,
    String? location,
    String? title,
  }) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final current = _posts[index];
    _posts[index] = current.copyWith(
      content: description ?? current.content,
      location: location ?? current.location,
      taggedTitle: title ?? current.taggedTitle,
    );
    emit(Loaded(List.unmodifiable(_posts)));
  }

  Future<void> updatePost(
    String postId, {
    String? description,
    String? location,
    String? title,
  }) =>
      editPost(postId, description: description, location: location, title: title);


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
      // ignore: avoid_print
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
