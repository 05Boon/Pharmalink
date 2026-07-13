DRUG_CATEGORIES = {
    "amoxicillin": "Antibiotic",
    "azithromycin": "Antibiotic",
    "ciprofloxacin": "Antibiotic",
    "ceftriaxone": "Antibiotic",
    "metronidazole": "Antibiotic",
    "paracetamol": "Antipyretic/Analgesic",
    "ibuprofen": "Antipyretic/Analgesic",
    "diclofenac": "Antipyretic/Analgesic",
    "aspirin": "Antipyretic/Analgesic",
    "artemether": "Antimalarial",
    "lumefantrine": "Antimalarial",
    "artesunate": "Antimalarial",
    "quinine": "Antimalarial",
    "loperamide": "Antidiarrheal",
    "ors": "Antidiarrheal",
    "zinc sulfate": "Antidiarrheal",
    "omeprazole": "Gastrointestinal",
    "cetirizine": "Antihistamine",
    "loratadine": "Antihistamine",
    "salbutamol": "Respiratory",
}

def get_category(drug_name: str) -> str:
    """
    Returns the category for a given drug name.
    Performs a case-insensitive lookup. Defaults to "General".
    """
    if not drug_name:
        return "General"
    
    clean_name = drug_name.strip().lower()
    
    if clean_name in DRUG_CATEGORIES:
        return DRUG_CATEGORIES[clean_name]
    
    for key, category in DRUG_CATEGORIES.items():
        if key in clean_name:
            return category
            
    return "General"
