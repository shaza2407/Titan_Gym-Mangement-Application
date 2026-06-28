from unittest.mock import MagicMock

def make_user(**overrides):
    user = MagicMock()
    user.userID = 1
    user.email = "test@example.com"
    user.name = "Test User"
    user.password = "$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj4J/HS.iK8i"
    user.role = "client"
    user.phone = "01234567890"
    user.is_verified = True
    user.reset_token = None
    user.reset_token_exp = None
    for key, value in overrides.items():
        setattr(user, key, value)
    return user

def mock_execute_returning(db, value):
    result = MagicMock()
    result.scalar_one_or_none.return_value = value
    db.execute.return_value = result