# STABLE: Infrastructure skeleton. Change only when infra changes.
from arq.connections import ArqRedis

pool: ArqRedis | None = None
