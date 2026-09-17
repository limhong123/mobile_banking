export default function StatusBadge({
  status,
}) {
  const normalizedStatus = String(
    status || "not_started",
  ).toLowerCase();

  const styles = {
    approved:
      "border-[#7AC40B]/20 bg-[#7AC40B]/10 text-[#568F05]",

    verified:
      "border-[#7AC40B]/20 bg-[#7AC40B]/10 text-[#568F05]",

    pending:
      "border-amber-200 bg-amber-50 text-amber-700",

    pending_review:
      "border-amber-200 bg-amber-50 text-amber-700",

    rejected:
      "border-red-200 bg-red-50 text-red-600",

    nid_uploaded:
      "border-[#1249AD]/20 bg-[#1249AD]/10 text-[#1249AD]",

    face_uploaded:
      "border-[#1249AD]/20 bg-[#1249AD]/10 text-[#1249AD]",

    not_started:
      "border-slate-200 bg-slate-100 text-slate-500",
  };

  const labels = {
    approved: "Approved",
    verified: "Verified",
    pending: "Pending",
    pending_review: "Pending review",
    rejected: "Rejected",
    nid_uploaded: "NID uploaded",
    face_uploaded: "Face uploaded",
    not_started: "Not started",
  };

  return (
    <span
      className={`inline-flex whitespace-nowrap rounded-full border px-3 py-1.5 text-xs font-bold ${
        styles[normalizedStatus] ||
        styles.not_started
      }`}
    >
      {labels[normalizedStatus] ||
        status ||
        "Unknown"}
    </span>
  );
}