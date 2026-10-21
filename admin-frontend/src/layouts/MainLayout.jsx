import {
  Menu,
  ShieldCheck,
} from "lucide-react";

import { useState } from "react";
import { Outlet } from "react-router-dom";

import Sidebar from "../components/Sidebar";

export default function MainLayout() {
  const user = JSON.parse(localStorage.getItem("user") || "{}");
  const [sidebarOpen, setSidebarOpen] =
    useState(false);

  return (
    <div className="min-h-screen bg-[#F5F7FB] text-slate-900">
      <Sidebar
        isOpen={sidebarOpen}
        onClose={() =>
          setSidebarOpen(false)
        }
      />

      <div className="min-h-screen lg:pl-64">
        <header className="sticky top-0 z-30 flex h-16 items-center justify-between border-b border-slate-200 bg-white/95 px-4 backdrop-blur sm:px-6 lg:px-8">
          <div className="flex items-center">
            <button
              type="button"
              aria-label="Open sidebar"
              onClick={() =>
                setSidebarOpen(true)
              }
              className="mr-3 grid h-10 w-10 place-items-center rounded-xl text-slate-600 transition hover:bg-slate-100 lg:hidden"
            >
              <Menu size={21} />
            </button>

            <div className="flex items-center gap-3">
              <div className="grid h-9 w-9 place-items-center rounded-xl bg-[#1249AD]/10 text-[#1249AD]">
                <ShieldCheck size={19} />
              </div>

              <div>
                <p className="text-sm font-black text-slate-900">
                  Mobile Banking Admin
                </p>

                <p className="mt-0.5 text-xs text-slate-500">
                  Manage users and KYC
                </p>
              </div>
            </div>
          </div>

          <div className="hidden items-center gap-2 rounded-full bg-[#7AC40B]/10 px-3 py-1.5 text-xs font-bold text-[#5D9906] sm:flex">
            <span className="h-2 w-2 rounded-full bg-[#7AC40B]" />
            System online
          </div>
        </header>

        <main className="w-full p-4 sm:p-6 lg:p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}

