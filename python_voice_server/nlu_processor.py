import sqlite3
import json
import re
import os
from rapidfuzz import process, fuzz


def _is_number(token):
    """True for '2', '250', '1.5' etc. Plain str.isdigit() rejects decimals,
    which silently broke quantities like '1.5 kg' or '2.5 litre'."""
    try:
        float(token)
        return True
    except ValueError:
        return False


def _to_number(token):
    val = float(token)
    return int(val) if val.is_integer() else val


# Extensive Tamil to English grocery & vegetable translations for department stores
TAMIL_SYNONYMS = {
    # Dairy & Beverages
    'paal': 'milk', 'pal': 'milk', 'paalu': 'milk', 'milk': 'milk', 'curd': 'curd', 'thayir': 'curd',
    'ghee': 'ghee', 'nei': 'ghee', 'butter': 'butter', 'vennai': 'butter', 'paneer': 'paneer',
    'tea': 'tea', 'theyle': 'tea', 'coffee': 'coffee', 'kaapi': 'coffee',
    'boost': 'boost', 'horlicks': 'horlicks', 'bournvita': 'bournvita',

    # Fresh Vegetables & Greens (Full Tamil/English dictionary)
    'thakkali': 'tomato', 'tomato': 'tomato', 'thakkaliye': 'tomato',
    'vengayam': 'onion', 'vengaiyam': 'onion', 'onion': 'onion', 'periya vengayam': 'onion', 'bellary': 'onion',
    'chinna vengayam': 'small onion', 'sambhar vengayam': 'small onion', 'shallot': 'small onion', 'shallots': 'small onion',
    'urulai': 'potato', 'urulaikizhangu': 'potato', 'urulaikelangu': 'potato', 'potato': 'potato', 'alu': 'potato', 'aloo': 'potato',
    'carrot': 'carrot', 'kyarot': 'carrot', 'carret': 'carrot',
    'beans': 'beans', 'beens': 'beans', 'french beans': 'beans',
    'kathiri': 'brinjal', 'kathirikai': 'brinjal', 'kathirikka': 'brinjal', 'brinjal': 'brinjal', 'eggplant': 'brinjal',
    'vendaikaai': 'ladies finger', 'vendaikai': 'ladies finger', 'vendakka': 'ladies finger', 'ladies finger': 'ladies finger', 'okra': 'ladies finger', 'bhindi': 'ladies finger',
    'kose': 'cabbage', 'muttaikose': 'cabbage', 'muttaikose': 'cabbage', 'cabbage': 'cabbage', 'patta gobhi': 'cabbage',
    'cauliflower': 'cauliflower', 'kaaliflower': 'cauliflower', 'kobili': 'cauliflower',
    'beetroot': 'beetroot', 'beethroot': 'beetroot', 'beet': 'beetroot',
    'pachai milagai': 'green chilli', 'pacha milagai': 'green chilli', 'green chilli': 'green chilli', 'pachamolaga': 'green chilli',
    'inji': 'ginger', 'ginger': 'ginger', 'adrak': 'ginger',
    'poondu': 'garlic', 'poondhu': 'garlic', 'garlic': 'garlic', 'lahsun': 'garlic',
    'elumichai': 'lemon', 'elumichampazham': 'lemon', 'elumicham': 'lemon', 'lemon': 'lemon', 'nimbu': 'lemon',
    'kothamalli': 'coriander leaves', 'mallithazhai': 'coriander leaves', 'coriander leaves': 'coriander leaves',
    'karuveppilai': 'curry leaves', 'kariveppilai': 'curry leaves', 'curry leaves': 'curry leaves',
    'pudina': 'mint leaves', 'pudheena': 'mint leaves', 'mint': 'mint leaves',
    'keerai': 'spinach', 'palak': 'spinach', 'spinach': 'spinach', 'sirukeerai': 'spinach', 'araikeerai': 'spinach',
    'pavakkai': 'bitter gourd', 'paavakkai': 'bitter gourd', 'pavakka': 'bitter gourd', 'bitter gourd': 'bitter gourd',
    'suraikai': 'bottle gourd', 'sorakkai': 'bottle gourd', 'bottle gourd': 'bottle gourd',
    'capsicum': 'capsicum', 'kuda milagai': 'capsicum', 'kudamilagai': 'capsicum', 'bell pepper': 'capsicum',
    'mushroom': 'mushroom', 'kaalan': 'mushroom',
    'mullangi': 'radish', 'radish': 'radish', 'mooli': 'radish',
    'poosanikai': 'pumpkin', 'poosani': 'pumpkin', 'pumpkin': 'pumpkin', 'parangikai': 'pumpkin',
    'peerkangai': 'ridge gourd', 'peerkankai': 'ridge gourd', 'ridge gourd': 'ridge gourd',
    'pudalangai': 'snake gourd', 'snake gourd': 'snake gourd',
    'chow chow': 'chow chow', 'chayote': 'chow chow',
    'avaraikkai': 'broad beans', 'kothavarangai': 'cluster beans',
    'vazhaikkai': 'raw banana', 'vazhaithandu': 'banana stem', 'vazhaipoo': 'banana flower',

    # Grains, Flours & Dals
    'arisi': 'rice', 'rice': 'rice', 'pacharisi': 'raw rice', 'puzhungal': 'boiled rice',
    'maavu': 'flour', 'mavu': 'flour', 'atta': 'atta', 'godhumai': 'wheat', 'wheat': 'wheat',
    'maida': 'maida', 'rava': 'rava', 'sooji': 'rava', 'semiya': 'vermicelli',
    'paruppu': 'dal', 'dhal': 'dal', 'dal': 'dal', 'thuvaram': 'toor dal', 'toor': 'toor dal',
    'urad': 'urad dal', 'ulundhu': 'urad dal', 'moong': 'moong dal', 'paasi': 'moong dal',
    'channa': 'channa', 'kadalai': 'channa',

    # Oils & Essentials
    'ennai': 'oil', 'yenne': 'oil', 'ennay': 'oil', 'oil': 'oil', 'sunflower': 'sunflower oil',
    'nallenna': 'gingelly oil', 'kadugu': 'mustard', 'sesame': 'gingelly oil', 'coconut': 'coconut oil',
    'thengai': 'coconut oil', 'sugar': 'sugar', 'sarkara': 'sugar', 'cheeni': 'sugar',
    'nattu': 'country sugar', 'jaggery': 'jaggery', 'vellam': 'jaggery',
    'uppu': 'salt', 'salt': 'salt', 'rock': 'rock salt', 'indhuppu': 'rock salt',

    # Brands
    'aachi': 'aachi', 'achi': 'aachi', 'sakthi': 'sakthi', 'sakthi ': 'sakthi', 'shakthi': 'sakthi',
    'everest': 'everest', 'mdh': 'mdh', 'tata': 'tata', 'sampann': 'sampann',
    'aashirvaad': 'aashirvaad', 'ashirvad': 'aashirvaad', 'ashirvaad': 'aashirvaad',
    'fortune': 'fortune', 'gold winner': 'gold winner', 'gold': 'gold winner', 'sun pure': 'sun pure', 'sunpure': 'sun pure',
    'idhayam': 'idhayam', 'idhyam': 'idhayam', 'grb': 'grb',

    # Spices & Masalas
    'milagai': 'chilli', 'chilli': 'chilli', 'powder': 'powder', 'thool': 'powder', 'podi': 'powder',
    'manjal': 'turmeric powder', 'turmeric': 'turmeric powder', 'malli': 'coriander powder', 'coriander': 'coriander powder',
    'seeragam': 'cumin', 'cumin': 'cumin', 'milagu': 'pepper', 'pepper': 'pepper',
    'masala': 'masala', 'sambar': 'sambar powder', 'rasam': 'rasam powder',
    'garam': 'garam masala', 'chicken': 'chicken masala', 'mutton': 'mutton masala',

    # Snacks & Bakery
    'biscuit': 'biscuit', 'biskot': 'biscuit', 'cookies': 'cookies',
    'cake': 'cake', 'keku': 'cake', 'bread': 'bread', 'bun': 'bun',
    'rusk': 'rusk', 'chips': 'chips', 'mixture': 'mixture', 'murukku': 'murukku',
    'chocolate': 'chocolate', 'dairy milk': 'dairy milk', 'kitkat': 'kitkat', '5 star': '5 star',

    # Personal Care & Cleaning
    'soap': 'soap', 'sope': 'soap', 'shampoo': 'shampoo', 'sampo': 'shampoo',
    'paste': 'toothpaste', 'brush': 'toothbrush', 'detergent': 'detergent', 'surf': 'surf excel',
    'rin': 'rin', 'ariel': 'ariel', 'vim': 'vim', 'comfort': 'comfort',
    'muttai': 'egg', 'mutta': 'egg', 'motta': 'egg', 'egg': 'egg',
    'thanni': 'water', 'water': 'water'
}

# Spoken fractions & unit equivalents
FRACTION_MAP = {
    'kaal': 0.25, 'kaalu': 0.25, 'quarter': 0.25,
    'ara': 0.5, 'arai': 0.5, 'half': 0.5,
    'mukka': 0.75, 'mukkal': 0.75, 'mukaal': 0.75,
    'onara': 1.5, 'ondrarai': 1.5, 'onrarai': 1.5, 'ondre': 1.5,
    'rendara': 2.5, 'rendarai': 2.5, 'rende': 2.5,
    'moonara': 3.5, 'moonarai': 3.5,
    'naalara': 4.5, 'naalarai': 4.5,
    'anjara': 5.5, 'anjarai': 5.5
}

UNIT_EQUIVALENTS = {
    # Liquid measurements (Volume)
    ('ara', 'litre'): '500ml', ('arai', 'litre'): '500ml', ('ara', 'liter'): '500ml', ('arai', 'liter'): '500ml', ('half', 'litre'): '500ml',
    ('kaal', 'litre'): '250ml', ('kaalu', 'litre'): '250ml', ('kaal', 'liter'): '250ml', ('quarter', 'litre'): '250ml',
    ('mukka', 'litre'): '750ml', ('mukkal', 'litre'): '750ml', ('mukka', 'liter'): '750ml',
    ('onara', 'litre'): '1.5l', ('ondrarai', 'litre'): '1.5l', ('ondre', 'litre'): '1.5l',
    ('rendara', 'litre'): '2.5l', ('rendarai', 'litre'): '2.5l',
    # Solid measurements (Weight)
    ('ara', 'kilo'): '500g', ('arai', 'kilo'): '500g', ('ara', 'kg'): '500g', ('half', 'kg'): '500g',
    ('kaal', 'kilo'): '250g', ('kaalu', 'kilo'): '250g', ('kaal', 'kg'): '250g', ('quarter', 'kg'): '250g',
    ('mukka', 'kilo'): '750g', ('mukkal', 'kilo'): '750g', ('mukka', 'kg'): '750g',
    ('onara', 'kilo'): '1.5kg', ('ondrarai', 'kilo'): '1.5kg', ('ondre', 'kilo'): '1.5kg',
    ('rendara', 'kilo'): '2.5kg', ('rendarai', 'kilo'): '2.5kg'
}

# Tamil/English numbers dictionary supporting compound numbers (1 - 1000+)
NUMBER_MAP = {
    'onnu': 1, 'onno': 1, 'oru': 1, 'one': 1, '1': 1,
    'rendu': 2, 'rendo': 2, 'renda': 2, 'two': 2, '2': 2,
    'moonu': 3, 'moono': 3, 'three': 3, '3': 3,
    'naalu': 4, 'naalo': 4, 'four': 4, '4': 4,
    'anju': 5, 'anjo': 5, 'aindhu': 5, 'five': 5, '5': 5,
    'aaru': 6, 'aaro': 6, 'six': 6, '6': 6,
    'ezhu': 7, 'seven': 7, '7': 7,
    'ettu': 8, 'eight': 8, '8': 8,
    'ombadhu': 9, 'onbadhu': 9, 'nine': 9, '9': 9,
    'pathu': 10, 'ten': 10, '10': 10,
    'padhinonnu': 11, 'eleven': 11, '11': 11,
    'pannirendu': 12, 'twelve': 12, '12': 12,
    'padhimoonu': 13, 'thirteen': 13, '13': 13,
    'padhinaalu': 14, 'fourteen': 14, '14': 14,
    'padhinanju': 15, 'fifteen': 15, '15': 15,
    'padhinaaru': 16, 'sixteen': 16, '16': 16,
    'padhinezhu': 17, 'seventeen': 17, '17': 17,
    'padhinettu': 18, 'eighteen': 18, '18': 18,
    'pathombadhu': 19, 'nineteen': 19, '19': 19,
    'irubadhu': 20, 'twenty': 20, '20': 20,
    'irubathi': 20, 'iruvathi': 20,
    'muppadhu': 30, 'thirty': 30, '30': 30,
    'muppathi': 30,
    'naarpadhu': 40, 'forty': 40, '40': 40,
    'naarpathi': 40,
    'aimbadhu': 50, 'anbadhu': 50, 'fifty': 50, '50': 50,
    'aimbadhi': 50, 'anbadhi': 50,
    'aruvadhu': 60, 'sixty': 60, '60': 60,
    'aruvathi': 60,
    'ezhuvadhu': 70, 'seventy': 70, '70': 70,
    'ezhuvathi': 70,
    'enbadhu': 80, 'eighty': 80, '80': 80,
    'enbathi': 80,
    'thonnooru': 90, 'ninety': 90, '90': 90,
    'thonnoothi': 90,
    'nooru': 100, 'hundred': 100, '100': 100,
    'noothi': 100
}

class NLUProcessor:
    def __init__(self, db_path):
        self.db_path = db_path

    def get_products_from_db(self):
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("SELECT id, name, unit, unit_value, selling_price FROM products")
            rows = cursor.fetchall()
            conn.close()
            
            product_list = []
            for r in rows:
                p_id, name, unit, u_val, s_price = r
                label = name
                if u_val and u_val > 1.0 and unit:
                    unit_str = 'ml' if 'milli' in str(unit).lower() else ('g' if 'gram' in str(unit).lower() else str(unit))
                    label = f"{name} {int(u_val)}{unit_str}"
                product_list.append({
                    "id": p_id,
                    "name": name,
                    "unit": unit,
                    "unit_value": u_val or 1.0,
                    "selling_price": s_price or 0.0,
                    "search_label": label
                })
            return product_list
        except Exception as e:
            print(f"Database Error: {e}")
            return []

    def process_transcript(self, transcript):
        # Ignore empty or pure noise/filler transcripts (e.g. 'kudu', 'podu', 'um', 'ah', 'venum')
        cleaned_words = [w for w in transcript.lower().split() if w not in ['kudu', 'podu', 'vendum', 'venum', 'um', 'uh', 'hmm', 'theva', 'ok', 'sari', 'please', 'kudunga', 'podunga']]
        if not cleaned_words:
            return json.dumps({"items": [], "unrecognized": []})
            
        # Ignore transcripts that ONLY contain numbers or weights without any product word (e.g. '1kg', '1.5kg', '500g', '1', '2')
        non_qty_words = [w for w in cleaned_words if w not in NUMBER_MAP and not w.isdigit() and w not in ['kilo', 'kg', 'g', 'gram', 'grams', 'litre', 'liter', 'l', 'ml', '1kg', '2kg', '5kg', '500g', '250g', '100g', '50g', '1l', '2l', '500ml', '250ml', 'kaal', 'ara', 'arai', 'mukka', 'mukkal', 'half', 'quarter', 'rs', 'rupees', 'roobai', 'rubai', 'rooba']]
        if not non_qty_words:
            return json.dumps({"items": [], "unrecognized": []})
            
        print(f"NLU Processing input: '{transcript}'")
        products = self.get_products_from_db()
        
        if not products:
             return json.dumps({"items": [], "unrecognized": [{"text": transcript, "reason": "No products in DB"}]})

        search_labels = [p['search_label'] for p in products]
        label_to_product = {p['search_label']: p for p in products}

        # 1. Split into primary clauses by punctuation or clause conjunctions.
        # The period is only a clause boundary when it ISN'T a decimal point -
        # '[,.\n]+' used to split "1.5" into "1" and "5", corrupting any decimal
        # quantity (e.g. "oil 1.5l" silently became qty=5 instead of 1.5).
        raw_clauses = re.split(r'[,\n]+|(?<!\d)\.(?!\d)|\b(?:apram|and|kooda|aduthu|then|next)\b', transcript.lower())
        
        clusters = []
        delimiters = [
            'vendum', 'venum', 'um', 'uh', 'hmm', 'kudu', 'packet', 'pakket', 'theva', 'podu', 'piece', 'kattu', 'bunch', 'bundle',
            # Bare unit words: without these, a unit left unconsumed by the 2-word
            # fraction/gram rules (e.g. after 'arai'/'kaal' already matched) leaks into
            # curr_words as if it were part of the product name.
            'kilo', 'kg', 'litre', 'liter', 'l', 'ml', 'g', 'gram', 'grams',
        ]
        
        for clause in raw_clauses:
            clause = clause.strip()
            if not clause:
                continue

            # Whisper frequently glues a spoken number straight onto its unit with
            # no space (e.g. "2kilo", "500gram", "1kg", "250ml"). Every quantity
            # rule below expects the number and unit as separate tokens, so a glued
            # token like "2kilo" previously matched none of them and fell through
            # to become part of the product name instead - silently dropping the
            # quantity and defaulting to 1. Split them apart first.
            clause = re.sub(
                r'(\d+(?:\.\d+)?)(kilograms|kilogram|kilos|kilo|grams|gram|litres|litre|liters|liter|kgs|kg|ml|g|l)\b',
                r'\1 \2',
                clause,
            )

            words = clause.split()
            curr_words = []
            curr_qty = None
            target_amount = None
            
            # Check if clause contains fraction tokens like 'ara litre', 'kaal kilo', '100g' or rupee amounts '20 roobai'
            unit_override = None
            i = 0
            while i < len(words):
                w = words[i]
                
                # Check Rupee amount commands e.g. "20 roobaiku", "50 rupees", "10 rs", "pathu roobaiku"
                if i < len(words) - 1 and any(words[i+1].startswith(r) for r in ['rooba', 'roobai', 'rubai', 'rupaye', 'rupee', 'rupees', 'rs']) and (_is_number(w) or w in NUMBER_MAP):
                    rupee_val = float(w) if _is_number(w) else float(NUMBER_MAP[w])
                    target_amount = rupee_val
                    i += 2
                    continue
                # Check gram weights e.g. "100 gram", "250 gram", "500 gram"
                elif i < len(words) - 1 and words[i+1] in ['gram', 'g', 'grams'] and (_is_number(w) or w in NUMBER_MAP):
                    gram_val = _to_number(w) if _is_number(w) else NUMBER_MAP[w]
                    curr_qty = gram_val / 1000.0  # Convert to Kg units (e.g. 0.1, 0.25, 0.5)
                    unit_override = f"{gram_val}g"
                    i += 2
                    continue
                # Check ml volumes e.g. "100 ml", "250 ml", "500 ml"
                elif i < len(words) - 1 and words[i+1] == 'ml' and (_is_number(w) or w in NUMBER_MAP):
                    ml_val = _to_number(w) if _is_number(w) else NUMBER_MAP[w]
                    curr_qty = ml_val / 1000.0  # Convert to Litre units
                    unit_override = f"{ml_val}ml"
                    i += 2
                    continue
                # Check explicit litre amounts e.g. "1 litre", "1.5 litre"
                elif i < len(words) - 1 and words[i+1] in ['litre', 'liter', 'l'] and (_is_number(w) or w in NUMBER_MAP):
                    litre_val = _to_number(w) if _is_number(w) else NUMBER_MAP[w]
                    curr_qty = litre_val
                    # Expressed in ml so this flows through the same packaged-product
                    # (fixed-size bottle) correction as the ml branch above.
                    unit_override = f"{litre_val * 1000:g}ml"
                    i += 2
                    continue
                # Check 2-word fraction pairs: e.g. ('ara', 'kilo') -> 0.5 kg
                elif i < len(words) - 1 and (w, words[i+1]) in UNIT_EQUIVALENTS:
                    unit_override = UNIT_EQUIVALENTS[(w, words[i+1])]
                    curr_qty = FRACTION_MAP.get(w, 0.5)
                    i += 2
                    continue
                elif w in FRACTION_MAP:
                    curr_qty = FRACTION_MAP[w]
                    i += 1
                    continue
                elif _is_number(w) or w in NUMBER_MAP:
                    val = _to_number(w) if _is_number(w) else NUMBER_MAP[w]
                    if curr_words and (curr_qty is not None or target_amount is not None):
                        # Prefix number + previous item already finished (either it had an
                        # explicit qty, or its quantity was already fixed via a rupee amount
                        # like '20 roobaikku') -> this number starts the NEXT item, it must
                        # not be swallowed as a postfix qty for the item we just closed.
                        clusters.append((' '.join(curr_words), curr_qty if curr_qty is not None else 1.0, unit_override, target_amount))
                        curr_words = []
                        curr_qty = val
                        unit_override = None
                        target_amount = None
                    elif curr_words and curr_qty is None:
                        # Postfix number (e.g. 'tomato 2')
                        clusters.append((' '.join(curr_words), val, unit_override, target_amount))
                        curr_words = []
                        curr_qty = None
                        unit_override = None
                        target_amount = None
                    else:
                        # Compounding prefix numbers (e.g. 'irubathi' (20) + 'rendu' (2) -> 22)
                        curr_qty = (curr_qty + val) if (curr_qty is not None and isinstance(curr_qty, int) and isinstance(val, int)) else val
                    i += 1
                else:
                    if w not in delimiters:
                        curr_words.append(w)
                    i += 1
                    
            if curr_words:
                clusters.append((' '.join(curr_words), curr_qty if curr_qty is not None else 1.0, unit_override, target_amount))
            elif curr_qty is not None:
                # Standalone number clause
                if clusters and clusters[-1][1] == 1.0:
                    prev_text, _, prev_unit, prev_target = clusters.pop()
                    clusters.append((prev_text, curr_qty, prev_unit, prev_target))

        # Common Whisper phonetic transcription fixes for Indian accents & Tamil speech
        PHONETIC_FIXES = {
            'ball': 'paal', 'paul': 'paal', 'pol': 'paal', 'pal': 'paal',
            'call': 'kaal', 'cal': 'kaal', 'kall': 'kaal',
            'are': 'ara', 'arr': 'ara', 'arai': 'ara',
            'avin': 'aavin', 'aavan': 'aavin', 'aaven': 'aavin', "aavin's": 'aavin', "avin's": 'aavin',
            'kold': 'gold', 'gould': 'gold',
            'sampo': 'shampoo', 'sampoo': 'shampoo', 'shampu': 'shampoo',
            'biskut': 'biscuit', 'biscut': 'biscuit', 'biskit': 'biscuit', 'biskot': 'biscuit',
            'yenna': 'ennai', 'yenne': 'ennai', 'ennay': 'ennai',
            'thakali': 'thakkali', 'thakkalli': 'thakkali', 'takali': 'thakkali', 'tomoto': 'tomato',
            'vengayam': 'vengayam', 'vengaayam': 'vengayam', 'vengayum': 'vengayam',
            'urula': 'urulai', 'urulakilangu': 'urulaikizhangu', 'urulaikelangu': 'urulaikizhangu',
            'vendaika': 'vendaikai', 'vendakka': 'vendaikai', 'vendakkai': 'vendaikai',
            'kathiri': 'kathirikai', 'kathirika': 'kathirikai', 'brinjal': 'brinjal',
            'pudina': 'pudina', 'pudheena': 'pudina', 'koththamalli': 'kothamalli', 'kothumalli': 'kothamalli',
            'karuveppila': 'karuveppilai', 'karivepila': 'karuveppilai',
            'elumicha': 'elumichai', 'elumicham': 'elumichai',
            'pavakka': 'pavakkai', 'paavakka': 'pavakkai',
            'ondo': 'onnu', 'onno': 'onnu', 'rendo': 'rendu', 'moono': 'moonu', 'naalo': 'naalu', 'anjo': 'anju'
        }

        # 2. Match each cluster against database products
        matched_items = []
        unrecognized_items = []
        
        def calculate_match_score(query_str, candidate_str, unit_override_str=None):
            q_words = query_str.lower().split()
            c_words = candidate_str.lower().split()
            
            # Query token coverage
            matched_q = sum(1 for qw in q_words if any(fuzz.ratio(qw, cw) >= 78 for cw in c_words))
            q_cov = matched_q / len(q_words) if q_words else 0.0
            
            # Candidate token coverage
            matched_c = sum(1 for cw in c_words if any(fuzz.ratio(cw, qw) >= 78 for qw in q_words))
            c_cov = matched_c / len(c_words) if c_words else 0.0
            
            # F1 score for word overlap
            f1 = 2 * (q_cov * c_cov) / (q_cov + c_cov) if (q_cov + c_cov) > 0 else 0.0
            sort_ratio = fuzz.token_sort_ratio(query_str, candidate_str) / 100.0
            
            base_score = (f1 * 0.6 + sort_ratio * 0.4) * 100
            
            # High token match boost (e.g. all words of 'green chilli' match 'Green Chilli (Pachai Milagai)')
            if q_cov >= 0.99 and matched_q > 0:
                base_score = max(base_score, 90.0 + (sort_ratio * 10.0))
            elif q_cov >= 0.70 and matched_q > 0:
                base_score = max(base_score, 75.0 + (sort_ratio * 20.0))
                
            # If query has NO words in common with candidate, zero out
            if matched_q == 0:
                return 0.0
                
            # Exact pack size bonus (only if candidate product already matches majority of query words)
            if unit_override_str and unit_override_str.lower() in candidate_str.lower() and q_cov >= 0.70:
                base_score += 15.0
                
            return base_score
        
        # Multi-word phrase replacements first
        MULTIWORD_REPLACEMENTS = {
            # Spices & Masala Slangs
            'manja thool': 'turmeric powder',
            'manjal thool': 'turmeric powder',
            'manja podi': 'turmeric powder',
            'manjal podi': 'turmeric powder',
            'kothamalli thool': 'coriander powder',
            'kothamalli podi': 'coriander powder',
            'malli thool': 'coriander powder',
            'malli podi': 'coriander powder',
            'dhaniya thool': 'coriander powder',
            'milaga thool': 'chilli powder',
            'milagai thool': 'chilli powder',
            'milaga podi': 'chilli powder',
            'milagai podi': 'chilli powder',
            'vathal podi': 'chilli powder',
            'chicken masala': 'chicken masala',
            'chicken thool': 'chicken masala',
            'koli masala': 'chicken masala',
            'mutton masala': 'mutton masala',
            'mutton thool': 'mutton masala',
            'kari masala': 'mutton masala',
            'aatu kari masala': 'mutton masala',
            'fish fry masala': 'fish fry masala',
            'meen masala': 'fish fry masala',
            'meen varuval masala': 'fish fry masala',
            'biryani masala': 'biryani masala',
            'briyani masala': 'biryani masala',
            'biriyani masala': 'biryani masala',
            'garam masala': 'garam masala',
            'karam masala': 'garam masala',
            'idli podi': 'idli chilli powder',
            'idly podi': 'idli chilli powder',
            'idli milagai podi': 'idli chilli powder',
            'kuzhambu masala': 'kuzhambu chilli powder',
            'kulambu thool': 'kuzhambu chilli powder',
            'kulambu podi': 'kuzhambu chilli powder',
            'kuzhambu milagai thool': 'kuzhambu chilli powder',
            'rasam thool': 'rasam powder',
            'rasa thool': 'rasam powder',
            'rasa podi': 'rasam powder',
            'rasam podi': 'rasam powder',
            'sambar thool': 'sambar powder',
            'sambar podi': 'sambar powder',
            'sambhar thool': 'sambar powder',
            'sambhar podi': 'sambar powder',
            'milagu thool': 'black pepper powder',
            'milagu podi': 'black pepper powder',
            'seeraga thool': 'cumin powder',
            'seeraga podi': 'cumin powder',

            # Fresh Produce & Herbs
            'pachai milagai': 'green chilli',
            'pacha milagai': 'green chilli',
            'green chilli': 'green chilli',
            'inji poondu': 'ginger garlic',
            'coriander leaves': 'kothamalli',
            'curry leaves': 'karuveppilai',
            'mint leaves': 'pudina',
            'chinna vengayam': 'small onion',
            'sambhar vengayam': 'small onion',
            'periya vengayam': 'onion',

            # Whole Spices
            'kadugu': 'mustard seeds',
            'seeragam': 'cumin seeds',
            'jeeragam': 'cumin seeds',
            'sombu': 'fennel seeds',
            'vendhayam': 'fenugreek seeds',
            'venthayam': 'fenugreek seeds',
            'perungayam': 'asafoetida',
            'kaya thool': 'asafoetida',
            'black pepper': 'black pepper',
            'karuppu milagu': 'black pepper',

            # Dals & Grains
            'thuvaram paruppu': 'toor dal',
            'thovaram paruppu': 'toor dal',
            'sambhar paruppu': 'toor dal',
            'toor dal': 'toor dal',
            'ulundham paruppu': 'urad dal',
            'uluntham paruppu': 'urad dal',
            'ulunthu': 'urad dal',
            'urad dal': 'urad dal',
            'paasi paruppu': 'moong dal',
            'pasi paruppu': 'moong dal',
            'moong dal': 'moong dal',
            'kadalai paruppu': 'chana dal',
            'pottukadalai': 'pottukadalai',
            'porikadalai': 'pottukadalai',
            'kothumai maavu': 'wheat atta',
            'godhumai maavu': 'wheat atta',
            'maida maavu': 'maida flour',
            'puzhungal arisi': 'ponni boiled rice',
            'ponni arisi': 'ponni boiled rice',
            'pacharisi': 'raw rice',
            'pacha arisi': 'raw rice',

            # Oils & Sweets
            'nallennai': 'gingelly oil',
            'nallenna': 'gingelly oil',
            'kadalai ennai': 'groundnut oil',
            'kadala enna': 'groundnut oil',
            'thengai ennai': 'coconut oil',
            'thenga enna': 'coconut oil',
            'gold winner': 'gold winner',
            'sun pure': 'sun pure',
            'fortune oil': 'fortune',
            'manda vellam': 'jaggery',
            'nattu sarkarai': 'nattu sakkarai',
            'nattu sakkarai': 'nattu sakkarai',
            'kal uppu': 'crystal salt',
            'thool uppu': 'salt',
            'dairy milk': 'dairy milk',
            'white bread': 'white bread'
        }

        for item_raw_text, qty, unit_override, target_amount in clusters:
            if not item_raw_text.strip():
                continue
                
            # First normalize multi-word phrases
            norm_text = item_raw_text.lower()
            for k, v in MULTIWORD_REPLACEMENTS.items():
                if k in norm_text:
                    norm_text = norm_text.replace(k, v)
                    
            # Apply individual token normalization
            tokens = []
            for w in norm_text.split():
                if w in ['kilo', 'kg', 'litre', 'liter', 'l', 'ml', 'g', 'gram', 'grams', 'kattu', 'bunch', 'rooba', 'roobai', 'rubai', 'rupaye', 'rupees', 'rs']:
                    continue
                w_norm = PHONETIC_FIXES.get(w, w)
                w_trans = TAMIL_SYNONYMS.get(w_norm, w_norm)
                tokens.append(w_trans)
            
            query = " ".join(tokens).strip()
            if not query:
                continue
                
            best_match = None
            best_score = 0
            
            # Perform multi-strategy matching against database products
            for prod in products:
                prod_label = prod['search_label']
                score = calculate_match_score(query, prod_label, unit_override)
                if score > best_score:
                    best_score = score
                    best_match = prod
            
            # Acceptance threshold
            if best_match and best_score >= 45.0:
                final_qty = qty

                # A spoken gram/ml amount (e.g. "50 gram", "200 ml") was parsed assuming
                # the product is sold loose by weight/volume, so qty = amount/1000 (kg or
                # litre). That's wrong for a product sold as a fixed-size sealed pack where
                # selling_price is per PACK, not per kg/litre (e.g. a 50g masala packet or a
                # 200ml juice bottle) - "50 gram" there means "1 packet", and "100 gram"
                # means "2 packets", not a fractional slice of one packet. Re-derive the
                # spoken amount and, if the matched product is packaged (unit_value > 1 with
                # a matching gram/ml unit), convert to a pack count instead.
                if unit_override and (unit_override.endswith('g') or unit_override.endswith('ml')) and not unit_override.endswith('kg'):
                    is_ml = unit_override.endswith('ml')
                    try:
                        spoken_amount = float(unit_override[:-2] if is_ml else unit_override[:-1])
                    except ValueError:
                        spoken_amount = None
                    if spoken_amount:
                        pack_size = best_match['unit_value']
                        unit_str = str(best_match['unit'] or '').lower()
                        if is_ml:
                            is_packaged = pack_size and pack_size > 1 and ('milli' in unit_str or unit_str == 'ml')
                        else:
                            is_packaged = pack_size and pack_size > 1 and ('gram' in unit_str or unit_str == 'g')
                        if is_packaged:
                            final_qty = max(1, round(spoken_amount / pack_size))
                            print(f"[Pack Qty] '{unit_override}' of packaged '{best_match['name']}' (pack={pack_size}) -> Qty: {final_qty} pack(s)")

                # If a specific rupee amount was requested (e.g. 20 roobaiku thakkali), compute quantity dynamically
                if target_amount is not None and best_match['selling_price'] > 0:
                    raw_computed_qty = target_amount / best_match['selling_price']
                    final_qty = round(raw_computed_qty, 3)
                    print(f"[Rupee Target] Rs.{target_amount} of '{best_match['name']}' @ Rs.{best_match['selling_price']} -> Qty: {final_qty}")

                print(f"[Match Success] '{item_raw_text}' -> '{best_match['name']}' (Score: {best_score:.1f}, Qty: {final_qty})")
                matched_items.append({
                    "product": best_match['name'],
                    "product_id": best_match['id'],
                    "quantity": final_qty,
                    "unit": best_match['unit'],
                    "unit_value": best_match['unit_value']
                })
            else:
                print(f"[Match Miss] '{item_raw_text}' (Query: '{query}', Best: {best_match['name'] if best_match else 'None'} @ {best_score:.1f})")
                unrecognized_items.append({
                    "text": item_raw_text,
                    "reason": f"Best match {best_match['name'] if best_match else 'None'} scored only {best_score:.1f}"
                })
                
        return json.dumps({
            "items": matched_items,
            "unrecognized": unrecognized_items
        })
