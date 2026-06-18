from fastapi_mail import FastMail, MessageSchema, ConnectionConfig
import os

conf = ConnectionConfig(
    MAIL_USERNAME  = os.getenv("MAIL_USERNAME"),
    MAIL_PASSWORD  = os.getenv("MAIL_PASSWORD"),
    MAIL_FROM      = os.getenv("MAIL_FROM"),
    MAIL_PORT      = 587,
    MAIL_SERVER    = "smtp.gmail.com",
    MAIL_STARTTLS  = True,
    MAIL_SSL_TLS   = False,
)

async def send_verification_email(email: str, token: str):
    link = f"{token}"
    message = MessageSchema(
        subject = "Confirm your Titan App account",
        recipients = [email],
        body       = f"Hi! Welcome to Titan !\n Please verify yor email using the following code:\n\n{token}\n\nExpires in 24 hours.\n do not share this code with anyone.",
        subtype    = "plain"
    )
    await FastMail(conf).send_message(message)

async def send_reset_email(email: str, token: str):
    message = MessageSchema(
        subject    = "Titan Account — Reseting your password",
        recipients = [email],
        body       = f"Reset your password using the folloeing code:\n\n{token}\n\n it expires in 30 minutes. \n If you didn't request this, you can safely ignore this email. \n do not share this code with anyone.",
        subtype    = "plain"
    )
    await FastMail(conf).send_message(message)



async def send_invitation_email(email: str, gym_name: str, token: str):
    link = f"http://localhost:5173/accept-invitation?token={token}"
    body = (
        f"Hi\n\n"
        f"You've been invited to join {gym_name} on Titan App.\n\n"
        f"Click the link below to accept your invitation:\n\n"
        f"{link}\n\n"
        f"This invitation expires in 7 days.\n\n"
        f"If you didn't expect this, you can safely ignore this email."
    )
    message = MessageSchema(
        subject = f"You're invited to join {gym_name} on Titan App.",
        recipients = [email],
        body = body,
        subtype = "plain",
    )
    await FastMail(conf).send_message(message)