# FEATURE: get_user_by_id — adapter test fixtures.
import pytest_asyncio
from sqlalchemy.ext.asyncio import async_sessionmaker


@pytest_asyncio.fixture()
async def adapter_session_factory(oit_engine):
    """Session factory bound to a rolled-back outer transaction."""
    connection = await oit_engine.connect()
    transaction = await connection.begin()
    factory = async_sessionmaker(
        bind=connection,
        expire_on_commit=False,
        join_transaction_mode="create_savepoint",
    )
    yield factory
    await transaction.rollback()
    await connection.close()
