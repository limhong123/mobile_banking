import api from "./api";


// =====================================================
// CREATE CASH TRANSFER
// =====================================================

export async function createCashTransfer(
  data
) {
  const response =
    await api.post(
      "/cash-transfers/create",
      data
    );

  return response.data;
}


// =====================================================
// CHECK CASH PICKUP
// =====================================================

export async function checkCashPickup({
  code,
  receiverPhone,
}) {
  const response =
    await api.post(
      "/cash-transfers/cash-pickup/check",
      {
        code,
        receiver_phone:
          receiverPhone,
      }
    );

  return response.data;
}


// =====================================================
// CLAIM CASH
// =====================================================

export async function claimCashPickup({
  code,
  receiverPhone,
}) {
  const response =
    await api.post(
      "/cash-transfers/cash-pickup/claim",
      {
        code,
        receiver_phone:
          receiverPhone,
      }
    );

  return response.data;
}


// =====================================================
// HISTORY
// =====================================================

export async function getCashTransferHistory() {
  const response =
    await api.get(
      "/cash-transfers/agent/history"
    );

  return response.data;
}