import '../../core/api/api_client.dart';
import '../../core/models/models.dart';

mixin WorkerFeedRepositoryMixin {
  ApiClient get client;
  Future<String?> getCurrentUserId();

  Future<Map<String, dynamic>> fetchPosts({
    int page = 1,
    int limit = 10,
    String? search,
    String? tag,
    String? authorId,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
      if (tag != null && tag.trim().isNotEmpty) 'tag': tag.trim(),
      if (authorId != null && authorId.trim().isNotEmpty) 'authorId': authorId.trim(),
    };

    final response = await client.dio.get('/posts', queryParameters: queryParams);
    final payload = response.data;
    List rawItems = [];
    int total = 0;
    int totalPages = 1;

    if (payload is Map) {
      final data = payload['data'];
      if (data is Map) {
        if (data['items'] is List) rawItems = data['items'];
        total = (data['total'] as num?)?.toInt() ?? rawItems.length;
        totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
      } else if (data is List) {
        rawItems = data;
      } else if (payload['items'] is List) {
        rawItems = payload['items'];
      }
    }

    final currentUserId = await getCurrentUserId();
    final posts = rawItems
        .whereType<Map>()
        .map((item) => FeedPost.fromJson(Map<String, dynamic>.from(item), currentUserId: currentUserId))
        .toList();

    return {
      'items': posts,
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
    };
  }

  /// 2. Get Post Detail (GET /posts/:id)
  Future<FeedPost> getPostDetail(String id) async {
    final response = await client.dio.get('/posts/$id');
    final payload = response.data;
    final data = payload is Map ? (payload['data'] ?? payload) : payload;
    final currentUserId = await getCurrentUserId();
    return FeedPost.fromJson(Map<String, dynamic>.from(data), currentUserId: currentUserId);
  }

  /// 3. Create Post (POST /posts)
  Future<FeedPost> createPost({
    required String title,
    required String description,
    String? location,
    List<String>? tags,
    List<String>? photos,
    String? coverPhoto,
    double? latitude,
    double? longitude,
    String visibility = 'PUBLIC',
  }) async {
    final body = <String, dynamic>{
      'title': title,
      'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
      if (tags != null && tags.isNotEmpty) 'tags': tags,
      if (photos != null && photos.isNotEmpty) 'photos': photos,
      if (coverPhoto != null && coverPhoto.isNotEmpty) 'coverPhoto': coverPhoto,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'visibility': visibility,
    };

    final response = await client.dio.post('/posts', data: body);
    final payload = response.data;
    final data = payload is Map ? (payload['data'] ?? payload) : payload;
    return FeedPost.fromJson(Map<String, dynamic>.from(data));
  }

  /// 4. Update Post (PATCH /posts/:id)
  Future<FeedPost> updatePost(String id, {String? description, String? location, String? title}) async {
    final body = <String, dynamic>{
      if (title != null && title.isNotEmpty) 'title': title,
      if (description != null && description.isNotEmpty) 'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
    };

    final response = await client.dio.patch('/posts/$id', data: body);
    final payload = response.data;
    final data = payload is Map ? (payload['data'] ?? payload) : payload;
    return FeedPost.fromJson(Map<String, dynamic>.from(data));
  }

  /// 5. Delete Post (Soft Delete) (DELETE /posts/:id)
  Future<void> deletePost(String id) async {
    await client.dio.delete('/posts/$id');
  }

  /// 6. Toggle Like Post (POST /posts/:id/like)
  Future<Map<String, dynamic>> toggleLikePost(String id) async {
    final response = await client.dio.post('/posts/$id/like');
    final payload = response.data;
    final data = payload is Map ? (payload['data'] ?? payload) : payload;
    return {
      'isLiked': data['isLiked'] == true,
      'likesCount': (data['likesCount'] as num?)?.toInt() ?? 0,
    };
  }

  /// 7. Share Post (POST /posts/:id/share)
  Future<int> sharePost(String id) async {
    final response = await client.dio.post('/posts/$id/share');
    final payload = response.data;
    final data = payload is Map ? (payload['data'] ?? payload) : payload;
    return (data['sharesCount'] as num?)?.toInt() ?? 0;
  }

  /// 8. Add Comment to Post (POST /posts/:id/comments)
  Future<PostComment> addComment(String postId, String content) async {
    final response = await client.dio.post('/posts/$postId/comments', data: {'content': content});
    final payload = response.data;
    final data = payload is Map ? (payload['data'] ?? payload) : payload;
    final currentUserId = await getCurrentUserId();
    return PostComment.fromJson(Map<String, dynamic>.from(data), currentUserId: currentUserId);
  }

  /// 9. List Comments for Post (GET /posts/:id/comments)
  Future<Map<String, dynamic>> fetchComments(String postId, {int page = 1, int limit = 10}) async {
    final response = await client.dio.get('/posts/$postId/comments', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final payload = response.data;
    List rawItems = [];
    int total = 0;
    int totalPages = 1;

    if (payload is Map) {
      final data = payload['data'];
      if (data is Map) {
        if (data['items'] is List) rawItems = data['items'];
        total = (data['total'] as num?)?.toInt() ?? rawItems.length;
        totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;
      } else if (data is List) {
        rawItems = data;
      } else if (payload['items'] is List) {
        rawItems = payload['items'];
      }
    }

    final currentUserId = await getCurrentUserId();
    final comments = rawItems
        .whereType<Map>()
        .map((item) => PostComment.fromJson(Map<String, dynamic>.from(item), currentUserId: currentUserId))
        .toList();

    return {
      'items': comments,
      'total': total,
      'page': page,
      'limit': limit,
      'totalPages': totalPages,
    };
  }
}
