# FEATURE: tiers — repository (FastCRUD instance).
from fastcrud import FastCRUD

from ...adapters.db.models.tier import Tier
from .schemas import TierCreateInternal, TierDelete, TierRead, TierUpdate, TierUpdateInternal

CRUDTier = FastCRUD[Tier, TierCreateInternal, TierUpdate, TierUpdateInternal, TierDelete, TierRead]
crud_tiers = CRUDTier(Tier)
