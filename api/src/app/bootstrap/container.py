# STABLE: DI container. Wires adapters and use cases for the users feature.
from dependency_injector import containers, providers

from ..adapters.db.session import local_session
from ..core.security import get_password_hash
from ..core.token_blacklist_service import TokenBlacklistService
from ..features.posts.create_post.data.adapter import CreatePostAdapter
from ..features.posts.create_post.domain.use_case import CreatePostUseCase
from ..features.posts.get_moderation_log.data.adapter import GetModerationLogAdapter
from ..features.posts.get_moderation_log.domain.use_case import GetModerationLogUseCase
from ..features.posts.list_all_posts.data.adapter import ListAllPostsAdapter
from ..features.posts.list_all_posts.domain.use_case import ListAllPostsUseCase
from ..features.posts.list_pending_posts.data.adapter import ListPendingPostsAdapter
from ..features.posts.list_pending_posts.domain.use_case import ListPendingPostsUseCase
from ..features.posts.list_posts.data.adapter import ListPostsAdapter
from ..features.posts.list_posts.domain.use_case import ListPostsUseCase
from ..features.posts.moderate_post.data.adapter import ModeratePostAdapter
from ..features.posts.moderate_post.domain.use_case import ModeratePostUseCase
from ..features.posts.revise_post.data.adapter import RevisePostAdapter
from ..features.posts.revise_post.domain.use_case import RevisePostUseCase
from ..features.users.assign_moderator.data.adapter import AssignModeratorAdapter
from ..features.users.assign_moderator.domain.use_case import AssignModeratorUseCase
from ..features.users.create_user.data.adapter import CreateUserAdapter
from ..features.users.create_user.domain.use_case import CreateUserUseCase
from ..features.users.delete_db_user.data.adapter import DeleteDbUserAdapter
from ..features.users.delete_db_user.domain.use_case import DeleteDbUserUseCase
from ..features.users.delete_user.data.adapter import DeleteUserAdapter
from ..features.users.delete_user.domain.use_case import DeleteUserUseCase
from ..features.users.get_user_by_username.data.adapter import GetUserByUsernameAdapter
from ..features.users.get_user_by_username.domain.use_case import GetUserByUsernameUseCase
from ..features.users.get_user_tier.data.adapter import GetUserTierAdapter
from ..features.users.get_user_tier.domain.use_case import GetUserTierUseCase
from ..features.users.list_users.data.adapter import ListUsersAdapter
from ..features.users.list_users.domain.use_case import ListUsersUseCase
from ..features.users.revoke_moderator.data.adapter import RevokeModeratorAdapter
from ..features.users.revoke_moderator.domain.use_case import RevokeModeratorUseCase
from ..features.users.update_user.data.adapter import UpdateUserAdapter
from ..features.users.update_user.domain.use_case import UpdateUserUseCase


class Container(containers.DeclarativeContainer):
    session_factory = providers.Object(local_session)

    password_hasher = providers.Object(get_password_hash)

    create_user_adapter = providers.Factory(
        CreateUserAdapter,
        session_factory=session_factory,
    )

    create_user_use_case = providers.Factory(
        CreateUserUseCase,
        port=create_user_adapter,
        password_hasher=password_hasher,
    )

    list_users_adapter = providers.Factory(
        ListUsersAdapter,
        session_factory=session_factory,
    )

    list_users_use_case = providers.Factory(
        ListUsersUseCase,
        port=list_users_adapter,
    )

    get_user_by_username_adapter = providers.Factory(
        GetUserByUsernameAdapter,
        session_factory=session_factory,
    )

    get_user_by_username_use_case = providers.Factory(
        GetUserByUsernameUseCase,
        port=get_user_by_username_adapter,
    )

    get_user_tier_adapter = providers.Factory(
        GetUserTierAdapter,
        session_factory=session_factory,
    )

    get_user_tier_use_case = providers.Factory(
        GetUserTierUseCase,
        port=get_user_tier_adapter,
    )

    update_user_adapter = providers.Factory(
        UpdateUserAdapter,
        session_factory=session_factory,
    )

    update_user_use_case = providers.Factory(
        UpdateUserUseCase,
        port=update_user_adapter,
    )

    token_blacklist_service = providers.Factory(
        TokenBlacklistService,
        session_factory=session_factory,
    )

    delete_user_adapter = providers.Factory(
        DeleteUserAdapter,
        session_factory=session_factory,
    )

    delete_user_use_case = providers.Factory(
        DeleteUserUseCase,
        port=delete_user_adapter,
    )

    delete_db_user_adapter = providers.Factory(
        DeleteDbUserAdapter,
        session_factory=session_factory,
    )

    delete_db_user_use_case = providers.Factory(
        DeleteDbUserUseCase,
        port=delete_db_user_adapter,
    )

    list_posts_adapter = providers.Factory(
        ListPostsAdapter,
        session_factory=session_factory,
    )

    list_posts_use_case = providers.Factory(
        ListPostsUseCase,
        port=list_posts_adapter,
    )

    list_all_posts_adapter = providers.Factory(
        ListAllPostsAdapter,
        session_factory=session_factory,
    )

    list_all_posts_use_case = providers.Factory(
        ListAllPostsUseCase,
        port=list_all_posts_adapter,
    )

    create_post_adapter = providers.Factory(
        CreatePostAdapter,
        session_factory=session_factory,
    )

    create_post_use_case = providers.Factory(
        CreatePostUseCase,
        port=create_post_adapter,
    )

    assign_moderator_adapter = providers.Factory(
        AssignModeratorAdapter,
        session_factory=session_factory,
    )

    assign_moderator_use_case = providers.Factory(
        AssignModeratorUseCase,
        port=assign_moderator_adapter,
    )

    revoke_moderator_adapter = providers.Factory(
        RevokeModeratorAdapter,
        session_factory=session_factory,
    )

    revoke_moderator_use_case = providers.Factory(
        RevokeModeratorUseCase,
        port=revoke_moderator_adapter,
    )

    moderate_post_adapter = providers.Factory(
        ModeratePostAdapter,
        session_factory=session_factory,
    )

    moderate_post_use_case = providers.Factory(
        ModeratePostUseCase,
        port=moderate_post_adapter,
    )

    revise_post_adapter = providers.Factory(
        RevisePostAdapter,
        session_factory=session_factory,
    )

    revise_post_use_case = providers.Factory(
        RevisePostUseCase,
        port=revise_post_adapter,
    )

    list_pending_posts_adapter = providers.Factory(
        ListPendingPostsAdapter,
        session_factory=session_factory,
    )

    list_pending_posts_use_case = providers.Factory(
        ListPendingPostsUseCase,
        port=list_pending_posts_adapter,
    )

    get_moderation_log_adapter = providers.Factory(
        GetModerationLogAdapter,
        session_factory=session_factory,
    )

    get_moderation_log_use_case = providers.Factory(
        GetModerationLogUseCase,
        port=get_moderation_log_adapter,
    )


container = Container()
