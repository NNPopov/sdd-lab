# STABLE: DI container. Wires adapters and use cases for the users feature.
from dependency_injector import containers, providers

from ..adapters.db.session import local_session
from ..adapters.db.token_blacklist.adapter import TokenBlacklistAdapter
from ..core.security import get_password_hash
from ..features.posts._shared.user_lookup_adapter import UserLookupAdapter
from ..features.posts.create_post.data.adapter import CreatePostAdapter
from ..features.posts.create_post.domain.use_case import CreatePostUseCase
from ..features.posts.erase_db_post.data.adapter import EraseDbPostAdapter
from ..features.posts.erase_db_post.domain.use_case import EraseDbPostUseCase
from ..features.posts.erase_post.data.adapter import ErasePostAdapter
from ..features.posts.erase_post.domain.use_case import ErasePostUseCase
from ..features.posts.get_moderation_log.data.adapter import GetModerationLogAdapter
from ..features.posts.get_moderation_log.domain.use_case import GetModerationLogUseCase
from ..features.posts.get_post.data.adapter import GetPostAdapter
from ..features.posts.get_post.domain.use_case import GetPostUseCase
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
from ..features.posts.update_post.data.adapter import UpdatePostAdapter
from ..features.posts.update_post.domain.use_case import UpdatePostUseCase
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

# Derive app package prefix from this module's qualified name so WiringConfiguration
# uses the same namespace the app was loaded under — "app" when started from src/,
# "src.app" when started as `uvicorn src.app.main:app` from the project root.
_app_pkg = __name__.rsplit(".bootstrap.container", 1)[0]


class Container(containers.DeclarativeContainer):
    wiring_config = containers.WiringConfiguration(
        modules=[
            f"{_app_pkg}.features.users.create_user.presentation.router",
            f"{_app_pkg}.features.users.list_users.presentation.router",
            f"{_app_pkg}.features.users.get_user_by_username.presentation.router",
            f"{_app_pkg}.features.users.get_user_tier.presentation.router",
            f"{_app_pkg}.features.users.update_user.presentation.router",
            f"{_app_pkg}.features.users.delete_user.presentation.router",
            f"{_app_pkg}.features.users.delete_db_user.presentation.router",
            f"{_app_pkg}.features.users.assign_moderator.presentation.router",
            f"{_app_pkg}.features.users.revoke_moderator.presentation.router",
            f"{_app_pkg}.features.posts.create_post.presentation.router",
            f"{_app_pkg}.features.posts.list_posts.presentation.router",
            f"{_app_pkg}.features.posts.list_all_posts.presentation.router",
            f"{_app_pkg}.features.posts.list_pending_posts.presentation.router",
            f"{_app_pkg}.features.posts.get_post.presentation.router",
            f"{_app_pkg}.features.posts.moderate_post.presentation.router",
            f"{_app_pkg}.features.posts.revise_post.presentation.router",
            f"{_app_pkg}.features.posts.get_moderation_log.presentation.router",
            f"{_app_pkg}.features.posts.update_post.presentation.router",
            f"{_app_pkg}.features.posts.erase_post.presentation.router",
            f"{_app_pkg}.features.posts.erase_db_post.presentation.router",
            f"{_app_pkg}.shared_dependencies",
        ]
    )

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

    token_blacklist_adapter = providers.Factory(
        TokenBlacklistAdapter,
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

    user_lookup_adapter = providers.Factory(
        UserLookupAdapter,
        session_factory=session_factory,
    )

    create_post_adapter = providers.Factory(
        CreatePostAdapter,
        session_factory=session_factory,
    )

    create_post_use_case = providers.Factory(
        CreatePostUseCase,
        port=create_post_adapter,
        user_lookup=user_lookup_adapter,
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

    get_post_adapter = providers.Factory(
        GetPostAdapter,
        session_factory=session_factory,
    )

    get_post_use_case = providers.Factory(
        GetPostUseCase,
        port=get_post_adapter,
    )

    update_post_adapter = providers.Factory(
        UpdatePostAdapter,
        session_factory=session_factory,
    )

    update_post_use_case = providers.Factory(
        UpdatePostUseCase,
        port=update_post_adapter,
        user_lookup=user_lookup_adapter,
    )

    erase_post_adapter = providers.Factory(
        ErasePostAdapter,
        session_factory=session_factory,
    )

    erase_post_use_case = providers.Factory(
        ErasePostUseCase,
        port=erase_post_adapter,
        user_lookup=user_lookup_adapter,
    )

    erase_db_post_adapter = providers.Factory(
        EraseDbPostAdapter,
        session_factory=session_factory,
    )

    erase_db_post_use_case = providers.Factory(
        EraseDbPostUseCase,
        port=erase_db_post_adapter,
        user_lookup=user_lookup_adapter,
    )


container = Container()
