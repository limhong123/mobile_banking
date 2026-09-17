import api from "./api";


export async function getAgentProfile() {
  const response =
    await api.get(
      "/agent/me"
    );

  return response.data;
}


export async function getAgentDashboard() {
  const response =
    await api.get(
      "/agent/dashboard"
    );

  return response.data;
}


export async function searchCustomer(
  phoneNumber
) {
  const response =
    await api.get(
      "/agent/customer",
      {
        params: {
          phone_number:
            phoneNumber,
        },
      }
    );

  return response.data;
}


export async function depositCustomer({
  phoneNumber,
  amount,
  description,
}) {
  const response =
    await api.post(
      "/agent/deposit",
      {
        phone_number:
          phoneNumber,

        amount:
          Number(amount),

        description:
          description ||
          "Cash deposit by agent",
      }
    );

  return response.data;
}


export async function getAgentTransactions() {
  const response =
    await api.get(
      "/agent/transactions"
    );

  return response.data;
}
