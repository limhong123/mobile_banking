import {
  useEffect,
  useState,
} from "react";

import {
  ArrowLeft,
  BadgeCheck,
  CreditCard,
  FileImage,
  Phone,
  ScanFace,
  User,
  Wallet,
} from "lucide-react";

import {
  useNavigate,
  useParams,
} from "react-router-dom";

import Sidebar from "../components/Sidebar";

import {
  getUserDetail,
} from "../api/adminApi";


export default function UserKycDetail() {
  const { id } =
    useParams();

  const navigate =
    useNavigate();


  const [
    user,
    setUser,
  ] = useState(null);


  const [
    loading,
    setLoading,
  ] = useState(true);


  const [
    error,
    setError,
  ] = useState("");


  // =====================================================
  // LOAD USER
  // =====================================================

  useEffect(() => {
    loadUser();
  }, [id]);


  async function loadUser() {
    try {
      setLoading(true);

      setError("");


      const response =
        await getUserDetail(
          id
        );


      console.log(
        "USER KYC DETAIL:",
        response
      );


      setUser(
        response?.data ||
        null
      );

    } catch (error) {
      console.error(
        "USER DETAIL ERROR:",
        error
      );


      const detail =
        error.response?.data
          ?.detail;


      setError(
        typeof detail ===
        "string"
          ? detail
          : "Unable to load user detail"
      );

    } finally {
      setLoading(false);
    }
  }


  // =====================================================
  // IMAGE URL
  // =====================================================

  function getImageUrl(
    path
  ) {
    if (!path) {
      return null;
    }


    const value =
      String(path)
        .trim();


    if (!value) {
      return null;
    }


    if (
      value.startsWith(
        "http://"
      ) ||
      value.startsWith(
        "https://"
      )
    ) {
      return value;
    }


    const baseUrl =
      (
        import.meta.env
          .VITE_API_BASE_URL ||
        "http://127.0.0.1:8000"
      ).replace(
        /\/$/,
        ""
      );


    if (
      value.startsWith("/")
    ) {
      return (
        `${baseUrl}${value}`
      );
    }


    return (
      `${baseUrl}/${value}`
    );
  }


  // =====================================================
  // KYC STATUS
  // =====================================================

  function kycLabel(
    status
  ) {
    switch (status) {
      case "approved":
        return "Approved";

      case "rejected":
        return "Rejected";

      case "nid_uploaded":
        return "Face Verification";

      case "not_submitted":
        return "Not Submitted";

      default:
        return (
          status ||
          "Not Submitted"
        );
    }
  }


  function kycStatusClass(
    status
  ) {
    if (
      status === "approved"
    ) {
      return (
        "bg-green-50 text-green-700"
      );
    }


    if (
      status === "rejected"
    ) {
      return (
        "bg-red-50 text-red-700"
      );
    }


    if (
      status === "nid_uploaded"
    ) {
      return (
        "bg-blue-50 text-blue-700"
      );
    }


    return (
      "bg-slate-100 text-slate-600"
    );
  }


  // =====================================================
  // LOADING
  // =====================================================

  if (loading) {
    return (
      <div className="min-h-screen bg-slate-50">

        <Sidebar />


        <main className="ml-[255px] flex min-h-screen items-center justify-center">

          <div className="text-center">

            <div className="mx-auto h-9 w-9 animate-spin rounded-full border-4 border-slate-200 border-t-blue-600" />


            <p className="mt-4 text-sm text-slate-500">
              Loading KYC detail...
            </p>

          </div>

        </main>

      </div>
    );
  }


  // =====================================================
  // ERROR
  // =====================================================

  if (
    error ||
    !user
  ) {
    return (
      <div className="min-h-screen bg-slate-50">

        <Sidebar />


        <main className="ml-[255px] min-h-screen p-8">

          <button
            type="button"
            onClick={() =>
              navigate(
                "/admin/users"
              )
            }
            className="mb-6 inline-flex items-center gap-2 text-sm font-semibold text-blue-600"
          >
            <ArrowLeft
              size={17}
            />

            Back to Users
          </button>


          <div className="rounded-2xl border border-red-200 bg-red-50 p-6 text-red-700">

            {error ||
              "User not found"}

          </div>

        </main>

      </div>
    );
  }


  // =====================================================
  // NORMALIZE DATA
  // =====================================================

  const kyc =
    user.kyc ||
    {};


  const nidData =
    user.nid_data ||
    kyc.nid_data ||
    {};


  // =====================================================
  // IDENTITY DATA
  // =====================================================

  const nidNumber =
    kyc.nid_number ||
    nidData.nid_number ||
    nidData.id_number ||
    "-";


  const nidFirstName =
    kyc.first_name ||
    nidData.first_name ||
    "";


  const nidLastName =
    kyc.last_name ||
    nidData.last_name ||
    "";


  const fullNameOnNid =
    kyc.full_name ||
    nidData.full_name ||
    `${nidFirstName} ${nidLastName}`
      .trim() ||
    "-";


  const dateOfBirth =
    kyc.date_of_birth ||
    nidData.date_of_birth ||
    nidData.dob ||
    "-";


  const expiryDate =
    kyc.expiry_date ||
    nidData.expiry_date ||
    nidData.expiration_date ||
    "-";


  const dataSource =
    kyc.source ||
    nidData.source ||
    "-";


  // =====================================================
  // FACE DATA
  // =====================================================

  const faceMatch =
    kyc.face_match ||
    user.face_match ||
    user.face_match_result ||
    user.match_result ||
    {};


  const faceVerified =
    kyc.face_verified ??
    user.face_verified ??
    faceMatch.verified ??
    null;


  const matchScore =
    kyc.face_match_score ??
    kyc.match_score ??
    user.match_score ??
    faceMatch.match_score ??
    null;


  const distance =
    kyc.distance ??
    user.distance ??
    faceMatch.distance ??
    null;


  const threshold =
    kyc.threshold ??
    user.threshold ??
    faceMatch.threshold ??
    null;


  const faceModel =
    kyc.model ||
    faceMatch.model ||
    "-";


  const similarityMetric =
    kyc.similarity_metric ||
    faceMatch.similarity_metric ||
    "-";


  // =====================================================
  // IMAGES
  // =====================================================

  const nidFront =
    getImageUrl(
      kyc.nid_front_url ||
      user.nid_front_url ||
      kyc.nid_front_path ||
      user.nid_front_path ||
      user.nid_image ||
      user.nid_image_path
    );


  const selfie =
    getImageUrl(
      kyc.selfie_url ||
      user.selfie_url ||
      kyc.selfie_path ||
      user.selfie_path ||
      user.face_image ||
      user.face_image_path
    );


  // =====================================================
  // UI
  // =====================================================

  return (
    <div className="min-h-screen bg-slate-50">

      <Sidebar />


      <main className="ml-[255px] min-h-screen p-8">

        {/* HEADER */}

        <div className="mb-7">

          <button
            type="button"
            onClick={() =>
              navigate(
                "/admin/users"
              )
            }
            className="mb-4 inline-flex items-center gap-2 text-sm font-semibold text-slate-500 transition hover:text-blue-600"
          >
            <ArrowLeft
              size={17}
            />

            Back to Users
          </button>


          <h1 className="text-3xl font-bold tracking-tight text-slate-900">
            KYC Detail
          </h1>


          <p className="mt-1 text-sm text-slate-500">
            View customer NID and
            live face verification result
          </p>

        </div>


        {/* CUSTOMER */}

        <div className="mb-6 grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">

          <InfoCard
            icon={User}
            label="Customer"
            value={
              `${user.first_name || ""} ${user.last_name || ""}`
                .trim() ||
              "-"
            }
          />


          <InfoCard
            icon={Phone}
            label="Phone Number"
            value={
              user.phone_number ||
              "-"
            }
          />


          <InfoCard
            icon={Wallet}
            label="Balance"
            value={
              `$${Number(
                user.balance ||
                0
              ).toFixed(2)}`
            }
          />


          <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">

            <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600">

              <BadgeCheck
                size={20}
              />

            </div>


            <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
              KYC Status
            </p>


            <div className="mt-2">

              <span
                className={`inline-flex rounded-full px-3 py-1 text-xs font-semibold ${kycStatusClass(
                  user.kyc_status
                )}`}
              >
                {kycLabel(
                  user.kyc_status
                )}
              </span>

            </div>

          </div>

        </div>


        {/* IDENTITY INFORMATION */}

        <div className="mb-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">

          <div className="mb-6">

            <h2 className="text-xl font-bold text-slate-900">
              Identity Information
            </h2>


            <p className="mt-1 text-sm text-slate-500">
              OCR information from
              the customer's NID front
            </p>

          </div>


          <div className="grid grid-cols-1 gap-x-10 gap-y-6 md:grid-cols-2 xl:grid-cols-3">

            <Detail
              label="NID Number"
              value={
                nidNumber
              }
            />


            <Detail
              label="Full Name on NID"
              value={
                fullNameOnNid
              }
            />


            <Detail
              label="Date of Birth"
              value={
                dateOfBirth
              }
            />


            <Detail
              label="Expiry Date"
              value={
                expiryDate
              }
            />


            <Detail
              label="Data Source"
              value={
                dataSource
              }
            />


            <Detail
              label="Phone Verified"
              value={
                user.is_verified
                  ? "Yes"
                  : "No"
              }
            />

          </div>

        </div>


        {/* FACE VERIFICATION */}

        <div className="mb-6 rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">

          <div className="mb-6 flex items-center gap-3">

            <div className="flex h-11 w-11 items-center justify-center rounded-xl bg-violet-50 text-violet-600">

              <ScanFace
                size={22}
              />

            </div>


            <div>

              <h2 className="text-xl font-bold text-slate-900">
                Face Verification
              </h2>


              <p className="mt-1 text-sm text-slate-500">
                NID face compared
                with live selfie
              </p>

            </div>

          </div>


          <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">

            <ResultCard
              label="Face Verified"
              value={
                faceVerified ===
                true
                  ? "Matched"
                  : faceVerified ===
                    false
                    ? "Not Matched"
                    : "-"
              }
            />


            <ResultCard
              label="Match Score"
              value={
                matchScore !==
                  null
                  ? `${matchScore}`
                  : "-"
              }
            />


            <ResultCard
              label="Distance"
              value={
                distance !==
                  null
                  ? `${distance}`
                  : "-"
              }
            />


            <ResultCard
              label="Threshold"
              value={
                threshold !==
                  null
                  ? `${threshold}`
                  : "-"
              }
            />


            <ResultCard
              label="Model"
              value={
                faceModel
              }
            />


            <ResultCard
              label="Similarity Metric"
              value={
                similarityMetric
              }
            />

          </div>

        </div>


        {/* DOCUMENTS */}

        <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">

          <div className="mb-6">

            <h2 className="text-xl font-bold text-slate-900">
              KYC Images
            </h2>


            <p className="mt-1 text-sm text-slate-500">
              NID front and
              live selfie used for verification
            </p>

          </div>


          <div className="grid grid-cols-1 gap-5 lg:grid-cols-2">

            <KycImage
              title="NID Front"
              url={
                nidFront
              }
            />


            <KycImage
              title="Live Selfie"
              url={
                selfie
              }
            />

          </div>

        </div>

      </main>

    </div>
  );
}


// =====================================================
// INFO CARD
// =====================================================

function InfoCard({
  icon: Icon,
  label,
  value,
}) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">

      <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-blue-50 text-blue-600">

        <Icon
          size={20}
        />

      </div>


      <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
        {label}
      </p>


      <p className="mt-1 font-bold text-slate-900">
        {value || "-"}
      </p>

    </div>
  );
}


// =====================================================
// DETAIL
// =====================================================

function Detail({
  label,
  value,
}) {
  return (
    <div>

      <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
        {label}
      </p>


      <p className="mt-1 break-words text-sm font-semibold text-slate-800">
        {value || "-"}
      </p>

    </div>
  );
}


// =====================================================
// RESULT CARD
// =====================================================

function ResultCard({
  label,
  value,
}) {
  return (
    <div className="rounded-xl bg-slate-50 p-4">

      <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
        {label}
      </p>


      <p className="mt-2 font-bold text-slate-900">
        {value}
      </p>

    </div>
  );
}


// =====================================================
// IMAGE
// =====================================================

function KycImage({
  title,
  url,
}) {
  const [
    failed,
    setFailed,
  ] = useState(false);


  return (
    <div className="overflow-hidden rounded-2xl border border-slate-200 bg-slate-50">

      <div className="border-b border-slate-200 bg-white px-4 py-3">

        <p className="flex items-center gap-2 text-sm font-semibold text-slate-800">

          <FileImage
            size={17}
          />

          {title}

        </p>

      </div>


      {url && !failed ? (

        <a
          href={url}
          target="_blank"
          rel="noreferrer"
          className="block bg-slate-100"
        >

          <img
            src={url}
            alt={title}
            className="h-[340px] w-full object-contain p-3"
            onError={() => {
              console.error(
                "IMAGE LOAD FAILED:",
                url
              );

              setFailed(true);
            }}
          />

        </a>

      ) : (

        <div className="flex h-[340px] flex-col items-center justify-center text-slate-400">

          <CreditCard
            size={38}
          />


          <p className="mt-3 text-sm">

            {failed
              ? "Unable to load image"
              : "No image uploaded"}

          </p>

        </div>

      )}

    </div>
  );
}