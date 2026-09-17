from pathlib import Path
import uuid

import cv2
from deepface import DeepFace


# =========================================================
# CONFIG
# =========================================================

FACE_DIR = Path(
    "uploads/kyc"
)

FACE_DIR.mkdir(
    parents=True,
    exist_ok=True,
)


# =========================================================
# EXTRACT FACE FROM NID
# =========================================================

def extract_face_from_nid(
    nid_image_path: str,
) -> str:
    """
    Detect face from NID front image,
    crop it, resize it, save it,
    and return cropped image path.
    """

    try:
        source_path = Path(
            nid_image_path
        )

        if not source_path.exists():
            raise ValueError(
                "NID front image does not exist"
            )

        image = cv2.imread(
            str(source_path)
        )

        if image is None:
            raise ValueError(
                "Cannot read NID front image"
            )

        # -------------------------------------------------
        # Detect face from NID
        # -------------------------------------------------

        faces = DeepFace.extract_faces(
            img_path=str(
                source_path
            ),
            detector_backend="retinaface",
            enforce_detection=True,
            align=True,
        )

        if not faces:
            raise ValueError(
                "No face detected in NID image"
            )

        # -------------------------------------------------
        # Choose the biggest detected face
        # -------------------------------------------------

        face_info = max(
            faces,
            key=lambda item: (
                item.get(
                    "facial_area",
                    {},
                ).get(
                    "w",
                    0,
                )
                *
                item.get(
                    "facial_area",
                    {},
                ).get(
                    "h",
                    0,
                )
            ),
        )

        facial_area = face_info.get(
            "facial_area",
            {},
        )

        x = int(
            facial_area.get(
                "x",
                0,
            )
        )

        y = int(
            facial_area.get(
                "y",
                0,
            )
        )

        width = int(
            facial_area.get(
                "w",
                0,
            )
        )

        height = int(
            facial_area.get(
                "h",
                0,
            )
        )

        if (
            width <= 0
            or height <= 0
        ):
            raise ValueError(
                "Invalid face area detected in NID"
            )

        image_height, image_width = (
            image.shape[:2]
        )

        # -------------------------------------------------
        # Add small padding around face
        # -------------------------------------------------

        padding_x = int(
            width * 0.12
        )

        padding_y = int(
            height * 0.18
        )

        x1 = max(
            0,
            x - padding_x,
        )

        y1 = max(
            0,
            y - padding_y,
        )

        x2 = min(
            image_width,
            x + width + padding_x,
        )

        y2 = min(
            image_height,
            y + height + padding_y,
        )

        cropped_face = image[
            y1:y2,
            x1:x2,
        ]

        if cropped_face.size == 0:
            raise ValueError(
                "Failed to crop NID face"
            )

        # -------------------------------------------------
        # Resize for more consistent face comparison
        # -------------------------------------------------

        cropped_face = cv2.resize(
            cropped_face,
            (
                512,
                512,
            ),
            interpolation=cv2.INTER_CUBIC,
        )

        # -------------------------------------------------
        # Save cropped face
        # -------------------------------------------------

        filename = (
            f"nid_face_"
            f"{uuid.uuid4()}"
            f".jpg"
        )

        output_path = (
            FACE_DIR
            / filename
        )

        success = cv2.imwrite(
            str(output_path),
            cropped_face,
        )

        if not success:
            raise RuntimeError(
                "Failed to save NID face image"
            )

        print(
            "========== NID FACE =========="
        )

        print(
            f"SOURCE: {source_path}"
        )

        print(
            f"FACE AREA: "
            f"x={x}, "
            f"y={y}, "
            f"w={width}, "
            f"h={height}"
        )

        print(
            f"SAVED: {output_path}"
        )

        print(
            "=============================="
        )

        return str(
            output_path
        )

    except ValueError:
        raise

    except Exception as error:
        raise RuntimeError(
            "Failed to extract "
            f"NID face: {error}"
        ) from error


# =========================================================
# VERIFY NID FACE VS SELFIE
# =========================================================

def verify_face_match(
    nid_face_path: str,
    selfie_path: str,
) -> dict:
    """
    Compare cropped NID face
    with live selfie using ArcFace.
    """

    try:
        nid_path = Path(
            nid_face_path
        )

        selfie = Path(
            selfie_path
        )

        if not nid_path.exists():
            raise ValueError(
                "NID face image does not exist"
            )

        if not selfie.exists():
            raise ValueError(
                "Selfie image does not exist"
            )

        print(
            "========== DEEPFACE =========="
        )

        print(
            f"NID FACE: {nid_path}"
        )

        print(
            f"SELFIE: {selfie}"
        )

        # -------------------------------------------------
        # Compare faces
        # -------------------------------------------------

        result = DeepFace.verify(
            img1_path=str(
                nid_path
            ),
            img2_path=str(
                selfie
            ),
            model_name="ArcFace",
            detector_backend="retinaface",
            distance_metric="cosine",
            enforce_detection=True,
            align=True,
        )

        verified = bool(
            result.get(
                "verified",
                False,
            )
        )

        distance = float(
            result.get(
                "distance",
                1.0,
            )
        )

        threshold = float(
            result.get(
                "threshold",
                0.0,
            )
        )

        # -------------------------------------------------
        # Display score for UI/debug
        #
        # Note:
        # DeepFace's official decision
        # should still use verified,
        # distance, and threshold.
        # -------------------------------------------------

        match_score = round(
            max(
                0.0,
                min(
                    100.0,
                    (
                        1.0
                        - distance
                    )
                    * 100.0,
                ),
            ),
            2,
        )

        print(
            f"VERIFIED: {verified}"
        )

        print(
            f"DISTANCE: {distance}"
        )

        print(
            f"THRESHOLD: {threshold}"
        )

        print(
            f"MATCH SCORE: {match_score}"
        )

        print(
            "=============================="
        )

        return {
            "verified": verified,

            "distance": round(
                distance,
                4,
            ),

            "threshold": round(
                threshold,
                4,
            ),

            "match_score": (
                match_score
            ),

            "model": result.get(
                "model",
                "ArcFace",
            ),

            "similarity_metric": (
                result.get(
                    "similarity_metric",
                    "cosine",
                )
            ),
        }

    except ValueError as error:
        print(
            "[FACE DETECTION ERROR] "
            f"{error}"
        )

        raise ValueError(
            "No clear face was detected "
            "in the NID or selfie image"
        ) from error

    except Exception as error:
        print(
            "[FACE VERIFY ERROR] "
            f"{error}"
        )

        raise RuntimeError(
            "Face verification "
            f"failed: {error}"
        ) from error