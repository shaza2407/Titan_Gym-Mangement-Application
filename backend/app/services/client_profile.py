from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from datetime import date
from app.models import User, Client
from app.schemas.client_profile_schema import ClientProfileUpdate, ClientProfileResponse


def _calculate_age(dob: date) -> int:
    today = date.today()
    return today.year - dob.year - (
        (today.month, today.day) < (dob.month, dob.day)
    )


def _build_response(user: User, client: Client) -> ClientProfileResponse:
    age = _calculate_age(client.date_of_birth) if client.date_of_birth else None
    return ClientProfileResponse(
        userID=user.userID,
        name=user.name,
        email=user.email,
        phone=user.phone,
        clientID=client.clientID,
        gender=client.gender,
        fitness_goal=client.fitness_goal,
        date_of_birth=client.date_of_birth,
        age=age,
        bio=client.bio,
        emergency_contact=client.emergency_contact,
    )


async def get_client_profile(userID: int, db: AsyncSession) -> ClientProfileResponse | None:
    user_result = await db.execute(select(User).where(User.userID == userID))
    user = user_result.scalar_one_or_none()
    if not user:
        return None

    client_result = await db.execute(select(Client).where(Client.userID == userID))
    client = client_result.scalar_one_or_none()
    if not client:
        return None

    return _build_response(user, client)


async def update_client_profile(
    userID: int,
    payload: ClientProfileUpdate,
    db: AsyncSession
) -> ClientProfileResponse | None:

    user_result = await db.execute(select(User).where(User.userID == userID))
    user = user_result.scalar_one_or_none()
    if not user:
        return None

    client_result = await db.execute(select(Client).where(Client.userID == userID))
    client = client_result.scalar_one_or_none()
    if not client:
        return None

    # Update User fields
    if payload.name is not None:
        user.name = payload.name
    if payload.phone is not None:
        user.phone = payload.phone

    # Update Client fields
    if payload.gender is not None:
        client.gender = payload.gender
    if payload.fitness_goal is not None:
        client.fitness_goal = payload.fitness_goal
    if payload.date_of_birth is not None:
        client.date_of_birth = payload.date_of_birth
    if payload.bio is not None:
        client.bio = payload.bio
    if payload.emergency_contact is not None:
        client.emergency_contact = payload.emergency_contact

    await db.commit()
    await db.refresh(user)
    await db.refresh(client)

    return _build_response(user, client)