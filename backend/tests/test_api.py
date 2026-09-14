import pytest
from fastapi import status

def test_health_check(client):
    res = client.get("/health")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "healthy"
    assert "azure_services" in data

def test_auth_and_safety_rejection(client):
    # Register without accepting medical safety should fail with 400
    res = client.post("/api/v1/auth/register", json={
        "email": "test_patient@dermaire.com",
        "password": "StrongPass123!",
        "full_name": "Salma Test",
        "role": "patient",
        "accept_safety": False
    })
    assert res.status_code == 400
    assert res.json()["errorCode"] == "SAFETY_ACCEPTANCE_REQUIRED"

    # Register with safety accepted should succeed with 201
    res = client.post("/api/v1/auth/register", json={
        "email": "test_patient@dermaire.com",
        "password": "StrongPass123!",
        "full_name": "Salma Test",
        "role": "patient",
        "accept_safety": True
    })
    assert res.status_code == 201
    token_data = res.json()
    assert "access_token" in token_data
    assert token_data["role"] == "patient"

def test_products_and_conflict_check(client):
    # Login patient
    login_res = client.post("/api/v1/auth/login", json={
        "email": "test_patient@dermaire.com",
        "password": "StrongPass123!"
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Standalone conflict check: Retinol + Glycolic Acid (AHA)
    conflict_res = client.post("/api/v1/products/check-interactions", json={
        "ingredients": ["Retinol", "Glycolic Acid"]
    })
    assert conflict_res.status_code == 200
    c_data = conflict_res.json()
    assert c_data["is_safe"] is False
    assert c_data["risk_level"] == "conflict"
    assert len(c_data["conflicts"]) > 0

    # Add product Product X
    prod_res = client.post("/api/v1/products", headers=headers, json={
        "name": "Product X",
        "brand": "Dermaire Lab",
        "category": "treatment",
        "active_ingredients": ["Retinol 0.3%"],
        "usage_instructions": "Apply 2 drops at night",
        "frequency_per_week": 3,
        "time_of_use": "evening",
        "in_routine": True
    })
    assert prod_res.status_code == 201
    p_data = prod_res.json()
    assert p_data["name"] == "Product X"

    # Adding duplicate should fail with 409
    dup_res = client.post("/api/v1/products", headers=headers, json={
        "name": "Product X",
        "category": "treatment"
    })
    assert dup_res.status_code == 409
    assert dup_res.json()["errorCode"] == "PRODUCT_DUPLICATE_NAME"

def test_experiment_and_checkin_flow(client):
    login_res = client.post("/api/v1/auth/login", json={
        "email": "test_patient@dermaire.com",
        "password": "StrongPass123!"
    })
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Start 28-day experiment
    exp_res = client.post("/api/v1/experiments", headers=headers, json={
        "target_days": 28,
        "primary_concern": "texture"
    })
    assert exp_res.status_code == 201
    exp_id = exp_res.json()["id"]

    # Submit check-in
    checkin_res = client.post("/api/v1/checkins", headers=headers, data={
        "time_of_day": "Morning",
        "hydration_score": 82.0,
        "texture_score": 76.0,
        "redness_score": 18.0,
        "experiment_id": exp_id,
        "notes": "Skin feels hydrated and calm today."
    })
    assert checkin_res.status_code == 201
    assert checkin_res.json()["tokens_earned"] == 1

def test_doctor_qr_and_notes(client):
    # Register Doctor
    doc_res = client.post("/api/v1/auth/register", json={
        "email": "doctor_ahmed@dermaire.com",
        "password": "DoctorPass2027!",
        "full_name": "Dr. Ahmed Mostafa",
        "role": "doctor",
        "accept_safety": True
    })
    doc_token = doc_res.json()["access_token"]
    doc_headers = {"Authorization": f"Bearer {doc_token}"}

    # Patient generates QR
    patient_res = client.post("/api/v1/auth/login", json={
        "email": "test_patient@dermaire.com",
        "password": "StrongPass123!"
    })
    patient_token = patient_res.json()["access_token"]
    patient_headers = {"Authorization": f"Bearer {patient_token}"}
    patient_id = patient_res.json()["user_id"]

    qr_res = client.post("/api/v1/doctor/generate-qr", headers=patient_headers)
    assert qr_res.status_code == 200
    access_token = qr_res.json()["access_token"]

    # Doctor claims QR
    claim_res = client.post("/api/v1/doctor/claim", headers=doc_headers, json={
        "access_token": access_token
    })
    assert claim_res.status_code == 200

    # Doctor lists authorized patients
    patients_list = client.get("/api/v1/doctor/patients", headers=doc_headers)
    assert patients_list.status_code == 200
    assert any(p["patient_id"] == patient_id for p in patients_list.json())

    # Doctor adds append-only note
    note_res = client.post(f"/api/v1/doctor/patients/{patient_id}/notes", headers=doc_headers, json={
        "content": "Patient shows marked reduction in erythema. Continue Retinol titration.",
        "priority": "routine",
        "follow_up": "Next Week"
    })
    assert note_res.status_code == 201

def test_ai_chat_red_flag_escalation(client):
    patient_res = client.post("/api/v1/auth/login", json={
        "email": "test_patient@dermaire.com",
        "password": "StrongPass123!"
    })
    headers = {"Authorization": f"Bearer {patient_res.json()["access_token"]}"}

    # English Emergency Red Flag: trouble breathing & face swelling
    emergency_en = client.post("/api/v1/chat", headers=headers, json={
        "message": "I applied the serum and now I have trouble breathing and face swelling!"
    })
    assert emergency_en.status_code == 200
    data_en = emergency_en.json()
    assert data_en["escalation_triggered"] is True
    assert data_en["kind"] == "escalation"

    # Arabic Emergency Red Flag: تورم الوجه وضيق تنفس
    emergency_ar = client.post("/api/v1/chat", headers=headers, json={
        "message": "عندي تورم الوجه وضيق تنفس بعد الكريم الجديد"
    })
    assert emergency_ar.status_code == 200
    data_ar = emergency_ar.json()
    assert data_ar["escalation_triggered"] is True
    assert data_ar["kind"] == "escalation"

    # Safe educational question
    safe_q = client.post("/api/v1/chat", headers=headers, json={
        "message": "How do I track my skin baseline?"
    })
    assert safe_q.status_code == 200
    assert safe_q.json()["escalation_triggered"] is False
