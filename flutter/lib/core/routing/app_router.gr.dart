// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

/// generated route for
/// [AppShellPage]
class AppShellRoute extends PageRouteInfo<void> {
  const AppShellRoute({List<PageRouteInfo>? children})
    : super(AppShellRoute.name, initialChildren: children);

  static const String name = 'AppShellRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const AppShellPage();
    },
  );
}

/// generated route for
/// [CreatePostPage]
class CreatePostRoute extends PageRouteInfo<CreatePostRouteArgs> {
  CreatePostRoute({
    required int userId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         CreatePostRoute.name,
         args: CreatePostRouteArgs(userId: userId, key: key),
         rawPathParams: {'user_id': userId},
         initialChildren: children,
       );

  static const String name = 'CreatePostRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<CreatePostRouteArgs>(
        orElse: () => CreatePostRouteArgs(userId: pathParams.getInt('user_id')),
      );
      return CreatePostPage(userId: args.userId, key: args.key);
    },
  );
}

class CreatePostRouteArgs {
  const CreatePostRouteArgs({required this.userId, this.key});

  final int userId;

  final Key? key;

  @override
  String toString() {
    return 'CreatePostRouteArgs{userId: $userId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! CreatePostRouteArgs) return false;
    return userId == other.userId && key == other.key;
  }

  @override
  int get hashCode => userId.hashCode ^ key.hashCode;
}

/// generated route for
/// [CreateTierPage]
class CreateTierRoute extends PageRouteInfo<void> {
  const CreateTierRoute({List<PageRouteInfo>? children})
    : super(CreateTierRoute.name, initialChildren: children);

  static const String name = 'CreateTierRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateTierPage();
    },
  );
}

/// generated route for
/// [CreateUserPage]
class CreateUserRoute extends PageRouteInfo<void> {
  const CreateUserRoute({List<PageRouteInfo>? children})
    : super(CreateUserRoute.name, initialChildren: children);

  static const String name = 'CreateUserRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const CreateUserPage();
    },
  );
}

/// generated route for
/// [EditPostPage]
class EditPostRoute extends PageRouteInfo<EditPostRouteArgs> {
  EditPostRoute({required Post post, Key? key, List<PageRouteInfo>? children})
    : super(
        EditPostRoute.name,
        args: EditPostRouteArgs(post: post, key: key),
        initialChildren: children,
      );

  static const String name = 'EditPostRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<EditPostRouteArgs>();
      return EditPostPage(post: args.post, key: args.key);
    },
  );
}

class EditPostRouteArgs {
  const EditPostRouteArgs({required this.post, this.key});

  final Post post;

  final Key? key;

  @override
  String toString() {
    return 'EditPostRouteArgs{post: $post, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditPostRouteArgs) return false;
    return post == other.post && key == other.key;
  }

  @override
  int get hashCode => post.hashCode ^ key.hashCode;
}

/// generated route for
/// [EditTierPage]
class EditTierRoute extends PageRouteInfo<EditTierRouteArgs> {
  EditTierRoute({
    required int tierId,
    String tierName = '',
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         EditTierRoute.name,
         args: EditTierRouteArgs(tierId: tierId, tierName: tierName, key: key),
         rawPathParams: {'id': tierId},
         rawQueryParams: {'name': tierName},
         initialChildren: children,
       );

  static const String name = 'EditTierRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<EditTierRouteArgs>(
        orElse: () => EditTierRouteArgs(
          tierId: pathParams.getInt('id'),
          tierName: queryParams.getString('name', ''),
        ),
      );
      return EditTierPage(
        tierId: args.tierId,
        tierName: args.tierName,
        key: args.key,
      );
    },
  );
}

class EditTierRouteArgs {
  const EditTierRouteArgs({required this.tierId, this.tierName = '', this.key});

  final int tierId;

  final String tierName;

  final Key? key;

  @override
  String toString() {
    return 'EditTierRouteArgs{tierId: $tierId, tierName: $tierName, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditTierRouteArgs) return false;
    return tierId == other.tierId &&
        tierName == other.tierName &&
        key == other.key;
  }

  @override
  int get hashCode => tierId.hashCode ^ tierName.hashCode ^ key.hashCode;
}

/// generated route for
/// [EditUserPage]
class EditUserRoute extends PageRouteInfo<EditUserRouteArgs> {
  EditUserRoute({required int userId, Key? key, List<PageRouteInfo>? children})
    : super(
        EditUserRoute.name,
        args: EditUserRouteArgs(userId: userId, key: key),
        rawPathParams: {'user_id': userId},
        initialChildren: children,
      );

  static const String name = 'EditUserRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<EditUserRouteArgs>(
        orElse: () => EditUserRouteArgs(userId: pathParams.getInt('user_id')),
      );
      return EditUserPage(userId: args.userId, key: args.key);
    },
  );
}

class EditUserRouteArgs {
  const EditUserRouteArgs({required this.userId, this.key});

  final int userId;

  final Key? key;

  @override
  String toString() {
    return 'EditUserRouteArgs{userId: $userId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! EditUserRouteArgs) return false;
    return userId == other.userId && key == other.key;
  }

  @override
  int get hashCode => userId.hashCode ^ key.hashCode;
}

/// generated route for
/// [ListPostsPage]
class ListPostsRoute extends PageRouteInfo<void> {
  const ListPostsRoute({List<PageRouteInfo>? children})
    : super(ListPostsRoute.name, initialChildren: children);

  static const String name = 'ListPostsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ListPostsPage();
    },
  );
}

/// generated route for
/// [ListTiersPage]
class ListTiersRoute extends PageRouteInfo<void> {
  const ListTiersRoute({List<PageRouteInfo>? children})
    : super(ListTiersRoute.name, initialChildren: children);

  static const String name = 'ListTiersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const ListTiersPage();
    },
  );
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<LoginRouteArgs> {
  LoginRoute({Key? key, String? redirectPath, List<PageRouteInfo>? children})
    : super(
        LoginRoute.name,
        args: LoginRouteArgs(key: key, redirectPath: redirectPath),
        rawQueryParams: {'redirect': redirectPath},
        initialChildren: children,
      );

  static const String name = 'LoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final queryParams = data.queryParams;
      final args = data.argsAs<LoginRouteArgs>(
        orElse: () =>
            LoginRouteArgs(redirectPath: queryParams.optString('redirect')),
      );
      return LoginPage(key: args.key, redirectPath: args.redirectPath);
    },
  );
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.redirectPath});

  final Key? key;

  final String? redirectPath;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, redirectPath: $redirectPath}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LoginRouteArgs) return false;
    return key == other.key && redirectPath == other.redirectPath;
  }

  @override
  int get hashCode => key.hashCode ^ redirectPath.hashCode;
}

/// generated route for
/// [ModeratePostPage]
class ModeratePostRoute extends PageRouteInfo<ModeratePostRouteArgs> {
  ModeratePostRoute({
    required String postUuid,
    required PendingPostItem post,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         ModeratePostRoute.name,
         args: ModeratePostRouteArgs(postUuid: postUuid, post: post, key: key),
         rawPathParams: {'post_uuid': postUuid},
         initialChildren: children,
       );

  static const String name = 'ModeratePostRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<ModeratePostRouteArgs>();
      return ModeratePostPage(
        postUuid: args.postUuid,
        post: args.post,
        key: args.key,
      );
    },
  );
}

class ModeratePostRouteArgs {
  const ModeratePostRouteArgs({
    required this.postUuid,
    required this.post,
    this.key,
  });

  final String postUuid;

  final PendingPostItem post;

  final Key? key;

  @override
  String toString() {
    return 'ModeratePostRouteArgs{postUuid: $postUuid, post: $post, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ModeratePostRouteArgs) return false;
    return postUuid == other.postUuid && post == other.post && key == other.key;
  }

  @override
  int get hashCode => postUuid.hashCode ^ post.hashCode ^ key.hashCode;
}

/// generated route for
/// [PendingPostsPage]
class PendingPostsRoute extends PageRouteInfo<void> {
  const PendingPostsRoute({List<PageRouteInfo>? children})
    : super(PendingPostsRoute.name, initialChildren: children);

  static const String name = 'PendingPostsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PendingPostsPage();
    },
  );
}

/// generated route for
/// [PendingTabPage]
class PendingTabRoute extends PageRouteInfo<void> {
  const PendingTabRoute({List<PageRouteInfo>? children})
    : super(PendingTabRoute.name, initialChildren: children);

  static const String name = 'PendingTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PendingTabPage();
    },
  );
}

/// generated route for
/// [PostDetailsPage]
class PostDetailsRoute extends PageRouteInfo<PostDetailsRouteArgs> {
  PostDetailsRoute({
    required int userId,
    required int id,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         PostDetailsRoute.name,
         args: PostDetailsRouteArgs(userId: userId, id: id, key: key),
         rawPathParams: {'user_id': userId, 'id': id},
         initialChildren: children,
       );

  static const String name = 'PostDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<PostDetailsRouteArgs>(
        orElse: () => PostDetailsRouteArgs(
          userId: pathParams.getInt('user_id'),
          id: pathParams.getInt('id'),
        ),
      );
      return PostDetailsPage(userId: args.userId, id: args.id, key: args.key);
    },
  );
}

class PostDetailsRouteArgs {
  const PostDetailsRouteArgs({
    required this.userId,
    required this.id,
    this.key,
  });

  final int userId;

  final int id;

  final Key? key;

  @override
  String toString() {
    return 'PostDetailsRouteArgs{userId: $userId, id: $id, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PostDetailsRouteArgs) return false;
    return userId == other.userId && id == other.id && key == other.key;
  }

  @override
  int get hashCode => userId.hashCode ^ id.hashCode ^ key.hashCode;
}

/// generated route for
/// [PostsTabPage]
class PostsTabRoute extends PageRouteInfo<void> {
  const PostsTabRoute({List<PageRouteInfo>? children})
    : super(PostsTabRoute.name, initialChildren: children);

  static const String name = 'PostsTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const PostsTabPage();
    },
  );
}

/// generated route for
/// [TierDetailsPage]
class TierDetailsRoute extends PageRouteInfo<TierDetailsRouteArgs> {
  TierDetailsRoute({
    required int tierId,
    String tierName = '',
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         TierDetailsRoute.name,
         args: TierDetailsRouteArgs(
           tierId: tierId,
           tierName: tierName,
           key: key,
         ),
         rawPathParams: {'id': tierId},
         rawQueryParams: {'name': tierName},
         initialChildren: children,
       );

  static const String name = 'TierDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<TierDetailsRouteArgs>(
        orElse: () => TierDetailsRouteArgs(
          tierId: pathParams.getInt('id'),
          tierName: queryParams.getString('name', ''),
        ),
      );
      return TierDetailsPage(
        tierId: args.tierId,
        tierName: args.tierName,
        key: args.key,
      );
    },
  );
}

class TierDetailsRouteArgs {
  const TierDetailsRouteArgs({
    required this.tierId,
    this.tierName = '',
    this.key,
  });

  final int tierId;

  final String tierName;

  final Key? key;

  @override
  String toString() {
    return 'TierDetailsRouteArgs{tierId: $tierId, tierName: $tierName, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TierDetailsRouteArgs) return false;
    return tierId == other.tierId &&
        tierName == other.tierName &&
        key == other.key;
  }

  @override
  int get hashCode => tierId.hashCode ^ tierName.hashCode ^ key.hashCode;
}

/// generated route for
/// [TiersTabPage]
class TiersTabRoute extends PageRouteInfo<void> {
  const TiersTabRoute({List<PageRouteInfo>? children})
    : super(TiersTabRoute.name, initialChildren: children);

  static const String name = 'TiersTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const TiersTabPage();
    },
  );
}

/// generated route for
/// [UserDetailsPage]
class UserDetailsRoute extends PageRouteInfo<UserDetailsRouteArgs> {
  UserDetailsRoute({
    required int userId,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         UserDetailsRoute.name,
         args: UserDetailsRouteArgs(userId: userId, key: key),
         rawPathParams: {'user_id': userId},
         initialChildren: children,
       );

  static const String name = 'UserDetailsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<UserDetailsRouteArgs>(
        orElse: () =>
            UserDetailsRouteArgs(userId: pathParams.getInt('user_id')),
      );
      return UserDetailsPage(userId: args.userId, key: args.key);
    },
  );
}

class UserDetailsRouteArgs {
  const UserDetailsRouteArgs({required this.userId, this.key});

  final int userId;

  final Key? key;

  @override
  String toString() {
    return 'UserDetailsRouteArgs{userId: $userId, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserDetailsRouteArgs) return false;
    return userId == other.userId && key == other.key;
  }

  @override
  int get hashCode => userId.hashCode ^ key.hashCode;
}

/// generated route for
/// [UserPostsPage]
class UserPostsRoute extends PageRouteInfo<UserPostsRouteArgs> {
  UserPostsRoute({
    required int userId,
    required String username,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
         UserPostsRoute.name,
         args: UserPostsRouteArgs(userId: userId, username: username, key: key),
         rawPathParams: {'user_id': userId},
         initialChildren: children,
       );

  static const String name = 'UserPostsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UserPostsRouteArgs>();
      return UserPostsPage(
        userId: args.userId,
        username: args.username,
        key: args.key,
      );
    },
  );
}

class UserPostsRouteArgs {
  const UserPostsRouteArgs({
    required this.userId,
    required this.username,
    this.key,
  });

  final int userId;

  final String username;

  final Key? key;

  @override
  String toString() {
    return 'UserPostsRouteArgs{userId: $userId, username: $username, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserPostsRouteArgs) return false;
    return userId == other.userId &&
        username == other.username &&
        key == other.key;
  }

  @override
  int get hashCode => userId.hashCode ^ username.hashCode ^ key.hashCode;
}

/// generated route for
/// [UsersPage]
class UsersRoute extends PageRouteInfo<void> {
  const UsersRoute({List<PageRouteInfo>? children})
    : super(UsersRoute.name, initialChildren: children);

  static const String name = 'UsersRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const UsersPage();
    },
  );
}

/// generated route for
/// [UsersTabPage]
class UsersTabRoute extends PageRouteInfo<void> {
  const UsersTabRoute({List<PageRouteInfo>? children})
    : super(UsersTabRoute.name, initialChildren: children);

  static const String name = 'UsersTabRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const UsersTabPage();
    },
  );
}
