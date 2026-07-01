from fastapi import APIRouter, Depends, status
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from io import BytesIO

from app.database import get_session
from app.dependencies.auth import require_client
from app.schemas.client.TrainingPlanRequest import TrainingPlanRequest
from app.schemas.client.TrainingPlanResponse import (
    TrainingPlanResponse, TrainingPlanSummary
)
from app.schemas.client.CompleteDayRequest import CompleteDayRequest
from app.services.client.training_plan import (
    CompleteWeekRequest,
    generate_training_plan_service,
    list_training_plans_service,
    get_training_plan_service,
    complete_day_service,
    complete_week_service,
    complete_training_plan_service,
    delete_training_plan_service,
    export_plan_pdf_service,
)

router = APIRouter(prefix="/training-plans", tags=["AI Training Plans"])

@router.post("/generate", response_model=TrainingPlanResponse,status_code=status.HTTP_201_CREATED, summary="Generate a personalised AI training plan (equipment-aware)",)
async def generate_training_plan( req: TrainingPlanRequest,current_user = Depends(require_client), db: AsyncSession = Depends(get_session),):
    return await generate_training_plan_service(req, int(current_user.userID), db)


@router.get("/", response_model=list[TrainingPlanSummary], summary="List all active training plans for the authenticated client",)
async def list_training_plans( current_user = Depends(require_client), db: AsyncSession = Depends(get_session),):
    return await list_training_plans_service(int(current_user.userID), db)


@router.get("/{plan_id}",response_model=TrainingPlanResponse, summary="Get full detail of a specific training plan",)
async def get_training_plan(plan_id: int, current_user = Depends(require_client), db: AsyncSession = Depends(get_session),):
    return await get_training_plan_service(plan_id, int(current_user.userID), db)




@router.post("/{plan_id}/complete-day",summary="Mark a day's workout as completed",)
async def complete_day(plan_id: int, request: CompleteDayRequest, current_user=Depends(require_client), db: AsyncSession = Depends(get_session),):
    return await complete_day_service(plan_id, request, int(current_user.userID), db)


@router.post("/{plan_id}/complete-week", summary="Mark a week's workouts as completed",)
async def complete_week( plan_id: int, request: CompleteWeekRequest, current_user=Depends(require_client), db: AsyncSession = Depends(get_session),):
    return await complete_week_service(plan_id, request, int(current_user.userID), db)


@router.patch("/{plan_id}/complete", response_model=TrainingPlanSummary, summary="Manually mark a training plan as completed",)
async def complete_training_plan(plan_id: int, current_user = Depends(require_client), db: AsyncSession = Depends(get_session),):
    return await complete_training_plan_service(plan_id, int(current_user.userID), db)


@router.delete("/{plan_id}", status_code=status.HTTP_204_NO_CONTENT, summary="Deactivate (soft-delete) a training plan",)
async def delete_training_plan( plan_id: int, current_user = Depends(require_client), db: AsyncSession = Depends(get_session),):
    return await delete_training_plan_service(plan_id, int(current_user.userID), db)


@router.get("/{plan_id}/pdf", summary="Download training plan as PDF",)
async def export_plan_pdf(plan_id: int, current_user = Depends(require_client), db: AsyncSession = Depends(get_session),):
    pdf_bytes = await export_plan_pdf_service(plan_id, int(current_user.userID), db)
    filename = f"training_plan_{plan_id}.pdf"
    return StreamingResponse( BytesIO(pdf_bytes), media_type="application/pdf", headers={"Content-Disposition": f"attachment; filename={filename}"},)