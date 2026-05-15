# app/main.py
from fastapi import FastAPI
from app.routers import auth
from app.routers import training_plan
<<<<<<< Updated upstream
=======
from app.routers import achievements
from app.routers import checkin
>>>>>>> Stashed changes

# BUG FIX: import all models so SQLAlchemy registers every table
# before create_all / Alembic migrations run.
import app.models  # noqa: F401

app = FastAPI(title="Titan Gym Management System")


@app.get("/")
def read_root():
    return {"message": "Welcome to Titan Gym Management System"}


app.include_router(auth.router)
app.include_router(training_plan.router)
<<<<<<< Updated upstream

=======
app.include_router(achievements.router)
app.include_router(checkin.router)
>>>>>>> Stashed changes
