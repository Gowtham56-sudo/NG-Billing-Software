import sqlite3
import json
import re
import os
from rapidfuzz import process, fuzz

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

    # Spices & Masalas
    'milagai': 'chilli', 'chilli': 'chilli', 'powder': 'powder', 'thool': 'powder',
    'manjal': 'turmeric', 'turmeric': 'turmeric', 'malli': 'coriander', 'coriander': 'coriander',
    'seeragam': 'cumin', 'cumin': 'cumin', 'milagu': 'pepper', 'pepper': 'pepper',
    'masala': 'masala', 'sambar': 'sambar powder', 'rasam': 'rasam powder',

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
        self.gemini_model = None
        try:
            from dotenv import load_dotenv
            import google.generativeai as genai
            load_dotenv()
            api_key = os.getenv("GEMINI_API_KEY")
            if api_key:
                genai.configure(api_key=api_key)
                self.gemini_model = genai.GenerativeModel('gemini-3.5-flash-lite')
        except Exception as e:
            print("Gemini init notice:", e)

    def get_products_from_db(self):
        try:
            conn = sqlite3.connect(self.db_path)
            cursor = conn.cursor()
            cursor.execute("SELECT id, name, unit, unit_value FROM products")
            rows = cursor.fetchall()
            conn.close()
            
            product_list = []
            for r in rows:
                p_id, name, unit, u_val = r
                label = name
                if u_val and u_val > 1.0 and unit:
                    unit_str = 'ml' if 'milli' in str(unit).lower() else ('g' if 'gram' in str(unit).lower() else str(unit))
                    label = f"{name} {int(u_val)}{unit_str}"
                product_list.append({
                    "id": p_id,
                    "name": name,
                    "unit": unit,
                    "unit_value": u_val or 1.0,
                    "search_label": label
                })
            return product_list
        except Exception as e:
            print(f"Database Error: {e}")
            return []

    def process_transcript(self, transcript):
        if not transcript or not transcript.strip():
            return json.dumps({"items": [], "unrecognized": []})
            
        print(f"NLU Processing input: '{transcript}'")
        products = self.get_products_from_db()
        
        if not products:
             return json.dumps({"items": [], "unrecognized": [{"text": transcript, "reason": "No products in DB"}]})

        search_labels = [p['search_label'] for p in products]
        label_to_product = {p['search_label']: p for p in products}

        # 1. Split into primary clauses by punctuation or clause conjunctions
        raw_clauses = re.split(r'[,.\n]+|\b(?:apram|and|kooda|aduthu|then|next)\b', transcript.lower())
        
        clusters = []
        delimiters = ['vendum', 'venum', 'um', 'uh', 'hmm', 'kudu', 'packet', 'pakket', 'theva', 'podu', 'piece', 'kattu', 'bunch', 'bundle']
        
        for clause in raw_clauses:
            clause = clause.strip()
            if not clause:
                continue
                
            words = clause.split()
            curr_words = []
            curr_qty = None
            
            # Check if clause contains fraction tokens like 'ara litre', 'kaal kilo', '100g'
            unit_override = None
            i = 0
            while i < len(words):
                w = words[i]
                
                # Check gram weights e.g. "100 gram", "250 gram", "500 gram"
                if i < len(words) - 1 and words[i+1] in ['gram', 'g', 'grams'] and (w.isdigit() or w in NUMBER_MAP):
                    gram_val = int(w) if w.isdigit() else NUMBER_MAP[w]
                    curr_qty = gram_val / 1000.0  # Convert to Kg units (e.g. 0.1, 0.25, 0.5)
                    unit_override = f"{gram_val}g"
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
                elif w.isdigit() or w in NUMBER_MAP:
                    val = int(w) if w.isdigit() else NUMBER_MAP[w]
                    if curr_words and curr_qty is not None:
                        # Prefix number + product finished, starting next item with new number
                        clusters.append((' '.join(curr_words), curr_qty, unit_override))
                        curr_words = []
                        curr_qty = val
                        unit_override = None
                    elif curr_words and curr_qty is None:
                        # Postfix number (e.g. 'tomato 2')
                        clusters.append((' '.join(curr_words), val, unit_override))
                        curr_words = []
                        curr_qty = None
                        unit_override = None
                    else:
                        # Compounding prefix numbers (e.g. 'irubathi' (20) + 'rendu' (2) -> 22)
                        curr_qty = (curr_qty + val) if (curr_qty is not None and isinstance(curr_qty, int) and isinstance(val, int)) else val
                    i += 1
                else:
                    if w not in delimiters:
                        curr_words.append(w)
                    i += 1
                    
            if curr_words:
                clusters.append((' '.join(curr_words), curr_qty if curr_qty is not None else 1.0, unit_override))
            elif curr_qty is not None:
                # Standalone number clause
                if clusters and clusters[-1][1] == 1.0:
                    prev_text, _, prev_unit = clusters.pop()
                    clusters.append((prev_text, curr_qty, prev_unit))

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
        
        def calculate_match_score(query_str, candidate_str):
            q_words = query_str.lower().split()
            c_words = candidate_str.lower().split()
            
            # Query token coverage
            matched_q = sum(1 for qw in q_words if any(fuzz.ratio(qw, cw) >= 80 for cw in c_words))
            q_cov = matched_q / len(q_words) if q_words else 0.0
            
            # Candidate token coverage
            matched_c = sum(1 for cw in c_words if any(fuzz.ratio(cw, qw) >= 80 for qw in q_words))
            c_cov = matched_c / len(c_words) if c_words else 0.0
            
            # F1 score for word overlap
            f1 = 2 * (q_cov * c_cov) / (q_cov + c_cov) if (q_cov + c_cov) > 0 else 0.0
            
            # Token sort ratio
            sort_ratio = fuzz.token_sort_ratio(query_str, candidate_str) / 100.0
            
            return (f1 * 0.7 + sort_ratio * 0.3) * 100
        
        for item_raw_text, qty, unit_override in clusters:
            if not item_raw_text.strip():
                continue
                
            # Apply phonetic normalization and Tamil translations
            tokens = []
            for w in item_raw_text.split():
                if w in ['kilo', 'kg', 'litre', 'liter', 'l', 'ml', 'g', 'gram', 'grams', 'kattu', 'bunch']:
                    continue
                w_norm = PHONETIC_FIXES.get(w, w)
                w_trans = TAMIL_SYNONYMS.get(w_norm, w_norm)
                tokens.append(w_trans)
            
            # If a specific volume/weight was detected, append to query to prioritize matching pack sizes
            if unit_override:
                tokens.append(unit_override)
                
            query = " ".join(tokens).strip()
            if not query:
                continue
                
            best_match = None
            best_score = 0
            
            # Perform multi-strategy matching against database products
            for prod in products:
                prod_label = prod['search_label']
                score = calculate_match_score(query, prod_label)
                if score > best_score:
                    best_score = score
                    best_match = prod
            
            # Acceptance threshold
            if best_match and best_score >= 48.0:
                print(f"[Match Success] '{item_raw_text}' -> '{best_match['name']}' (Score: {best_score:.1f}, Qty: {qty})")
                matched_items.append({
                    "product": best_match['name'],
                    "product_id": best_match['id'],
                    "quantity": qty,
                    "unit": best_match['unit'],
                    "unit_value": best_match['unit_value']
                })
            else:
                print(f"[Match Miss] '{item_raw_text}' (Query: '{query}', Best: {best_match['name'] if best_match else 'None'} @ {best_score:.1f})")
                unrecognized_items.append({
                    "text": item_raw_text,
                    "reason": f"Best match {best_match['name'] if best_match else 'None'} scored only {best_score:.1f}"
                })
                
        # 3. Cloud LLM Fallback (Gemini) if primary NLU had unrecognized tokens and Gemini is active
        if unrecognized_items and self.gemini_model:
            try:
                print("Falling back to Gemini LLM for unmatched phrases...")
                prompt = f"""
                You are a smart supermarket billing parser for Tamil and English spoken voice.
                Database product catalogue:
                {json.dumps([p['name'] for p in products])}

                Parse the following spoken input into exact product names from the catalogue and quantities:
                Input: "{transcript}"

                Return ONLY valid JSON matching this schema:
                {{
                  "items": [
                    {{"product": "Exact Product Name from Catalogue", "quantity": 1.0}}
                  ]
                }}
                """
                response = self.gemini_model.generate_content(prompt)
                clean_json_str = response.text.replace("```json", "").replace("```", "").strip()
                gemini_res = json.loads(clean_json_str)
                if gemini_res.get("items"):
                    return json.dumps({"items": gemini_res["items"], "unrecognized": []})
            except Exception as e:
                print(f"Gemini fallback notice: {e}")

        return json.dumps({
            "items": matched_items,
            "unrecognized": unrecognized_items
        })
