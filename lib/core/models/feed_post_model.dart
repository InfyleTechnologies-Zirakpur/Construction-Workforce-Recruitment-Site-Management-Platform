class PostComment {
  const PostComment({
    required this.id,
    required this.authorName,
    required this.authorRole,
    this.authorAvatarUrl,
    required this.text,
    required this.createdAt,
    this.isMine = false,
    this.replies = const [],
  });

  final String id;
  final String authorName;
  final String authorRole;
  final String? authorAvatarUrl;
  final String text;
  final DateTime createdAt;
  final bool isMine;
  final List<PostComment> replies;

  PostComment copyWith({
    String? id,
    String? authorName,
    String? authorRole,
    String? authorAvatarUrl,
    String? text,
    DateTime? createdAt,
    bool? isMine,
    List<PostComment>? replies,
  }) {
    return PostComment(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      isMine: isMine ?? this.isMine,
      replies: replies ?? this.replies,
    );
  }

  factory PostComment.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final authorObj = json['author'] is Map ? Map<String, dynamic>.from(json['author']) : null;
    final companyObj = json['company'] is Map ? Map<String, dynamic>.from(json['company']) : null;
    final userObj = json['user'] is Map ? Map<String, dynamic>.from(json['user']) : null;

    final authorId = authorObj?['id']?.toString() ??
        companyObj?['id']?.toString() ??
        userObj?['id']?.toString() ??
        json['authorId']?.toString();

    final bool isMine = json['isMine'] == true ||
        (currentUserId != null &&
            currentUserId.isNotEmpty &&
            authorId != null &&
            authorId.toLowerCase() == currentUserId.toLowerCase());

    final rawAuthorName = authorObj?['companyName']?.toString() ??
        authorObj?['name']?.toString() ??
        authorObj?['fullName']?.toString() ??
        authorObj?['businessName']?.toString() ??
        companyObj?['companyName']?.toString() ??
        companyObj?['name']?.toString() ??
        userObj?['companyName']?.toString() ??
        userObj?['name']?.toString() ??
        userObj?['fullName']?.toString() ??
        json['companyName']?.toString() ??
        json['authorName']?.toString() ??
        '';

    final authorName = rawAuthorName.isNotEmpty ? rawAuthorName : (isMine ? '' : 'Verified User');

    final authorRole = authorObj?['role']?.toString() ??
        companyObj?['role']?.toString() ??
        userObj?['role']?.toString() ??
        json['authorRole']?.toString() ??
        'Community Member';

    final authorAvatar = authorObj?['avatarUrl']?.toString() ??
        companyObj?['avatarUrl']?.toString() ??
        userObj?['avatarUrl']?.toString() ??
        json['authorAvatarUrl']?.toString();

    final rawDate = json['createdAt']?.toString();
    final parsedDate = rawDate != null ? DateTime.tryParse(rawDate) ?? DateTime.now() : DateTime.now();

    return PostComment(
      id: json['id']?.toString() ?? '',
      authorName: authorName,
      authorRole: authorRole,
      authorAvatarUrl: authorAvatar,
      text: (json['content'] ?? json['text'])?.toString() ?? '',
      createdAt: parsedDate,
      isMine: isMine,
      replies: const [],
    );
  }
}

class FeedPost {
  const FeedPost({
    required this.id,
    required this.authorName,
    required this.authorRole,
    this.authorAvatarUrl,
    required this.content,
    this.location,
    this.taggedTitle,
    required this.createdAt,
    this.isMyPost = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.sharesCount = 0,
    this.isLiked = false,
    this.comments = const [],
    this.photos = const [],
    this.tags = const [],
  });

  final String id;
  final String authorName;
  final String authorRole;
  final String? authorAvatarUrl;
  final String content;
  final String? location;
  final String? taggedTitle;
  final DateTime createdAt;
  final bool isMyPost;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool isLiked;
  final List<PostComment> comments;
  final List<String> photos;
  final List<String> tags;

  FeedPost copyWith({
    String? id,
    String? authorName,
    String? authorRole,
    String? authorAvatarUrl,
    String? content,
    String? location,
    String? taggedTitle,
    DateTime? createdAt,
    bool? isMyPost,
    int? likesCount,
    int? commentsCount,
    int? sharesCount,
    bool? isLiked,
    List<PostComment>? comments,
    List<String>? photos,
    List<String>? tags,
  }) {
    return FeedPost(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      authorAvatarUrl: authorAvatarUrl ?? this.authorAvatarUrl,
      content: content ?? this.content,
      location: location ?? this.location,
      taggedTitle: taggedTitle ?? this.taggedTitle,
      createdAt: createdAt ?? this.createdAt,
      isMyPost: isMyPost ?? this.isMyPost,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      sharesCount: sharesCount ?? this.sharesCount,
      isLiked: isLiked ?? this.isLiked,
      comments: comments ?? this.comments,
      photos: photos ?? this.photos,
      tags: tags ?? this.tags,
    );
  }

  factory FeedPost.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final authorObj = json['author'] is Map ? Map<String, dynamic>.from(json['author']) : null;
    final companyObj = json['company'] is Map ? Map<String, dynamic>.from(json['company']) : null;
    final String title = json['title']?.toString() ?? json['taggedTitle']?.toString() ?? '';
    final String description = json['description']?.toString() ?? json['content']?.toString() ?? '';

    final String? authorIdStr = json['authorId']?.toString() ??
        json['userId']?.toString() ??
        authorObj?['id']?.toString() ??
        companyObj?['id']?.toString();

    final bool matchUserId = (currentUserId != null &&
        currentUserId.isNotEmpty &&
        authorIdStr != null &&
        authorIdStr.isNotEmpty &&
        authorIdStr.toLowerCase() == currentUserId.toLowerCase());

    final bool isMyPost = matchUserId ||
        ((json['isMine'] == true || json['isMyPost'] == true) &&
            (authorIdStr == null || authorIdStr.isEmpty || matchUserId));

    final rawAuthorName = authorObj?['companyName']?.toString() ??
        authorObj?['name']?.toString() ??
        authorObj?['fullName']?.toString() ??
        authorObj?['businessName']?.toString() ??
        authorObj?['displayName']?.toString() ??
        companyObj?['companyName']?.toString() ??
        companyObj?['name']?.toString() ??
        companyObj?['businessName']?.toString() ??
        json['companyName']?.toString() ??
        json['authorName']?.toString() ??
        json['userName']?.toString() ??
        (json['user'] is Map ? json['user']['name']?.toString() ?? json['user']['companyName']?.toString() ?? json['user']['fullName']?.toString() : null) ??
        '';

    final authorName = rawAuthorName.isNotEmpty ? rawAuthorName : '';

    final authorRole = authorObj?['role']?.toString() ??
        companyObj?['role']?.toString() ??
        json['authorRole']?.toString() ??
        (json['location']?.toString().isNotEmpty == true ? json['location'].toString() : 'Verified Feed');

    final authorAvatar = authorObj?['avatarUrl']?.toString() ??
        companyObj?['avatarUrl']?.toString() ??
        json['authorAvatarUrl']?.toString();

    final photosList = (json['photos'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final tagsList = (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [];

    return FeedPost(
      id: json['id']?.toString() ?? '',
      authorName: authorName,
      authorRole: authorRole,
      authorAvatarUrl: authorAvatar,
      content: description,
      location: json['location']?.toString(),
      taggedTitle: title.isNotEmpty ? title : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      isMyPost: isMyPost,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      sharesCount: (json['sharesCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] == true,
      comments: const [],
      photos: photosList,
      tags: tagsList,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': taggedTitle,
        'description': content,
        'location': location,
        'createdAt': createdAt.toIso8601String(),
        'isMine': isMyPost,
        'likesCount': likesCount,
        'commentsCount': commentsCount,
        'sharesCount': sharesCount,
        'isLiked': isLiked,
        'photos': photos,
        'tags': tags,
      };
}
