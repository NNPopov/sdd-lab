# STABLE: Queue port.
from typing import Any, Protocol


class IQueueClient(Protocol):
    async def enqueue_job(self, function: str, *args: Any, **kwargs: Any) -> Any: ...
