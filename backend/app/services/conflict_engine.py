from typing import List, Dict, Tuple
from app.schemas import ConflictItem, ProductInteractionCheckResponse

# Rules matrix for active ingredients
# (Ingredient A, Ingredient B) -> (Severity, Reason, Recommendation)
CONFLICT_MATRIX: Dict[Tuple[str, str], Tuple[str, str, str]] = {
    ("retinol", "aha"): (
        "conflict",
        "Combining Retinoids with AHAs (like Glycolic or Lactic acid) significantly increases risk of skin barrier damage, erythema, and severe peeling.",
        "Alternate nights: Use Retinol on Night 1, and AHA on Night 2, or use AHA in the morning with sunscreen."
    ),
    ("retinol", "bha"): (
        "conflict",
        "Retinoids combined with Salicylic Acid (BHA) can strip the skin lipid barrier and trigger acute irritation.",
        "Use BHA in the morning or alternate days with Retinol."
    ),
    ("retinol", "benzoyl peroxide"): (
        "conflict",
        "Benzoyl Peroxide oxidizes tretinoin and retinol, deactivating both ingredients while severely drying the skin.",
        "Use Benzoyl Peroxide in the morning and Retinol strictly at night."
    ),
    ("retinol", "vitamin c"): (
        "caution",
        "Both are potent actives operating at different optimal pH levels. Layering them simultaneously can trigger stinging and redness.",
        "Apply Vitamin C in the morning under sunscreen for antioxidant protection, and Retinol at night."
    ),
    ("vitamin c", "aha"): (
        "caution",
        "Both are acidic formulations that can compromise skin barrier pH balance when layered together.",
        "Separate by morning and evening application."
    ),
    ("copper peptides", "vitamin c"): (
        "conflict",
        "Direct acids and pure Vitamin C can oxidize copper ions and break peptide bonds, rendering both ineffective.",
        "Do not layer copper peptides with direct acids or ascorbic acid."
    )
}

SYNONYMS: Dict[str, str] = {
    "retinoid": "retinol",
    "tretinoin": "retinol",
    "adapalene": "retinol",
    "glycolic acid": "aha",
    "lactic acid": "aha",
    "mandelic acid": "aha",
    "salicylic acid": "bha",
    "ascorbic acid": "vitamin c",
    "l-ascorbic acid": "vitamin c",
    "benzoyl peroxide": "benzoyl peroxide",
    "copper peptide": "copper peptides"
}

def normalize_ingredient(name: str) -> str:
    cleaned = name.strip().lower()
    for syn, canonical in SYNONYMS.items():
        if syn in cleaned:
            return canonical
    return cleaned

def check_ingredients_interaction(ingredients: List[str]) -> ProductInteractionCheckResponse:
    normalized = [normalize_ingredient(ing) for ing in ingredients if ing.strip()]
    unique_ingredients = list(set(normalized))
    
    conflicts: List[ConflictItem] = []
    has_high_conflict = False

    for i in range(len(unique_ingredients)):
        for j in range(i + 1, len(unique_ingredients)):
            ing_a = unique_ingredients[i]
            ing_b = unique_ingredients[j]

            match = CONFLICT_MATRIX.get((ing_a, ing_b)) or CONFLICT_MATRIX.get((ing_b, ing_a))
            if match:
                severity, reason, rec = match
                if severity == "conflict":
                    has_high_conflict = True
                conflicts.append(ConflictItem(
                    ingredient_a=ing_a.title(),
                    ingredient_b=ing_b.title(),
                    severity=severity,
                    reason=reason,
                    recommendation=rec
                ))

    if has_high_conflict:
        risk_level = "conflict"
        is_safe = False
        advice = "Critical conflict detected! Do not combine these ingredients in the same application time."
    elif conflicts:
        risk_level = "caution"
        is_safe = True
        advice = "Caution advised: These ingredients can be used in the same overall regimen if staggered between morning and evening."
    else:
        risk_level = "safe"
        is_safe = True
        advice = "No known ingredient conflicts detected in our clinical matrix. Always perform a 24-hour patch test before full application."

    return ProductInteractionCheckResponse(
        is_safe=is_safe,
        risk_level=risk_level,
        conflicts=conflicts,
        advice=advice
    )
