from typing import Dict, Any, Tuple
from app.core.config import settings

RED_FLAG_KEYWORDS = [
    # English
    "difficulty breathing", "trouble breathing", "shortness of breath",
    "face swelling", "facial swelling", "swollen lips", "swollen tongue",
    "severe pain", "rapidly spreading", "bleeding", "infection",
    "anaphylaxis", "blistering", "fever with rash", "pus",
    # Arabic
    "صعوبة تنفس", "ضيق تنفس", "تورم الوجه", "تورم الشفاه", "تورم اللسان",
    "ألم شديد", "انتشار سريع", "نزيف", "عدوى", "تقيح", "صديد",
    "حمى مع طفح", "حساسية حادة"
]

class AzureSafetyService:
    def __init__(self):
        self.is_live = settings.is_safety_live
        if self.is_live:
            from azure.ai.contentsafety import ContentSafetyClient
            from azure.core.credentials import AzureKeyCredential
            self.client = ContentSafetyClient(
                endpoint=settings.AZURE_CONTENT_SAFETY_ENDPOINT,
                credential=AzureKeyCredential(settings.AZURE_CONTENT_SAFETY_KEY)
            )

    def analyze_message_safety(self, message: str) -> Tuple[bool, str, Dict[str, Any]]:
        normalized = message.lower()
        matched_flags = [kw for kw in RED_FLAG_KEYWORDS if kw in normalized]

        if matched_flags:
            return (
                True,
                "Your symptoms may require immediate emergency medical attention. "
                "If you are experiencing severe swelling, difficulty breathing, or an acute spreading reaction, "
                "please contact emergency services or go to the nearest hospital immediately. "
                "قد تتطلب أعراضك رعاية طبية طارئة فورية. إذا كنت تعاني من صعوبة في التنفس أو تورم حاد، يرجى التوجه لأقرب طوارئ فوراً.",
                {"detected_red_flags": matched_flags, "escalation_action": "IMMEDIATE_EMERGENCY_CARE"}
            )

        if self.is_live:
            try:
                from azure.ai.contentsafety.models import AnalyzeTextOptions
                request = AnalyzeTextOptions(text=message)
                response = self.client.analyze_text(request)
                is_harmful = any(
                    item.severity > 2 for item in [
                        response.hate_result,
                        response.self_harm_result,
                        response.sexual_result,
                        response.violence_result
                    ] if item is not None
                )
                if is_harmful:
                    return (
                        True,
                        "Message content flagged by safety policy. Please maintain clinical and medical queries only.",
                        {"azure_safety_triggered": True}
                    )
            except Exception:
                pass

        return False, "", {}

azure_safety_service = AzureSafetyService()
