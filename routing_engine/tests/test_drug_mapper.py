import pytest
from app.utils.drug_mapper import get_category

def test_drug_mapper_known():
    drug = "amoxicillin"
    category = get_category(drug)
    print(f"\n[DRUG MAPPER] Known Drug: '{drug}'")
    print(f"[DRUG MAPPER] Mapped Category: '{category}'")
    assert category == "Antibiotic"

def test_drug_mapper_unknown():
    drug = "random_unknown_drug_123"
    category = get_category(drug)
    print(f"\n[DRUG MAPPER] Unknown Drug: '{drug}'")
    print(f"[DRUG MAPPER] Mapped Category: '{category}'")
    assert category == "General"
