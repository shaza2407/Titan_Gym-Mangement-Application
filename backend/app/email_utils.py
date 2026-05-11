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
    link = f"http://localhost:8000/auth/verify-email?token={token}"
    message = MessageSchema(
        subject = "Confirm your Titan App account",
        recipients = [email],
        body       = f"Hi! Please verify your email:\n\n{link}\n\nExpires in 24 hours.",
        subtype    = "plain"
    )
    await FastMail(conf).send_message(message)

async def send_reset_email(email: str, token: str):
    link = f"http://localhost:8000/auth/reset-password?token={token}"
    message = MessageSchema(
        subject    = "Titan Account — Password Reset",
        recipients = [email],
        body       = f"Reset your password here:\n\n{link}\n\n Link expires in 30 minutes.",
        subtype    = "plain"
    )
    await FastMail(conf).send_message(message)