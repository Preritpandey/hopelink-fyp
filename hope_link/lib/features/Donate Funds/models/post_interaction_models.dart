class PostInteractionState {
  final int totalLikes;
  final bool isLikedByCurrentUser;
  final int commentsCount;

  const PostInteractionState({
    this.totalLikes = 0,
    this.isLikedByCurrentUser = false,
    this.commentsCount = 0,
  });

  factory PostInteractionState.fromJson(Map<String, dynamic>? json) {
    final source = json ?? const <String, dynamic>{};
    return PostInteractionState(
      totalLikes: source['totalLikes'] is num
          ? (source['totalLikes'] as num).toInt()
          : 0,
      isLikedByCurrentUser: source['isLikedByCurrentUser'] == true,
      commentsCount: source['commentsCount'] is num
          ? (source['commentsCount'] as num).toInt()
          : 0,
    );
  }

  PostInteractionState copyWith({
    int? totalLikes,
    bool? isLikedByCurrentUser,
    int? commentsCount,
  }) {
    return PostInteractionState(
      totalLikes: totalLikes ?? this.totalLikes,
      isLikedByCurrentUser: isLikedByCurrentUser ?? this.isLikedByCurrentUser,
      commentsCount: commentsCount ?? this.commentsCount,
    );
  }
}

class PostCommentUser {
  final String id;
  final String name;
  final String? email;
  final String? profileImage;

  const PostCommentUser({
    required this.id,
    required this.name,
    this.email,
    this.profileImage,
  });

  factory PostCommentUser.fromJson(Map<String, dynamic>? json) {
    final source = json ?? const <String, dynamic>{};
    return PostCommentUser(
      id: (source['_id'] ?? source['id'] ?? '').toString(),
      name: (source['name'] ?? 'HopeLink User').toString(),
      email: source['email']?.toString(),
      profileImage: source['profileImage']?.toString(),
    );
  }
}

class PostComment {
  final String id;
  final String postId;
  final String postType;
  final String text;
  final PostCommentUser user;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isOwner;

  const PostComment({
    required this.id,
    required this.postId,
    required this.postType,
    required this.text,
    required this.user,
    required this.createdAt,
    required this.updatedAt,
    this.isOwner = false,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      postId: (json['postId'] ?? '').toString(),
      postType: (json['postType'] ?? '').toString(),
      text: (json['text'] ?? '').toString(),
      user: PostCommentUser.fromJson(json['user'] as Map<String, dynamic>?),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()) ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()) ??
          DateTime.now(),
      isOwner: json['isOwner'] == true,
    );
  }
}
