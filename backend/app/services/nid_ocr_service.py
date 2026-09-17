from datetime import datetime
from pathlib import Path
import re

import cv2
import pytesseract


# =========================================================
# WINDOWS TESSERACT PATH
# =========================================================

pytesseract.pytesseract.tesseract_cmd = (
    r"C:\Program Files (x86)\Tesseract-OCR\tesseract.exe"
)


# =========================================================
# HELPERS
# =========================================================

def _clean_line(
    value: str,
) -> str:
    value = (
        value
        .upper()
        .strip()
        .replace(" ", "")
    )

    return re.sub(
        r"[^A-Z0-9<]",
        "",
        value,
    )


def _fix_numeric(
    value: str,
) -> str:
    table = str.maketrans({
        "O": "0",
        "Q": "0",
        "D": "0",
        "I": "1",
        "L": "1",
        "Z": "2",
        "S": "5",
        "B": "8",
        "G": "6",
    })

    return value.translate(
        table
    )


# =========================================================
# CLEAN / PARSE NAME
# =========================================================

def _extract_mrz_name(
    line: str,
) -> tuple[str, str]:
    line = (
        line
        .upper()
        .strip()
    )

    # Remove leading OCR noise:
    # 7RUN<<LIMHONG...
    # -> RUN<<LIMHONG...
    line = re.sub(
        r"^[^A-Z]+",
        "",
        line,
    )

    # Keep only valid MRZ chars
    line = re.sub(
        r"[^A-Z<]",
        "",
        line,
    )

    # First try strict pattern:
    # RUN<<LIMHONG
    match = re.search(
        r"([A-Z]{2,})<<([A-Z]{2,})",
        line,
    )

    if match:
        first_name = (
            match.group(1)
            .strip()
            .title()
        )

        last_name = (
            match.group(2)
            .strip()
            .title()
        )

        return (
            first_name,
            last_name,
        )

    # Fallback:
    # split with <<
    parts = line.split(
        "<<",
        1,
    )

    if len(parts) < 2:
        return "", ""

    first_name = (
        parts[0]
        .replace("<", " ")
        .strip()
        .title()
    )

    last_name_raw = (
        parts[1]
        .split("<", 1)[0]
        .strip()
    )

    last_name = (
        last_name_raw
        .title()
    )

    return (
        first_name,
        last_name,
    )


# =========================================================
# DATE PARSER
# =========================================================

def _parse_date(
    value: str,
    kind: str,
) -> str:
    value = _fix_numeric(
        value
    )

    value = re.sub(
        r"\D",
        "",
        value,
    )

    if len(value) != 6:
        return ""

    yy = int(
        value[0:2]
    )

    mm = int(
        value[2:4]
    )

    dd = int(
        value[4:6]
    )

    current_year = (
        datetime.now().year
    )

    current_yy = (
        current_year % 100
    )

    if kind == "birth":
        if yy <= current_yy:
            year = (
                2000 + yy
            )
        else:
            year = (
                1900 + yy
            )
    else:
        year = (
            2000 + yy
        )

    try:
        date = datetime(
            year,
            mm,
            dd,
        )

        return date.strftime(
            "%Y-%m-%d"
        )

    except ValueError:
        return ""


# =========================================================
# FIND MRZ LINES
# =========================================================

def _find_mrz_lines(
    text: str,
) -> list[str]:
    lines = []

    for raw_line in (
        text.splitlines()
    ):
        line = _clean_line(
            raw_line
        )

        if len(line) < 15:
            continue

        if (
            "<" in line
            or "IDKHM" in line
            or "KHM" in line
        ):
            lines.append(
                line
            )

    print(
        "========== CLEANED LINES =========="
    )

    for line in lines:
        print(line)

    print(
        "==================================="
    )

    for index, line in enumerate(
        lines
    ):
        if "IDKHM" in line:
            if (
                len(lines)
                >= index + 3
            ):
                return [
                    lines[index],
                    lines[index + 1],
                    lines[index + 2],
                ]

    lines = sorted(
        lines,
        key=lambda item:
            item.count("<"),
        reverse=True,
    )

    if len(lines) >= 3:
        return lines[:3]

    return []


# =========================================================
# PARSE MRZ
# =========================================================

def parse_mrz(
    text: str,
) -> dict:
    lines = _find_mrz_lines(
        text
    )

    if len(lines) < 3:
        raise ValueError(
            "Could not detect 3 MRZ lines"
        )

    line1 = lines[0]
    line2 = lines[1]
    line3 = lines[2]

    print(
        "========== MRZ =========="
    )

    print(
        f"LINE1={line1}"
    )

    print(
        f"LINE2={line2}"
    )

    print(
        f"LINE3={line3}"
    )

    print(
        "========================="
    )

    # =====================================================
    # NID NUMBER
    # =====================================================

    nid_number = ""

    match = re.search(
        r"IDKHM([A-Z0-9]{9,14})",
        line1,
    )

    if match:
        raw = _fix_numeric(
            match.group(1)
        )

        numbers = re.sub(
            r"\D",
            "",
            raw,
        )

        if len(numbers) >= 9:
            nid_number = (
                numbers[:9]
            )

    # =====================================================
    # NAME
    # =====================================================

    first_name, last_name = (
        _extract_mrz_name(
            line3
        )
    )

    # =====================================================
    # DOB + EXPIRY
    # =====================================================

    date_of_birth = ""
    expiry_date = ""

    numeric_line = (
        _fix_numeric(
            line2
        )
    )

    date_match = re.search(
        r"(\d{6})\d?[MF<](\d{6})",
        numeric_line,
    )

    if date_match:
        date_of_birth = (
            _parse_date(
                date_match.group(1),
                "birth",
            )
        )

        expiry_date = (
            _parse_date(
                date_match.group(2),
                "expiry",
            )
        )

    completed = all([
        first_name,
        last_name,
        nid_number,
        date_of_birth,
        expiry_date,
    ])

    return {
        "first_name":
            first_name,

        "last_name":
            last_name,

        "nid_number":
            nid_number,

        "date_of_birth":
            date_of_birth,

        "expiry_date":
            expiry_date,

        "ocr_completed":
            completed,

        "mrz_lines":
            lines,
    }


# =========================================================
# OCR ONE IMAGE
# =========================================================

def _ocr_image(
    image,
    psm: int,
) -> str:
    config = (
        f"--oem 3 "
        f"--psm {psm} "
        "-c tessedit_char_whitelist="
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "0123456789<"
    )

    return (
        pytesseract
        .image_to_string(
            image,
            lang="eng",
            config=config,
        )
    )


# =========================================================
# EXTRACT NID DATA
# =========================================================

def extract_nid_data(
    image_path: str,
) -> dict:
    path = Path(
        image_path
    )

    if not path.exists():
        raise ValueError(
            "NID image does not exist"
        )

    image = cv2.imread(
        str(path)
    )

    if image is None:
        raise ValueError(
            "Cannot read NID image"
        )

    height, width = (
        image.shape[:2]
    )

    print(
        "========== IMAGE =========="
    )

    print(
        f"width={width}"
    )

    print(
        f"height={height}"
    )

    print(
        "==========================="
    )

    # =====================================================
    # CROP BOTTOM AREA
    # =====================================================

    y1 = int(
        height * 0.50
    )

    y2 = height

    mrz_crop = image[
        y1:y2,
        0:width,
    ]

    if mrz_crop.size == 0:
        raise ValueError(
            "MRZ crop is empty"
        )

    # =====================================================
    # DEBUG DIRECTORY
    # =====================================================

    debug_dir = Path(
        "uploads/debug"
    )

    debug_dir.mkdir(
        parents=True,
        exist_ok=True,
    )

    cv2.imwrite(
        str(
            debug_dir
            / "mrz_crop.jpg"
        ),
        mrz_crop,
    )

    # =====================================================
    # RESIZE
    # =====================================================

    mrz_crop = cv2.resize(
        mrz_crop,
        None,
        fx=1.5,
        fy=1.5,
        interpolation=cv2.INTER_CUBIC,
    )

    # =====================================================
    # GRAYSCALE
    # =====================================================

    gray = cv2.cvtColor(
        mrz_crop,
        cv2.COLOR_BGR2GRAY,
    )

    # =====================================================
    # CONTRAST
    # =====================================================

    clahe = cv2.createCLAHE(
        clipLimit=2.0,
        tileGridSize=(
            8,
            8,
        ),
    )

    contrast = clahe.apply(
        gray
    )

    # =====================================================
    # OTSU THRESHOLD
    # =====================================================

    otsu = cv2.threshold(
        contrast,
        0,
        255,
        (
            cv2.THRESH_BINARY
            + cv2.THRESH_OTSU
        ),
    )[1]

    # =====================================================
    # SAVE DEBUG IMAGES
    # =====================================================

    cv2.imwrite(
        str(
            debug_dir
            / "mrz_gray.jpg"
        ),
        gray,
    )

    cv2.imwrite(
        str(
            debug_dir
            / "mrz_otsu.jpg"
        ),
        otsu,
    )

    # =====================================================
    # OCR - FAST MODE
    # =====================================================

    image_variants = [
        contrast,
        otsu,
    ]

    best_partial = None
    best_score = -1

    for image_variant in (
        image_variants
    ):
        try:
            text = _ocr_image(
                image_variant,
                6,
            )

            if not text.strip():
                continue

            print(
                "========== OCR =========="
            )

            print(text)

            print(
                "========================="
            )

            try:
                result = parse_mrz(
                    text
                )

                result[
                    "raw_text"
                ] = text

                # Full success:
                # stop immediately.
                if result.get(
                    "ocr_completed"
                ):
                    print(
                        "========== OCR SUCCESS =========="
                    )

                    print(
                        result
                    )

                    print(
                        "================================="
                    )

                    return result

                score = sum([
                    bool(
                        result.get(
                            "first_name"
                        )
                    ),
                    bool(
                        result.get(
                            "last_name"
                        )
                    ),
                    bool(
                        result.get(
                            "nid_number"
                        )
                    ),
                    bool(
                        result.get(
                            "date_of_birth"
                        )
                    ),
                    bool(
                        result.get(
                            "expiry_date"
                        )
                    ),
                ])

                if score > best_score:
                    best_score = score
                    best_partial = (
                        result
                    )

                    best_partial[
                        "raw_text"
                    ] = text

            except Exception as error:
                print(
                    "[MRZ PARSE ERROR] "
                    f"{error}"
                )

        except Exception as error:
            print(
                "[OCR TRY ERROR] "
                f"{error}"
            )

    # =====================================================
    # PARTIAL FALLBACK
    # =====================================================

    if best_partial:
        print(
            "========== OCR PARTIAL =========="
        )

        print(
            best_partial
        )

        print(
            "================================="
        )

        return best_partial

    raise ValueError(
        "Could not read NID MRZ"
    )