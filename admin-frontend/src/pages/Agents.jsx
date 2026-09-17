import {
  useEffect,
  useState,
} from "react";

import {
  KeyRound,
  Plus,
  Power,
  Search,
  UserRoundCog,
  Wallet,
  X,
} from "lucide-react";

import Sidebar from "../components/Sidebar";

import {
  createAgent,
  getAgents,
  resetAgentPin,
  toggleAgentStatus,
  topUpAgent,
} from "../api/adminApi";


// =====================================================
// EMPTY AGENT FORM
// =====================================================

const emptyAgentForm = {
  first_name: "",
  last_name: "",
  phone_number: "",
  nid_number: "",
  date_of_birth: "",
  gender: "",
  address: "",
  agent_code: "",
  branch_name: "",
  daily_transaction_limit:
    "5000",
  pin: "",
  confirm_pin: "",
};


export default function Agents() {
  const [
    agents,
    setAgents,
  ] = useState([]);

  const [
    search,
    setSearch,
  ] = useState("");

  const [
    loading,
    setLoading,
  ] = useState(true);

  const [
    showCreate,
    setShowCreate,
  ] = useState(false);

  const [
    showTopUp,
    setShowTopUp,
  ] = useState(false);

  const [
    selectedAgent,
    setSelectedAgent,
  ] = useState(null);

  const [
    topUpAmount,
    setTopUpAmount,
  ] = useState("");

  const [
    creating,
    setCreating,
  ] = useState(false);

  const [
    toppingUp,
    setToppingUp,
  ] = useState(false);

  const [
    form,
    setForm,
  ] = useState(
    emptyAgentForm
  );


  // =====================================================
  // LOAD AGENTS
  // =====================================================

  useEffect(() => {
    loadAgents();
  }, []);


  async function loadAgents() {
    try {
      setLoading(true);

      const response =
        await getAgents();

      setAgents(
        response?.data ||
        []
      );

    } catch (error) {
      console.error(
        "LOAD AGENTS ERROR:",
        error
      );

    } finally {
      setLoading(false);
    }
  }


  // =====================================================
  // FORM CHANGE
  // =====================================================

  function handleChange(
    event
  ) {
    const {
      name,
      value,
    } = event.target;

    let newValue =
      value;

    if (
      name === "pin" ||
      name === "confirm_pin"
    ) {
      newValue =
        value
          .replace(
            /\D/g,
            ""
          )
          .slice(
            0,
            6
          );
    }

    setForm(
      (
        previous
      ) => ({
        ...previous,

        [name]:
          newValue,
      })
    );
  }


  // =====================================================
  // OPEN CREATE
  // =====================================================

  function openCreate() {
    setForm(
      emptyAgentForm
    );

    setShowCreate(
      true
    );
  }


  // =====================================================
  // CLOSE CREATE
  // =====================================================

  function closeCreate() {
    if (creating) {
      return;
    }

    setShowCreate(
      false
    );

    setForm(
      emptyAgentForm
    );
  }


  // =====================================================
  // CREATE AGENT
  // =====================================================

  async function handleCreate(
    event
  ) {
    event.preventDefault();


    const requiredFields = [
      form.first_name,
      form.last_name,
      form.phone_number,
      form.nid_number,
      form.date_of_birth,
      form.gender,
      form.address,
      form.agent_code,
      form.branch_name,
    ];


    const missingField =
      requiredFields.some(
        (value) =>
          !value
            ?.toString()
            .trim()
      );


    if (missingField) {
      alert(
        "Please complete all required fields"
      );

      return;
    }


    if (
      !/^\d{6}$/.test(
        form.pin
      )
    ) {
      alert(
        "PIN must be exactly 6 digits"
      );

      return;
    }


    if (
      form.pin !==
      form.confirm_pin
    ) {
      alert(
        "PIN and Confirm PIN do not match"
      );

      return;
    }


    const dailyLimit =
      Number(
        form.daily_transaction_limit
      );


    if (
      !Number.isFinite(
        dailyLimit
      ) ||
      dailyLimit <= 0
    ) {
      alert(
        "Daily transaction limit must be greater than 0"
      );

      return;
    }


    try {
      setCreating(
        true
      );


      await createAgent({
        first_name:
          form.first_name
            .trim(),

        last_name:
          form.last_name
            .trim(),

        phone_number:
          form.phone_number
            .trim(),

        nid_number:
          form.nid_number
            .trim(),

        date_of_birth:
          form.date_of_birth,

        gender:
          form.gender,

        address:
          form.address
            .trim(),

        agent_code:
          form.agent_code
            .trim()
            .toUpperCase(),

        branch_name:
          form.branch_name
            .trim(),

        daily_transaction_limit:
          dailyLimit,

        pin:
          form.pin,
      });


      setForm(
        emptyAgentForm
      );


      setShowCreate(
        false
      );


      await loadAgents();


      alert(
        "Agent created successfully"
      );

    } catch (error) {
      console.error(
        "CREATE AGENT ERROR:",
        error
      );


      const detail =
        error.response
          ?.data
          ?.detail;


      alert(
        typeof detail ===
          "string"
          ? detail
          : detail?.message ||
            "Unable to create agent"
      );

    } finally {
      setCreating(
        false
      );
    }
  }


  // =====================================================
  // OPEN TOP UP
  // =====================================================

  function openTopUp(
    agent
  ) {
    setSelectedAgent(
      agent
    );

    setTopUpAmount(
      ""
    );

    setShowTopUp(
      true
    );
  }


  // =====================================================
  // CLOSE TOP UP
  // =====================================================

  function closeTopUp() {
    if (toppingUp) {
      return;
    }

    setShowTopUp(
      false
    );

    setSelectedAgent(
      null
    );

    setTopUpAmount(
      ""
    );
  }


  // =====================================================
  // TOP UP AGENT
  // =====================================================

  async function handleTopUp(
    event
  ) {
    event.preventDefault();


    if (!selectedAgent) {
      return;
    }


    const amount =
      Number(
        topUpAmount
      );


    if (
      !Number.isFinite(
        amount
      ) ||
      amount <= 0
    ) {
      alert(
        "Enter a valid amount"
      );

      return;
    }


    const confirmed =
      window.confirm(
        `Transfer $${amount.toFixed(
          2
        )} from System Wallet to ${selectedAgent.first_name} ${selectedAgent.last_name}?`
      );


    if (!confirmed) {
      return;
    }


    try {
      setToppingUp(
        true
      );


      const response =
        await topUpAgent(
          selectedAgent.id,
          amount
        );


      const newBalance =
        response?.data
          ?.agent_balance_after ??
        0;


      setShowTopUp(
        false
      );

      setSelectedAgent(
        null
      );

      setTopUpAmount(
        ""
      );


      await loadAgents();


      alert(
        `Top up successful.\nAgent balance: $${Number(
          newBalance
        ).toFixed(
          2
        )}`
      );

    } catch (error) {
      console.error(
        "TOP UP ERROR:",
        error
      );


      const detail =
        error.response
          ?.data
          ?.detail;


      alert(
        typeof detail ===
          "string"
          ? detail
          : detail?.message ||
            "Top up failed"
      );

    } finally {
      setToppingUp(
        false
      );
    }
  }


  // =====================================================
  // STATUS
  // =====================================================

  async function handleStatus(
    agent
  ) {
    const confirmed =
      window.confirm(
        agent.is_active
          ? `Disable ${agent.first_name} ${agent.last_name}?`
          : `Enable ${agent.first_name} ${agent.last_name}?`
      );


    if (!confirmed) {
      return;
    }


    try {
      await toggleAgentStatus(
        agent.id
      );


      await loadAgents();

    } catch (error) {
      console.error(
        "AGENT STATUS ERROR:",
        error
      );


      const detail =
        error.response
          ?.data
          ?.detail;


      alert(
        typeof detail ===
          "string"
          ? detail
          : detail?.message ||
            "Unable to update agent"
      );
    }
  }


  // =====================================================
  // RESET PIN
  // =====================================================

  async function handleResetPin(
    agent
  ) {
    const pin =
      window.prompt(
        `Enter new 6-digit PIN for ${agent.first_name} ${agent.last_name}`
      );


    if (
      pin === null
    ) {
      return;
    }


    if (
      !/^\d{6}$/.test(
        pin
      )
    ) {
      alert(
        "PIN must be exactly 6 digits"
      );

      return;
    }


    try {
      await resetAgentPin(
        agent.id,
        pin
      );


      alert(
        "Agent PIN reset successfully"
      );

    } catch (error) {
      console.error(
        "RESET PIN ERROR:",
        error
      );


      const detail =
        error.response
          ?.data
          ?.detail;


      alert(
        typeof detail ===
          "string"
          ? detail
          : detail?.message ||
            "Unable to reset PIN"
      );
    }
  }


  // =====================================================
  // FILTER
  // =====================================================

  const filteredAgents =
    agents.filter(
      (agent) => {
        const text =
          `${
            agent.first_name ||
            ""
          } ${
            agent.last_name ||
            ""
          } ${
            agent.phone_number ||
            ""
          } ${
            agent.agent_code ||
            ""
          } ${
            agent.branch_name ||
            ""
          }`
            .toLowerCase();


        return text.includes(
          search
            .trim()
            .toLowerCase()
        );
      }
    );


  // =====================================================
  // UI
  // =====================================================

  return (
    <div className="min-h-screen bg-slate-50">

      <Sidebar />


      <main className="ml-[255px] min-h-screen p-8">

        {/* HEADER */}

        <div className="mb-8 flex items-center justify-between gap-5">

          <div>

            <h1 className="text-3xl font-bold tracking-tight text-slate-900">
              Agents
            </h1>

            <p className="mt-1 text-sm text-slate-500">
              Create, fund and manage
              KhmerPay agent accounts
            </p>

          </div>


          <button
            type="button"
            onClick={
              openCreate
            }
            className="inline-flex items-center gap-2 rounded-xl bg-blue-600 px-5 py-3 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-700"
          >
            <Plus
              size={19}
            />

            Create Agent
          </button>

        </div>


        {/* SEARCH */}

        <div className="mb-6 flex max-w-md items-center gap-3 rounded-xl border border-slate-200 bg-white px-4 shadow-sm focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">

          <Search
            size={19}
            className="shrink-0 text-slate-400"
          />


          <input
            type="text"
            value={
              search
            }
            onChange={(
              event
            ) =>
              setSearch(
                event
                  .target
                  .value
              )
            }
            placeholder="Search name, phone, code..."
            className="w-full bg-transparent py-3 text-sm text-slate-900 outline-none placeholder:text-slate-400"
          />

        </div>


        {/* TABLE */}

        <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">

          {loading ? (

            <div className="flex min-h-[260px] items-center justify-center">

              <div className="text-center">

                <div className="mx-auto h-8 w-8 animate-spin rounded-full border-4 border-slate-200 border-t-blue-600" />

                <p className="mt-4 text-sm text-slate-500">
                  Loading agents...
                </p>

              </div>

            </div>

          ) : filteredAgents.length ===
            0 ? (

            <div className="flex min-h-[260px] flex-col items-center justify-center p-8 text-center">

              <div className="mb-4 flex h-14 w-14 items-center justify-center rounded-full bg-slate-100 text-slate-400">

                <UserRoundCog
                  size={26}
                />

              </div>


              <h3 className="font-semibold text-slate-800">
                No agents found
              </h3>


              <p className="mt-1 text-sm text-slate-500">
                Create your first
                KhmerPay agent account.
              </p>

            </div>

          ) : (

            <div className="overflow-x-auto">

              <table className="w-full border-collapse">

                <thead className="bg-slate-50">

                  <tr className="text-left text-xs font-semibold uppercase tracking-wide text-slate-500">

                    <th className="whitespace-nowrap px-6 py-4">
                      Agent
                    </th>

                    <th className="whitespace-nowrap px-6 py-4">
                      Phone
                    </th>

                    <th className="whitespace-nowrap px-6 py-4">
                      Balance
                    </th>

                    <th className="whitespace-nowrap px-6 py-4">
                      Transactions
                    </th>

                    <th className="whitespace-nowrap px-6 py-4">
                      Total Deposit
                    </th>

                    <th className="whitespace-nowrap px-6 py-4">
                      Status
                    </th>

                    <th className="whitespace-nowrap px-6 py-4">
                      Actions
                    </th>

                  </tr>

                </thead>


                <tbody className="divide-y divide-slate-100">

                  {filteredAgents.map(
                    (agent) => (

                      <tr
                        key={
                          agent.id
                        }
                        className="transition hover:bg-slate-50"
                      >

                        {/* AGENT */}

                        <td className="whitespace-nowrap px-6 py-5">

                          <div className="flex items-center gap-3">

                            <div className="flex h-10 w-10 items-center justify-center rounded-full bg-blue-50 font-bold text-blue-600">

                              {agent.first_name
                                ?.charAt(
                                  0
                                )
                                .toUpperCase() ||
                                "A"}

                            </div>


                            <div>

                              <p className="font-semibold text-slate-900">

                                {agent.first_name}{" "}
                                {agent.last_name}

                              </p>


                              <p className="mt-0.5 text-xs text-slate-400">

                                {agent.agent_code
                                  ? `${agent.agent_code} • `
                                  : ""}

                                KhmerPay Agent

                              </p>


                              {agent.branch_name && (

                                <p className="mt-0.5 text-xs text-slate-400">
                                  {agent.branch_name}
                                </p>

                              )}

                            </div>

                          </div>

                        </td>


                        {/* PHONE */}

                        <td className="whitespace-nowrap px-6 py-5 text-sm text-slate-600">
                          {
                            agent.phone_number
                          }
                        </td>


                        {/* BALANCE */}

                        <td className="whitespace-nowrap px-6 py-5">

                          <p className="font-bold text-blue-600">

                            $

                            {Number(
                              agent.balance ||
                                0
                            ).toLocaleString(
                              undefined,
                              {
                                minimumFractionDigits:
                                  2,

                                maximumFractionDigits:
                                  2,
                              }
                            )}

                          </p>


                          <p className="mt-0.5 text-xs text-slate-400">
                            {agent.currency ||
                              "USD"}
                          </p>

                        </td>


                        {/* TRANSACTIONS */}

                        <td className="whitespace-nowrap px-6 py-5 text-sm font-medium text-slate-700">

                          {agent.total_transactions ||
                            0}

                        </td>


                        {/* TOTAL DEPOSIT */}

                        <td className="whitespace-nowrap px-6 py-5 font-semibold text-slate-900">

                          $

                          {Number(
                            agent.total_deposit ||
                              0
                          ).toLocaleString(
                            undefined,
                            {
                              minimumFractionDigits:
                                2,

                              maximumFractionDigits:
                                2,
                            }
                          )}

                        </td>


                        {/* STATUS */}

                        <td className="whitespace-nowrap px-6 py-5">

                          <span
                            className={
                              agent.is_active
                                ? "inline-flex rounded-full bg-green-50 px-3 py-1 text-xs font-semibold text-green-700"
                                : "inline-flex rounded-full bg-red-50 px-3 py-1 text-xs font-semibold text-red-700"
                            }
                          >

                            {agent.is_active
                              ? "Active"
                              : "Disabled"}

                          </span>

                        </td>


                        {/* ACTION */}

                        <td className="whitespace-nowrap px-6 py-5">

                          <div className="flex items-center gap-2">

                            <button
                              type="button"
                              onClick={() =>
                                openTopUp(
                                  agent
                                )
                              }
                              disabled={
                                !agent.is_active
                              }
                              className="inline-flex items-center gap-1.5 rounded-lg border border-green-200 bg-green-50 px-3 py-2 text-xs font-semibold text-green-700 transition hover:bg-green-100 disabled:cursor-not-allowed disabled:opacity-40"
                            >
                              <Wallet
                                size={15}
                              />

                              Top Up
                            </button>


                            <button
                              type="button"
                              onClick={() =>
                                handleResetPin(
                                  agent
                                )
                              }
                              className="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 bg-white px-3 py-2 text-xs font-semibold text-slate-700 transition hover:bg-slate-50"
                            >
                              <KeyRound
                                size={15}
                              />

                              Reset PIN
                            </button>


                            <button
                              type="button"
                              onClick={() =>
                                handleStatus(
                                  agent
                                )
                              }
                              className={
                                agent.is_active
                                  ? "inline-flex items-center gap-1.5 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-xs font-semibold text-red-700 transition hover:bg-red-100"
                                  : "inline-flex items-center gap-1.5 rounded-lg border border-green-200 bg-green-50 px-3 py-2 text-xs font-semibold text-green-700 transition hover:bg-green-100"
                              }
                            >
                              <Power
                                size={15}
                              />

                              {agent.is_active
                                ? "Disable"
                                : "Enable"}

                            </button>

                          </div>

                        </td>

                      </tr>

                    )
                  )}

                </tbody>

              </table>

            </div>
          )}

        </div>


        {/* =================================================
            CREATE AGENT MODAL
        ================================================= */}

        {showCreate && (

          <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">

            <div className="max-h-[92vh] w-full max-w-3xl overflow-y-auto rounded-3xl bg-white shadow-2xl">

              {/* HEADER */}

              <div className="sticky top-0 z-10 flex items-start justify-between gap-5 border-b border-slate-100 bg-white px-7 py-6">

                <div>

                  <h2 className="text-2xl font-bold text-slate-900">
                    Create Agent
                  </h2>

                  <p className="mt-1 text-sm text-slate-500">
                    Register a new authorized
                    KhmerPay agent
                  </p>

                </div>


                <button
                  type="button"
                  disabled={
                    creating
                  }
                  onClick={
                    closeCreate
                  }
                  className="rounded-xl bg-slate-100 p-2 text-slate-600 transition hover:bg-slate-200 disabled:opacity-50"
                >
                  <X
                    size={20}
                  />
                </button>

              </div>


              <form
                onSubmit={
                  handleCreate
                }
                className="p-7"
              >

                {/* PERSONAL INFO */}

                <SectionTitle
                  title="Personal Information"
                  subtitle="Basic identity information of the agent"
                />


                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">

                  <FormInput
                    label="First Name"
                    name="first_name"
                    value={
                      form.first_name
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="Phon"
                    required
                  />


                  <FormInput
                    label="Last Name"
                    name="last_name"
                    value={
                      form.last_name
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="Phe"
                    required
                  />


                  <FormInput
                    label="Phone Number"
                    name="phone_number"
                    value={
                      form.phone_number
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="+855 12 345 678"
                    required
                  />


                  <FormInput
                    label="National ID Number"
                    name="nid_number"
                    value={
                      form.nid_number
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="Enter NID number"
                    required
                  />


                  <FormInput
                    label="Date of Birth"
                    name="date_of_birth"
                    type="date"
                    value={
                      form.date_of_birth
                    }
                    onChange={
                      handleChange
                    }
                    required
                  />


                  <div>

                    <label className="mb-2 block text-sm font-semibold text-slate-700">
                      Gender
                      <span className="ml-1 text-red-500">
                        *
                      </span>
                    </label>


                    <select
                      name="gender"
                      value={
                        form.gender
                      }
                      onChange={
                        handleChange
                      }
                      required
                      className="w-full rounded-xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-700 outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    >

                      <option value="">
                        Select gender
                      </option>

                      <option value="male">
                        Male
                      </option>

                      <option value="female">
                        Female
                      </option>

                      <option value="other">
                        Other
                      </option>

                    </select>

                  </div>


                  <div className="sm:col-span-2">

                    <label className="mb-2 block text-sm font-semibold text-slate-700">
                      Address
                      <span className="ml-1 text-red-500">
                        *
                      </span>
                    </label>


                    <textarea
                      name="address"
                      value={
                        form.address
                      }
                      onChange={
                        handleChange
                      }
                      placeholder="Agent current address"
                      rows={3}
                      required
                      className="w-full resize-none rounded-xl border border-slate-200 px-4 py-3 text-sm outline-none transition focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
                    />

                  </div>

                </div>


                <div className="my-7 border-t border-slate-100" />


                {/* AGENT INFO */}

                <SectionTitle
                  title="Agent Information"
                  subtitle="Operational information used by KhmerPay"
                />


                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">

                  <FormInput
                    label="Agent Code"
                    name="agent_code"
                    value={
                      form.agent_code
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="AGT-0001"
                    required
                  />


                  <FormInput
                    label="Branch / Location"
                    name="branch_name"
                    value={
                      form.branch_name
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="Phnom Penh Branch"
                    required
                  />


                  <div className="sm:col-span-2">

                    <label className="mb-2 block text-sm font-semibold text-slate-700">
                      Daily Transaction Limit
                      <span className="ml-1 text-red-500">
                        *
                      </span>
                    </label>


                    <div className="flex items-center rounded-xl border border-slate-200 px-4 transition focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">

                      <span className="font-bold text-slate-400">
                        $
                      </span>


                      <input
                        type="number"
                        name="daily_transaction_limit"
                        min="1"
                        step="0.01"
                        value={
                          form.daily_transaction_limit
                        }
                        onChange={
                          handleChange
                        }
                        required
                        className="w-full bg-transparent px-3 py-3 text-sm outline-none"
                      />


                      <span className="text-xs font-semibold text-slate-400">
                        USD
                      </span>

                    </div>


                    <p className="mt-2 text-xs text-slate-400">
                      Maximum total amount this
                      agent can process per day.
                    </p>

                  </div>

                </div>


                <div className="my-7 border-t border-slate-100" />


                {/* SECURITY */}

                <SectionTitle
                  title="Security"
                  subtitle="Set the initial login PIN for this agent"
                />


                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">

                  <FormInput
                    label="6-Digit PIN"
                    name="pin"
                    type="password"
                    inputMode="numeric"
                    maxLength={6}
                    value={
                      form.pin
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="••••••"
                    required
                  />


                  <FormInput
                    label="Confirm PIN"
                    name="confirm_pin"
                    type="password"
                    inputMode="numeric"
                    maxLength={6}
                    value={
                      form.confirm_pin
                    }
                    onChange={
                      handleChange
                    }
                    placeholder="••••••"
                    required
                  />

                </div>


                {/* WALLET NOTE */}

                <div className="mt-6 rounded-2xl border border-blue-100 bg-blue-50 p-4">

                  <div className="flex items-start gap-3">

                    <Wallet
                      size={20}
                      className="mt-0.5 shrink-0 text-blue-600"
                    />


                    <div>

                      <p className="text-sm font-semibold text-blue-900">
                        Agent Wallet
                      </p>


                      <p className="mt-1 text-xs leading-5 text-blue-700">
                        The agent starts with
                        $0.00. After creation,
                        use Top Up to transfer
                        money from the System
                        Wallet to this agent.
                      </p>

                    </div>

                  </div>

                </div>


                {/* BUTTONS */}

                <div className="mt-7 flex items-center justify-end gap-3">

                  <button
                    type="button"
                    disabled={
                      creating
                    }
                    onClick={
                      closeCreate
                    }
                    className="rounded-xl border border-slate-200 bg-white px-5 py-3 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 disabled:opacity-50"
                  >
                    Cancel
                  </button>


                  <button
                    type="submit"
                    disabled={
                      creating
                    }
                    className="min-w-[180px] rounded-xl bg-blue-600 px-5 py-3 text-sm font-semibold text-white transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-50"
                  >

                    {creating
                      ? "Creating..."
                      : "Create Agent"}

                  </button>

                </div>

              </form>

            </div>

          </div>

        )}


        {/* =================================================
            TOP UP MODAL
        ================================================= */}

        {showTopUp &&
          selectedAgent && (

            <div className="fixed inset-0 z-[100] flex items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm">

              <div className="w-full max-w-md rounded-3xl bg-white p-7 shadow-2xl">

                <div className="mb-6 flex items-start justify-between gap-5">

                  <div>

                    <h2 className="text-2xl font-bold text-slate-900">
                      Top Up Agent
                    </h2>


                    <p className="mt-1 text-sm text-slate-500">
                      Transfer money from
                      System Wallet
                    </p>

                  </div>


                  <button
                    type="button"
                    onClick={
                      closeTopUp
                    }
                    disabled={
                      toppingUp
                    }
                    className="rounded-xl bg-slate-100 p-2 text-slate-600 transition hover:bg-slate-200 disabled:opacity-50"
                  >
                    <X
                      size={20}
                    />
                  </button>

                </div>


                <div className="mb-5 rounded-2xl bg-slate-50 p-4">

                  <p className="text-xs font-medium uppercase tracking-wide text-slate-400">
                    Agent
                  </p>


                  <p className="mt-1 font-semibold text-slate-900">

                    {
                      selectedAgent.first_name
                    }{" "}
                    {
                      selectedAgent.last_name
                    }

                  </p>


                  <p className="mt-1 text-sm text-slate-500">
                    {
                      selectedAgent.phone_number
                    }
                  </p>


                  <div className="mt-4 flex items-center justify-between border-t border-slate-200 pt-4">

                    <span className="text-sm text-slate-500">
                      Current Balance
                    </span>


                    <strong className="text-xl text-blue-600">

                      $

                      {Number(
                        selectedAgent.balance ||
                          0
                      ).toLocaleString(
                        undefined,
                        {
                          minimumFractionDigits:
                            2,

                          maximumFractionDigits:
                            2,
                        }
                      )}

                    </strong>

                  </div>

                </div>


                <form
                  onSubmit={
                    handleTopUp
                  }
                >

                  <label className="mb-2 block text-sm font-semibold text-slate-700">
                    Top Up Amount
                  </label>


                  <div className="flex items-center rounded-xl border border-slate-200 px-4 transition focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100">

                    <span className="text-xl font-bold text-slate-400">
                      $
                    </span>


                    <input
                      type="number"
                      min="0.01"
                      step="0.01"
                      value={
                        topUpAmount
                      }
                      onChange={(
                        event
                      ) =>
                        setTopUpAmount(
                          event
                            .target
                            .value
                        )
                      }
                      placeholder="0.00"
                      className="w-full bg-transparent px-3 py-3 text-xl font-bold text-slate-900 outline-none"
                      required
                    />

                  </div>


                  <div className="mt-3 grid grid-cols-4 gap-2">

                    {[
                      50,
                      100,
                      500,
                      1000,
                    ].map(
                      (
                        value
                      ) => (

                        <button
                          type="button"
                          key={
                            value
                          }
                          onClick={() =>
                            setTopUpAmount(
                              String(
                                value
                              )
                            )
                          }
                          className="rounded-xl border border-slate-200 py-2 text-sm font-semibold text-slate-600 transition hover:border-blue-500 hover:bg-blue-50 hover:text-blue-600"
                        >

                          ${value}

                        </button>

                      )
                    )}

                  </div>


                  <div className="mt-5 rounded-xl border border-amber-200 bg-amber-50 p-3">

                    <p className="text-xs leading-5 text-amber-700">
                      This amount will be
                      deducted from the System
                      Wallet and added to the
                      Agent balance.
                    </p>

                  </div>


                  <button
                    type="submit"
                    disabled={
                      toppingUp
                    }
                    className="mt-6 w-full rounded-xl bg-green-600 py-3.5 text-sm font-semibold text-white transition hover:bg-green-700 disabled:cursor-not-allowed disabled:opacity-50"
                  >

                    {toppingUp
                      ? "Processing..."
                      : "Confirm Top Up"}

                  </button>

                </form>

              </div>

            </div>

          )}

      </main>

    </div>
  );
}


// =====================================================
// SECTION TITLE
// =====================================================

function SectionTitle({
  title,
  subtitle,
}) {
  return (
    <div className="mb-5">

      <h3 className="text-base font-bold text-slate-900">
        {title}
      </h3>


      <p className="mt-1 text-xs text-slate-500">
        {subtitle}
      </p>

    </div>
  );
}


// =====================================================
// FORM INPUT
// =====================================================

function FormInput({
  label,
  required = false,
  ...props
}) {
  return (
    <div>

      <label className="mb-2 block text-sm font-semibold text-slate-700">

        {label}

        {required && (

          <span className="ml-1 text-red-500">
            *
          </span>

        )}

      </label>


      <input
        {...props}
        className="w-full rounded-xl border border-slate-200 px-4 py-3 text-sm text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
      />

    </div>
  );
}