# STABLE: Domain error hierarchy. No framework imports allowed.
class DomainError(Exception):
    """Base class for domain-level errors."""

    def __init__(self, message: str = "", code: str | None = None):
        self.message = message
        # If code not provided, derive from class name
        if code is None:
            class_name = self.__class__.__name__
            if class_name.endswith("DomainError"):
                self.code = class_name[:-11].lower()  # Remove "DomainError" suffix
            else:
                self.code = class_name.lower()
        else:
            self.code = code
        super().__init__(message)


class NotFoundDomainError(DomainError):
    """Raised when a requested resource is not found."""


class DuplicateValueDomainError(DomainError):
    """Raised when a duplicate value would be created."""


class ForbiddenDomainError(DomainError):
    """Raised when access to a resource is forbidden."""


class UnknownDomainError(DomainError):
    """Raised when an adapter encounters an unexpected failure."""
