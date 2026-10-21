from datetime import datetime
from pathlib import Path
import re
import cv2
import pytesseract


# =========================================================
# TESSERACT EXECUTABLE PATH
# =========================================================

pytesseract.pytesseract.tesseract_cmd = (
    r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe"
)


# =========================================================
# CONSTANTS & TRANSLATION TABLES
# =========================================================

KHMER_DIGITS_MAP = {
    "០": "0", "១": "1", "២": "2", "៣": "3", "៤": "4",
    "៥": "5", "៦": "6", "៧": "7", "៨": "8", "៩": "9"
}

NUMERIC_OCR_FIX = str.maketrans({
    "O": "0", "o": "0",
    "Q": "0", "q": "0",
    "D": "0",
    "I": "1", "i": "1", "l": "1", "|": "1", "!": "1",
    "Z": "2", "z": "2",
    "S": "5", "s": "5",
    "B": "8",
    "G": "6", "b": "6",
})


# =========================================================
# HELPERS
# =========================================================

def parse_khmer_numerals(text: str) -> str:
    res = []
    for char in text:
        res.append(KHMER_DIGITS_MAP.get(char, char))
    return "".join(res)


def parse_date_yymmdd(yymmdd: str, kind: str = "birth") -> str:
    cleaned = re.sub(r"\D", "", yymmdd.translate(NUMERIC_OCR_FIX))
    if len(cleaned) != 6:
        return ""

    yy = int(cleaned[0:2])
    mm = int(cleaned[2:4])
    dd = int(cleaned[4:6])

    if mm < 1 or mm > 12 or dd < 1 or dd > 31:
        return ""

    current_year = datetime.now().year
    current_yy = current_year % 100

    if kind == "birth":
        year = (2000 + yy) if yy <= current_yy else (1900 + yy)
    else:
        year = 2000 + yy

    try:
        return datetime(year, mm, dd).strftime("%Y-%m-%d")
    except ValueError:
        return ""


def parse_date_dmy(dmy_str: str) -> str:
    dmy_str = parse_khmer_numerals(dmy_str)
    match = re.search(r"(\d{1,2})[\.\/\-](\d{1,2})[\.\/\-](\d{4})", dmy_str)
    if match:
        d, m, y = int(match.group(1)), int(match.group(2)), int(match.group(3))
        if 1 <= m <= 12 and 1 <= d <= 31 and 1900 <= y <= 2100:
            try:
                return datetime(y, m, d).strftime("%Y-%m-%d")
            except ValueError:
                return ""
    return ""


def clean_name_token(token: str) -> str:
    token = re.sub(r"[^A-Za-z]", "", token)
    # Remove obvious trailing noise like 'ccecccc', 'kkkk', 'eeeee'
    token = re.sub(r"(?:[ccekkKCE]{3,})$", "", token, flags=re.IGNORECASE)
    # If ends with solitary 'x' after a valid name (e.g. RUNX -> RUN)
    if len(token) > 3 and token.upper().endswith("X"):
        token = token[:-1]
    return token.strip().title()


# =========================================================
# PARSE NID TEXT (MRZ + VISUAL / VIZ)
# =========================================================

def parse_nid_from_text(raw_text: str) -> dict:
    lines = [l.strip() for l in raw_text.splitlines() if l.strip()]

    nid_number = ""
    first_name = ""
    last_name = ""
    full_name = ""
    date_of_birth = ""
    expiry_date = ""
    gender = ""
    source = "ocr"

    # -----------------------------------------------------
    # 1. Search for MRZ lines
    # -----------------------------------------------------
    mrz_lines = []
    line1 = ""
    line2 = ""
    line3 = ""

    for l in lines:
        cleaned = re.sub(r"[^A-Z0-9<]", "", l.upper().replace(" ", ""))
        if not line1 and ("IDKHM" in cleaned or (cleaned.startswith("ID") and "<" in cleaned)):
            line1 = cleaned
            mrz_lines.append(l)
        elif not line2 and re.search(r"\d{6}[0-9OQDILZSBG]?[MF<]\d{6}", cleaned):
            line2 = cleaned
            mrz_lines.append(l)
        elif not line3 and re.search(r"[A-Z]{2,}[<]+[A-Z]{2,}", cleaned):
            line3 = cleaned
            mrz_lines.append(l)

    # Secondary MRZ scan if any line missing
    if not line1 or not line2 or not line3:
        for l in lines:
            cleaned = re.sub(r"[^A-Z0-9<]", "", l.upper().replace(" ", ""))
            if not line1 and "IDKHM" in cleaned:
                line1 = cleaned
            elif not line2 and re.search(r"\d{6}", cleaned) and ("KHM" in cleaned or "M" in cleaned or "F" in cleaned):
                line2 = cleaned
            elif not line3 and "<" in cleaned and re.search(r"[A-Z]{3,}", cleaned) and "IDKHM" not in cleaned:
                line3 = cleaned

    # Extract from Line 1: Document number
    if line1:
        match1 = re.search(r"(?:IDKHM|ID|KHM)?([0-9OQDILZSBG]{8,12})", line1)
        if match1:
            digits = re.sub(r"\D", "", match1.group(1).translate(NUMERIC_OCR_FIX))
            if len(digits) >= 9:
                nid_number = digits[:9]
                source = "ocr_mrz"

    # Extract from Line 2: DOB, Expiry, Gender
    if line2:
        m2 = re.search(r"(\d{6})[0-9OQDILZSBG]?[MF<](\d{6})", line2.translate(NUMERIC_OCR_FIX))
        if m2:
            date_of_birth = parse_date_yymmdd(m2.group(1), "birth")
            expiry_date = parse_date_yymmdd(m2.group(2), "expiry")
            source = "ocr_mrz"
        if re.search(r"\d{6}[0-9OQDILZSBG]?M", line2):
            gender = "Male"
        elif re.search(r"\d{6}[0-9OQDILZSBG]?F", line2):
            gender = "Female"

    # Extract from Line 3: Name
    if line3:
        m3 = re.search(r"([A-Z]{2,})[<]+([A-Z]{2,}(?:[<]+[A-Z]{2,})*)", line3)
        if m3:
            surname = clean_name_token(m3.group(1))
            given_raw = m3.group(2).split("<")
            given_tokens = [clean_name_token(t) for t in given_raw if clean_name_token(t)]
            given = " ".join(given_tokens)
            if surname and given:
                last_name = surname
                first_name = given
                full_name = f"{surname} {given}".strip()
                source = "ocr_mrz"
            elif surname:
                full_name = surname
                last_name = surname

    # -----------------------------------------------------
    # 2. Visual Inspection Zone (VIZ) fallbacks
    # -----------------------------------------------------
    if not nid_number:
        for l in lines:
            if "<" in l:
                continue
            cleaned_l = parse_khmer_numerals(l)
            m = re.search(r"\b(\d{9,10})\b", cleaned_l)
            if m:
                nid_number = m.group(1)
                break

    if not full_name:
        for l in lines:
            if "<" in l:
                continue
            m = re.search(r"\b([A-Z]{2,15}\s+[A-Z]{2,15}(?:\s+[A-Z]{2,15})?)\b", l)
            if m:
                candidate = m.group(1).strip()
                upper = candidate.upper()
                if not any(w in upper for w in [
                    "KINGDOM", "CAMBODIA", "IDENTITY", "CARD", "NATIONAL",
                    "PROTOCOL", "SECURITY", "DNS", "SSID", "SERVER", "DEVICE"
                ]):
                    parts = candidate.title().split()
                    last_name = parts[0]
                    first_name = " ".join(parts[1:])
                    full_name = candidate.title()
                    break

    if not date_of_birth or not expiry_date:
        dates = []
        for l in lines:
            if "<" in l:
                continue
            for m in re.finditer(r"(\d{1,2}[\.\/\-]\d{1,2}[\.\/\-]\d{4})", parse_khmer_numerals(l)):
                parsed = parse_date_dmy(m.group(1))
                if parsed and parsed not in dates:
                    dates.append(parsed)
        if dates:
            if not date_of_birth and len(dates) >= 1:
                date_of_birth = dates[0]
            if not expiry_date and len(dates) >= 2:
                expiry_date = dates[1]

    if not gender:
        for l in lines:
            if "ប្រុស" in l or " ភេទ: ប្រុស" in l or "SEX: M" in l.upper():
                gender = "Male"
                break
            elif "ស្រី" in l or " ភេទ: ស្រី" in l or "SEX: F" in l.upper():
                gender = "Female"
                break

    ocr_completed = bool(nid_number and (full_name or first_name))

    return {
        "nid_number": nid_number,
        "first_name": first_name,
        "last_name": last_name,
        "full_name": full_name or f"{last_name} {first_name}".strip(),
        "date_of_birth": date_of_birth,
        "expiry_date": expiry_date,
        "gender": gender,
        "address": "",
        "source": source,
        "ocr_completed": ocr_completed,
        "mrz_lines": mrz_lines,
        "raw_text": raw_text,
    }


# =========================================================
# MAIN EXTRACT FUNCTION
# =========================================================

def extract_nid_data(image_path: str) -> dict:
    path = Path(image_path)
    if not path.exists():
        raise ValueError(f"NID image does not exist: {image_path}")

    image = cv2.imread(str(path))
    if image is None:
        raise ValueError(f"Cannot read NID image: {image_path}")

    h, w = image.shape[:2]

    # Normalize resolution for fast, crisp OCR (target width ~1200)
    target_w = 1200
    if w > target_w:
        scale = target_w / w
        resized = cv2.resize(image, (target_w, int(h * scale)), interpolation=cv2.INTER_AREA)
    else:
        resized = image

    gray = cv2.cvtColor(resized, cv2.COLOR_BGR2GRAY)

    # Strategy 1: PSM 3 (Auto page segmentation - layout preserving)
    res3 = None
    try:
        text_psm3 = pytesseract.image_to_string(gray, lang="eng", config="--oem 3 --psm 3")
        res3 = parse_nid_from_text(text_psm3)
        if res3.get("ocr_completed") and res3.get("date_of_birth"):
            return res3
    except Exception as e:
        print(f"[OCR PSM3 ERROR] {e}")

    # Strategy 2: PSM 6 (Uniform block of text)
    res6 = None
    try:
        text_psm6 = pytesseract.image_to_string(gray, lang="eng", config="--oem 3 --psm 6")
        res6 = parse_nid_from_text(text_psm6)
        if res6.get("ocr_completed") and res6.get("date_of_birth"):
            return res6
    except Exception as e:
        print(f"[OCR PSM6 ERROR] {e}")

    # Strategy 3: PSM 11 (Sparse text)
    res11 = None
    try:
        text_psm11 = pytesseract.image_to_string(gray, lang="eng", config="--oem 3 --psm 11")
        res11 = parse_nid_from_text(text_psm11)
        if res11.get("ocr_completed"):
            return res11
    except Exception as e:
        print(f"[OCR PSM11 ERROR] {e}")

    # Pick best candidate
    best = None
    best_score = -1
    for cand in [res3, res6, res11]:
        if cand:
            score = sum([
                bool(cand.get("nid_number")),
                bool(cand.get("full_name")),
                bool(cand.get("date_of_birth")),
                bool(cand.get("expiry_date")),
                bool(cand.get("gender")),
            ])
            if score > best_score:
                best_score = score
                best = cand

    if best and (best.get("nid_number") or best.get("full_name")):
        return best

    # Safe structured fallback
    return {
        "nid_number": "",
        "first_name": "",
        "last_name": "",
        "full_name": "",
        "date_of_birth": "",
        "expiry_date": "",
        "gender": "",
        "address": "",
        "source": "ocr_failed",
        "ocr_completed": False,
        "mrz_lines": [],
        "raw_text": "",
    }