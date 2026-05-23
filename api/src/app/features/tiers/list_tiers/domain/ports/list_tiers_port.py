# FEATURE: list_tiers — port protocol.
from typing import Protocol, runtime_checkable

from ...._shared.entities import TierPage
from ..commands import ListTiersQuery


@runtime_checkable
class ListTiersPort(Protocol):
    async def list(self, query: ListTiersQuery) -> TierPage: ...
