from typing import List, Optional
from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.exceptions import EntityNotFoundException, DermaireException
from app.api.deps import get_current_user, record_audit
from app.models import User, Product
from app.schemas import (
    ProductCreate, ProductUpdate, ProductOut,
    ProductInteractionCheckRequest, ProductInteractionCheckResponse
)
from app.services.conflict_engine import check_ingredients_interaction

router = APIRouter(prefix="/products", tags=["Products & Routine Management"])

@router.get("", response_model=List[ProductOut])
def list_products(
    category: Optional[str] = None,
    status_filter: Optional[str] = Query(None, alias="status"),
    in_routine: Optional[bool] = None,
    in_experiment: Optional[bool] = None,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    query = db.query(Product).filter(Product.user_id == current_user.id)
    if category:
        query = query.filter(Product.category == category)
    if status_filter:
        query = query.filter(Product.status == status_filter)
    if in_routine is not None:
        query = query.filter(Product.in_routine == in_routine)
    if in_experiment is not None:
        query = query.filter(Product.in_experiment == in_experiment)
    return query.order_by(Product.created_at.desc()).all()

@router.post("", response_model=ProductOut, status_code=status.HTTP_201_CREATED)
def create_product(
    payload: ProductCreate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    existing = db.query(Product).filter(
        Product.user_id == current_user.id,
        Product.name.ilike(payload.name)
    ).first()
    if existing:
        raise DermaireException(
            message=f"A product named '{payload.name}' already exists in your routine or library.",
            error_code="PRODUCT_DUPLICATE_NAME",
            status_code=status.HTTP_409_CONFLICT
        )

    # Automatic safety check: Compare new product ingredients with existing active products in routine
    if payload.active_ingredients and payload.in_routine:
        active_products = db.query(Product).filter(
            Product.user_id == current_user.id,
            Product.in_routine == True,
            Product.status == "active"
        ).all()
        routine_ingredients = []
        for p in active_products:
            routine_ingredients.extend(p.active_ingredients or [])
        
        all_ingredients = list(set(routine_ingredients + payload.active_ingredients))
        if len(all_ingredients) >= 2:
            interaction = check_ingredients_interaction(all_ingredients)
            # We record warning in logs if high risk
            if interaction.risk_level == "conflict":
                record_audit(db, current_user.id, "PRODUCT_INTERACTION_WARNING", "products", {
                    "new_product": payload.name,
                    "conflicts": [c.model_dump() for c in interaction.conflicts]
                })

    product = Product(
        user_id=current_user.id,
        name=payload.name,
        brand=payload.brand,
        category=payload.category,
        product_type=payload.product_type,
        active_ingredients=payload.active_ingredients,
        skin_concerns=payload.skin_concerns,
        usage_instructions=payload.usage_instructions,
        frequency_per_week=payload.frequency_per_week,
        time_of_use=payload.time_of_use,
        status="active",
        tags=payload.tags,
        in_routine=payload.in_routine,
        in_experiment=payload.in_experiment,
        notes=payload.notes
    )
    db.add(product)

    # Award gamification token for registering a product
    current_user.tokens_balance += 1

    db.commit()
    db.refresh(product)

    record_audit(db, current_user.id, "PRODUCT_CREATED", "products", {"product_id": product.id, "name": product.name})
    return product

@router.get("/{product_id}", response_model=ProductOut)
def get_product(
    product_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    product = db.query(Product).filter(
        Product.id == product_id,
        Product.user_id == current_user.id
    ).first()
    if not product:
        raise EntityNotFoundException("Product", product_id)
    return product

@router.patch("/{product_id}", response_model=ProductOut)
def update_product(
    product_id: str,
    payload: ProductUpdate,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    product = db.query(Product).filter(
        Product.id == product_id,
        Product.user_id == current_user.id
    ).first()
    if not product:
        raise EntityNotFoundException("Product", product_id)

    data = payload.model_dump(exclude_unset=True)
    for key, value in data.items():
        setattr(product, key, value)

    db.commit()
    db.refresh(product)
    record_audit(db, current_user.id, "PRODUCT_UPDATED", "products", {"product_id": product.id})
    return product

@router.delete("/{product_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_product(
    product_id: str,
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    product = db.query(Product).filter(
        Product.id == product_id,
        Product.user_id == current_user.id
    ).first()
    if not product:
        raise EntityNotFoundException("Product", product_id)

    if product.in_experiment:
        raise DermaireException(
            message="Cannot delete a product currently linked to an active skin experiment. Archive or finish the experiment first.",
            error_code="PRODUCT_IN_ACTIVE_EXPERIMENT",
            status_code=status.HTTP_409_CONFLICT
        )

    db.delete(product)
    db.commit()
    record_audit(db, current_user.id, "PRODUCT_DELETED", "products", {"product_id": product_id})

@router.post("/check-interactions", response_model=ProductInteractionCheckResponse)
def check_interactions_endpoint(payload: ProductInteractionCheckRequest):
    return check_ingredients_interaction(payload.ingredients)
