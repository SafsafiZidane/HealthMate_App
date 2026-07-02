import pytest
from fastapi import HTTPException
from app.repository.dependencies import get_current_standard_user
from app.tables.users import UserRole


class _UserStub:
    def __init__(self, role):
        self.role = role
        self.email = "test@example.com"


def test_admin_cannot_use_user_features():
    admin_user = _UserStub(UserRole.ADMIN)

    with pytest.raises(HTTPException) as exc_info:
        get_current_standard_user(admin_user)

    assert exc_info.value.status_code == 403
    assert "Administrators cannot use user features" in str(exc_info.value.detail)


def test_regular_user_can_use_user_features():
    regular_user = _UserStub(UserRole.USER)

    result = get_current_standard_user(regular_user)

    assert result is regular_user
