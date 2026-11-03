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



export async function getBankFinancialSummary() {

  const response = await api.get(

    "/admin/wallet/financial-summary"

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



export async function reconcileSystemWallet(action, payload = {}) {

  const response = await api.post(

    "/admin/wallet/reconcile",

    {

      action,

      ...payload,

    }

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

// USER BALANCE ADJUSTMENTS (CREDIT / DEBIT)
export async function creditUser(userId, { amount, description, reference } = {}) {
  const response = await api.post(`/admin/users/${userId}/credit`, {
    amount: Number(amount),
    description,
    reference,
  });
  return response.data;
}

export async function debitUser(userId, { amount, description, reference } = {}) {
  const response = await api.post(`/admin/users/${userId}/debit`, {
    amount: Number(amount),
    description,
    reference,
  });
  return response.data;
}

// AGENT BALANCE ADJUSTMENTS (CREDIT / DEBIT)
export async function creditAgent(agentId, { amount, description, reference } = {}) {
  const response = await api.post(`/admin/agents/${agentId}/credit`, {
    amount: Number(amount),
    description,
    reference,
  });
  return response.data;
}

export async function debitAgent(agentId, { amount, description, reference } = {}) {
  const response = await api.post(`/admin/agents/${agentId}/debit`, {
    amount: Number(amount),
    description,
    reference,
  });
  return response.data;
}

// ==========================================
// SAVINGS
// ==========================================

export async function getSavingsTerms() {
  const response = await api.get('/admin/savings/terms');
  return response.data;
}

export async function createSavingsTerm(data) {
  const response = await api.post('/admin/savings/terms', data);
  return response.data;
}

export async function updateSavingsTerm(id, data) {
  const response = await api.patch(`/admin/savings/terms/${id}`, data);
  return response.data;
}

export async function deleteSavingsTerm(id) {
  const response = await api.delete(`/admin/savings/terms/${id}`);
  return response.data;
}

export async function getSavingsSettings() {
  const response = await api.get('/admin/savings/settings');
  return response.data;
}

export async function updateSavingsSettings(data) {
  const response = await api.put('/admin/savings/settings', data);
  return response.data;
}

export async function getSavingsOverview() {
  const response = await api.get('/admin/savings/overview');
  return response.data;
}

export async function simulateSavingsMaturity(id) {
  const response = await api.post(`/admin/savings/${id}/simulate-maturity`);
  return response.data;
}
