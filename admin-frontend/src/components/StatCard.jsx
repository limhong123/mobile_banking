export default function StatCard({
  title,
  value,
  icon: Icon,
  iconStyle = "",
  description,
}) {
  return (
    <div className="group relative overflow-hidden rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition duration-200 hover:-translate-y-0.5 hover:border-[#1249AD]/20 hover:shadow-lg hover:shadow-slate-200/60">
      <div className="flex items-start justify-between">
        <div
          className={`grid h-11 w-11 place-items-center rounded-xl ${iconStyle}`}
        >
          <Icon size={22} />
        </div>

        <div className="h-8 w-1 rounded-full bg-[#1249AD]/10 transition group-hover:bg-[#1249AD]" />
      </div>

      <h3 className="mt-5 text-3xl font-black text-slate-900">
        {value}
      </h3>

      <p className="mt-1 text-sm font-bold text-slate-700">
        {title}
      </p>

      {description && (
        <p className="mt-2 text-xs text-slate-400">
          {description}
        </p>
      )}
    </div>
  );
}