# 🌿 Dermaire Personal Skin Lab — Backend API
### 🏆 Microsoft Imagine Cup 2027 Edition

An evidence-based, clinical-grade personal skincare laboratory backend built on **100% Microsoft Azure Cloud & Azure AI** ecosystem with Python FastAPI.

---

## 🌟 Architecture & Microsoft Azure Integration

| Azure Cloud Service | Clinical & Technical Use Case in Dermaire |
|---|---|
| **Azure Blob Storage** | Secure storage for daily skin check-in photos and clinical reports. Images are accessible solely through **ephemeral, encrypted Shared Access Signature (SAS) tokens** that expire automatically. |
| **Azure AI Vision (Image Analysis 4.0)** | Extracts quantitative visual skin indicators (Erythema / Redness ratio, surface roughness/texture variance, and lesion tracking) against the patient's baseline. |
| **Azure OpenAI Service (GPT-4o)** | Powers the interactive **Skin Assistant**, educating users on ingredient compatibility, barrier health, and routine design while enforcing strict non-diagnostic medical disclaimers. |
| **Azure AI Content Safety** | Real-time safety guardrail and red-flag escalation engine (English & Arabic) that detects clinical emergencies (anaphylaxis, facial swelling, breathing distress) and triggers emergency guidance. |
| **Azure Database for PostgreSQL** | Relational transactional storage for patient health journeys, active routine products, 28-day experiments, and append-only clinical notes. |
| **Azure Key Vault** | Enterprise protection for JWT keys, database secrets, and Azure API credentials. |
| **Azure Container Apps / App Service** | Scalable containerized microservice hosting with HTTPS and CI/CD integration. |

---

## 🚀 Quick Start (Local Run)

The backend features an intelligent **Zero-Setup Fallback Mode**: it operates seamlessly out of the box with local SQLite and mock AI services for offline testing and development, and automatically transitions to live Azure services once credentials are provided in .env.

### 1. Activate Environment & Run
`ash
# Activate virtual environment
.venv\Scripts\activate

# Run FastAPI with Uvicorn
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
`

### 2. Interactive API Documentation (Swagger)
- **Swagger UI:** http://localhost:8000/docs
- **ReDoc:** http://localhost:8000/redoc
- **Health Check:** http://localhost:8000/health

---

## 🧪 Automated Test Suite

To run the automated test suite covering authentication, product interactions, clinical experiments, doctor portal QR claims, and AI safety red flags:

`ash
python -m pytest -v
`

---

## 🐳 Docker Deployment

`ash
docker-compose up --build
`
