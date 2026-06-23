from enum import Enum

class UserRole(str, Enum):
    client = "client"
    coach = "coach"
    admin = "admin"