from io import BytesIO
from textwrap import wrap
from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from app.config.db import get_db
from app.models.consultation import (
    ConsultationCreate,
    ConsultationOut,
    ConsultationReply,
    DoctorOut,
)
from app.repository.consultation import ConsultationRepo, DoctorRepo
from app.repository.dependencies import get_current_doctor_user, get_current_standard_user
from app.tables.users import User

consultationRouter = APIRouter(prefix="/consultations", tags=["Consultations"])


def _pdf_escape(value: str) -> str:
    return value.replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")


def _build_simple_pdf(title: str, lines: list[str]) -> bytes:
    stream_lines = ["BT", "/F1 12 Tf", "1 0 0 1 50 780 Tm", f"({_pdf_escape(title)}) Tj"]
    y_step = 16
    current_y = 760

    for line in lines:
        for part in wrap(line, width=88) or [""]:
            escaped = _pdf_escape(part)
            stream_lines.append(f"1 0 0 1 50 {current_y} Tm")
            stream_lines.append(f"({escaped}) Tj")
            current_y -= y_step
            if current_y < 60:
                stream_lines.append("1 0 0 1 50 60 Tm")
                stream_lines.append("(Content continues in API data if PDF page limit is reached.) Tj")
                stream_lines.append("ET")
                return _finish_pdf("\n".join(stream_lines))
    stream_lines.append("ET")
    return _finish_pdf("\n".join(stream_lines))


def _finish_pdf(content_stream: str) -> bytes:
    content = content_stream.encode("latin-1", errors="replace")
    objects = [
        b"<< /Type /Catalog /Pages 2 0 R >>",
        b"<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
        b"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>",
        b"<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>",
        b"<< /Length " + str(len(content)).encode("ascii") + b" >>\nstream\n" + content + b"\nendstream",
    ]
    pdf = BytesIO()
    pdf.write(b"%PDF-1.4\n")
    offsets = [0]
    for idx, obj in enumerate(objects, start=1):
        offsets.append(pdf.tell())
        pdf.write(f"{idx} 0 obj\n".encode("ascii"))
        pdf.write(obj)
        pdf.write(b"\nendobj\n")
    xref_offset = pdf.tell()
    pdf.write(f"xref\n0 {len(objects) + 1}\n".encode("ascii"))
    pdf.write(b"0000000000 65535 f \n")
    for offset in offsets[1:]:
        pdf.write(f"{offset:010d} 00000 n \n".encode("ascii"))
    pdf.write(
        f"trailer << /Size {len(objects) + 1} /Root 1 0 R >>\nstartxref\n{xref_offset}\n%%EOF".encode("ascii")
    )
    return pdf.getvalue()


@consultationRouter.get("/doctors", response_model=list[DoctorOut])
def browse_doctors(db: Session = Depends(get_db)):
    return DoctorRepo.list_doctors(db)


@consultationRouter.get("/doctors/{doctor_id}", response_model=DoctorOut)
def get_doctor(doctor_id: int, db: Session = Depends(get_db)):
    doctor = DoctorRepo.get_doctor(db, doctor_id)
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    return doctor


@consultationRouter.post("", response_model=ConsultationOut)
def request_consultation(
    req: ConsultationCreate,
    user: User = Depends(get_current_standard_user),
    db: Session = Depends(get_db),
):
    doctor = DoctorRepo.get_doctor(db, req.doctor_id)
    if not doctor:
        raise HTTPException(status_code=404, detail="Doctor not found")
    return ConsultationRepo.create(db, user.id, req.doctor_id, req.condition_description)


@consultationRouter.get("/mine", response_model=list[ConsultationOut])
def list_my_consultations(
    user: User = Depends(get_current_standard_user),
    db: Session = Depends(get_db),
):
    return ConsultationRepo.list_for_user(db, user.id)


@consultationRouter.get("/doctor/inbox", response_model=list[ConsultationOut])
def list_doctor_consultations(
    doctor: User = Depends(get_current_doctor_user),
    db: Session = Depends(get_db),
):
    return ConsultationRepo.list_for_doctor(db, doctor.id)


@consultationRouter.post("/{consultation_id}/reply", response_model=ConsultationOut)
def reply_to_consultation(
    consultation_id: int,
    req: ConsultationReply,
    doctor: User = Depends(get_current_doctor_user),
    db: Session = Depends(get_db),
):
    consultation = ConsultationRepo.get_for_doctor(db, consultation_id, doctor.id)
    if not consultation:
        raise HTTPException(status_code=404, detail="Consultation not found")
    return ConsultationRepo.reply(db, consultation, req.doctor_reply)


@consultationRouter.get("/reports/export")
def export_my_reports(
    user: User = Depends(get_current_standard_user),
    db: Session = Depends(get_db),
):
    consultations = ConsultationRepo.list_for_user(db, user.id)
    lines = [
        f"Patient: {user.first_name or ''} {user.last_name or ''}".strip(),
        f"Email: {user.email}",
        "",
    ]
    for item in consultations:
        lines.extend([
            f"Report #{item.id}",
            f"Doctor ID: {item.doctor_id}",
            f"Status: {item.status.value}",
            f"Created at: {item.created_at}",
            f"Condition: {item.condition_description}",
            f"Doctor reply: {item.doctor_reply or 'No reply yet'}",
            "",
        ])

    pdf_bytes = _build_simple_pdf("Healthmate Consultation Reports", lines)
    return StreamingResponse(
        BytesIO(pdf_bytes),
        media_type="application/pdf",
        headers={"Content-Disposition": "attachment; filename=consultation-reports.pdf"},
    )
