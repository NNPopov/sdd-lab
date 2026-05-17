# STABLE: Infrastructure skeleton. Change only when infra changes.
from sqlalchemy.orm import DeclarativeBase, MappedAsDataclass


class Base(DeclarativeBase, MappedAsDataclass):
    pass
