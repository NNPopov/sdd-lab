# FEATURE: users — re-exports auth dependencies from shared_dependencies.
# Keep this module so existing test overrides continue to work.
from ...shared_dependencies import (  # noqa: F401
    get_current_moderator_or_superuser,
    get_current_superuser,
    get_current_user,
    get_optional_user,
)
