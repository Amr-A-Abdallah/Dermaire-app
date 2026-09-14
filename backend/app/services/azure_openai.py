from typing import Dict, Any, Tuple
from app.core.config import settings
from app.services.azure_safety import azure_safety_service

CLINICAL_SYSTEM_PROMPT = """
You are Dermaire's Personal Skin Lab Assistant, an evidence-based clinical guide developed for the Microsoft Imagine Cup 2027.
Your primary role is to educate users on skincare science, ingredient interactions, barrier health, and self-experimentation tracking.

STRICT MEDICAL GUIDELINES:
1. You are NOT a doctor and CANNOT diagnose conditions (such as eczema, psoriasis, or melanoma) or prescribe prescription medications.
2. If the user presents severe symptoms (swelling, breathing difficulty, extreme pain, spreading rash, fever), immediately escalate to emergency services.
3. Recommend patch-testing new products and introducing one active ingredient at a time.
4. Encourage consulting a qualified dermatologist for definitive medical treatments.
5. Support both English and Arabic queries with empathetic, scientific precision.
"""

class AzureOpenAIService:
    def __init__(self):
        self.is_live = settings.is_openai_live
        if self.is_live:
            from openai import AzureOpenAI
            self.client = AzureOpenAI(
                azure_endpoint=settings.AZURE_OPENAI_ENDPOINT,
                api_key=settings.AZURE_OPENAI_API_KEY,
                api_version=settings.AZURE_OPENAI_API_VERSION
            )

    def generate_chat_reply(self, user_message: str) -> Tuple[str, str, bool, Dict[str, Any]]:
        # 1. First Pass: Azure Content Safety & Red-Flag Escalation Check
        flagged, escalation_msg, details = azure_safety_service.analyze_message_safety(user_message)
        if flagged:
            return escalation_msg, "escalation", True, details

        # 2. Second Pass: Azure OpenAI GPT-4o (if live)
        if self.is_live:
            try:
                response = self.client.chat.completions.create(
                    model=settings.AZURE_OPENAI_DEPLOYMENT_NAME,
                    messages=[
                        {"role": "system", "content": CLINICAL_SYSTEM_PROMPT},
                        {"role": "user", "content": user_message}
                    ],
                    temperature=0.3,
                    max_tokens=450
                )
                reply_text = response.choices[0].message.content or ""
                return reply_text, "education", False, {"source": "Azure OpenAI GPT-4o"}
            except Exception as e:
                # Log and fallback gracefully
                pass

        # 3. Third Pass: Safe Deterministic Skincare Guide (Offline / Fallback Mode)
        lower_msg = user_message.lower()
        if any(w in lower_msg for w in ["measurement", "قياس", "score", "baseline"]):
            reply = (
                "Skin measurements track changes compared to your personal baseline. "
                "They reflect relative surface hydration, texture smoothness, and redness estimates. "
                "القياسات في ديرماير تقارن تغيرات بشرتك بخط الأساس الشخصي وتساعدك في معرفة تأثير المنتجات بدقة."
            )
            kind = "education"
        elif any(w in lower_msg for w in ["retinol", "ريتينول", "aha", "bha", "conflict", "تضارب", "active"]):
            reply = (
                "Active ingredients require gradual introduction. Avoid combining potent exfoliants (AHAs/BHAs) "
                "with Retinoids in the same evening session to prevent compromising your lipid barrier. "
                "المكونات الفعالة مثل الريتينول والأحماض تتطلب تدرجاً. لا تخلط الريتينول مع المقشرات في نفس المساء حمايةً لحاجز البشرة."
            )
            kind = "education"
        elif any(w in lower_msg for w in ["product", "منتج", "routine", "روتين"]):
            reply = (
                "When introducing a new product to your routine, patch test on the inner forearm for 24-48 hours. "
                "Change only one variable at a time so you can accurately isolate cause and effect in your skin experiment."
            )
            kind = "education"
        else:
            reply = (
                "I am Dermaire's Skin Lab Assistant. I can explain product layering, active ingredients, and experiment tracking. "
                "I do not provide medical diagnoses or prescriptions. For personal clinical decisions, please consult your dermatologist. "
                "أنا مساعد ديرماير لمختبر البشرة. يمكنني إرشادك في روتين العناية وتعارض المكونات وتتبع التجارب بأمان."
            )
            kind = "uncertainty"

        return reply, kind, False, {"source": "Dermaire Safe Clinical Rules (Offline Mode)"}

azure_openai_service = AzureOpenAIService()
