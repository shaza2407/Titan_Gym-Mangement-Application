from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models import User, Client
from app.schemas.client_profile_schema import ClientProfileUpdate, ClientProfileResponse

async def get_client_profile(userID: int, db: AsyncSession) -> ClientProfileResponse:
    # Get user
    user_result = await db.execute(select(User).where(User.userID == userID))
    user = user_result.scalar_one_or_none()
    if not user:
        return None

    # Get client
    client_result = await db.execute(select(Client).where(Client.userID == userID))
    client = client_result.scalar_one_or_none()
    if not client:
        return None

    return ClientProfileResponse(
        userID=user.userID,
        name=user.name,
        email=user.email,
        phone=user.phone,
        clientID=client.clientID,
        age=client.age,
        gender=client.gender,
        fitness_goal=client.fitness_goal,
        bio=client.bio,
        emergency_contact=client.emergency_contact,
        profile_picture=client.profile_picture,
    )


async def update_client_profile(
    userID: int,
    payload: ClientProfileUpdate,
    db: AsyncSession
) -> ClientProfileResponse:

    # Get user
    user_result = await db.execute(select(User).where(User.userID == userID))
    user = user_result.scalar_one_or_none()
    if not user:
        return None

    # Get client
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
    if payload.age is not None:
        client.age = payload.age
    if payload.gender is not None:
        client.gender = payload.gender
    if payload.fitness_goal is not None:
        client.fitness_goal = payload.fitness_goal
    if payload.bio is not None:
        client.bio = payload.bio
    if payload.emergency_contact is not None:
        client.emergency_contact = payload.emergency_contact
    if payload.profile_picture is not None:
        client.profile_picture = payload.profile_picture

    await db.commit()
    await db.refresh(user)
    await db.refresh(client)

    return ClientProfileResponse(
        userID=user.userID,
        name=user.name,
        email=user.email,
        phone=user.phone,
        clientID=client.clientID,
        age=client.age,
        gender=client.gender,
        fitness_goal=client.fitness_goal,
        bio=client.bio,
        emergency_contact=client.emergency_contact,
        profile_picture=client.profile_picture,
    )