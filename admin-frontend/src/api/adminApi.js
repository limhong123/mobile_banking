import api from "./api";

// USERS
export async function getUsers() {
  const response = await api.get("/admin/users");
  return response.data;
}

export async function toggleUserStatus(id) {
  const response = await api.patch(
    `/admin/users/${id}/status`
  );

  return response.data;
}

export async function approveKyc(id) {
  const response = await api.post(
    `/admin/kyc/${id}/approve`
  );

  return response.data;
}

export async function rejectKyc(id) {
  const response = await api.post(
    `/admin/kyc/${id}/reject`
  );

  return response.data;
}
export async function getUserDetail(id) {
  const response = await api.get(
    `/admin/users/${id}`
  );

  return response.data;
}

// AGENTS
export async function getAgents() {
  const response = await api.get(
    "/admin/agents"
  );

  return response.data;
}

export async function createAgent(data) {
  const response = await api.post(
    "/admin/agents",
    data
  );

  return response.data;
}

export async function resetAgentPin(
  id,
  pin
) {
  const response = await api.patch(
    `/admin/agents/${id}/pin`,
    {
      pin,
    }
  );

  return response.data;
}

export async function toggleAgentStatus(
  id
) {
  const response = await api.patch(
    `/admin/agents/${id}/status`
  );

  return response.data;
}


// SYSTEM WALLET
export async function getSystemWallet() {
  const response = await api.get(
    "/admin/wallet"
  );

  return response.data;
}

export async function fundSystemWallet(
  amount,
  description = ""
) {
  const response = await api.post(
    "/admin/wallet/fund",
    {
      amount: Number(amount),
      description,
    }
  );

  return response.data;
}

export async function getSystemWalletHistory() {
  const response = await api.get(
    "/admin/wallet/history"
  );

  return response.data;
}


// AGENT TOP UP
export async function topUpAgent(
  agentId,
  amount
) {
  const response = await api.post(
    `/admin/wallet/agents/${agentId}/topup`,
    {
      amount: Number(amount),
      description:
        "Agent wallet top up",
    }
  );

  return response.data;
}