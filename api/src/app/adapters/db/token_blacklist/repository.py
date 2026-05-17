# STABLE: Infrastructure skeleton. Change only when infra changes.
from fastcrud import FastCRUD

from ....core.schemas import TokenBlacklistCreate, TokenBlacklistRead, TokenBlacklistUpdate
from .model import TokenBlacklist

CRUDTokenBlacklist = FastCRUD[
    TokenBlacklist,
    TokenBlacklistCreate,
    TokenBlacklistUpdate,
    TokenBlacklistUpdate,
    TokenBlacklistUpdate,
    TokenBlacklistRead,
]
crud_token_blacklist = CRUDTokenBlacklist(TokenBlacklist)
