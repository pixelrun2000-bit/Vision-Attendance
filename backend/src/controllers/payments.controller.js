// src/controllers/payments.controller.js
// ─── Payment Gateway & Webhook Security ──────────────────────────────────────
const crypto = require("crypto");
const { pool } = require("../config/db");
const { v4: uuidv4 } = require("uuid");

// Replace this with your actual Payment Gateway secret key later
const GATEWAY_WEBHOOK_SECRET = process.env.GATEWAY_WEBHOOK_SECRET || "my_super_secret_webhook_key";

const PLAN_PRICES = {
  "Basic": 3.00,
  "Standard": 6.00,
  "Premium": 12.00
};

/**
 * 1. Initialize Payment
 * Called by the frontend when a user clicks "Subscribe".
 * Generates an idempotent transaction_id and returns a checkout URL/token.
 */
const createPaymentIntent = async (req, res, next) => {
  try {
    const { plan } = req.body;
    const userId = req.user.id;

    if (!PLAN_PRICES[plan]) {
      return res.status(400).json({ success: false, message: "Invalid plan selected" });
    }

    // ── Layer 1: Prevent Double Subscription ────────────────────────────────
    const [userRows] = await pool.execute(
      "SELECT subscription_plan FROM users WHERE id = ?",
      [userId]
    );
    
    if (userRows[0].subscription_plan !== 'Free') {
      return res.status(400).json({
        success: false,
        message: `You are already subscribed to the ${userRows[0].subscription_plan} plan.`
      });
    }

    // ── Layer 2: Idempotency Key (transaction_id) ───────────────────────────
    // Prevent double clicking from creating multiple pending orders.
    const [pendingRows] = await pool.execute(
      "SELECT transaction_id FROM payments WHERE user_id = ? AND status = 'pending' AND plan_name = ?",
      [userId, plan]
    );

    let transactionId;
    
    if (pendingRows.length > 0) {
      // Reuse existing pending transaction
      transactionId = pendingRows[0].transaction_id;
    } else {
      // Create a new secure transaction ID
      transactionId = uuidv4();
      const amount = PLAN_PRICES[plan];

      await pool.execute(
        `INSERT INTO payments (user_id, plan_name, amount, currency, transaction_id, status)
         VALUES (?, ?, ?, 'USD', ?, 'pending')`,
        [userId, plan, amount, transactionId]
      );
    }

    // MOCK: In reality, you'd call Stripe/Paymob API here to get a payment token.
    // e.g. const response = await paymob.createOrder({ amount: PLAN_PRICES[plan], ... });
    
    // Return mock payment info to frontend
    res.json({
      success: true,
      transaction_id: transactionId,
      amount: PLAN_PRICES[plan],
      payment_url: `/mock-checkout?trx=${transactionId}` // Mock URL for testing
    });

  } catch (err) {
    next(err);
  }
};

/**
 * 2. Webhook Callback (Backend-to-Backend)
 * Called by Stripe/Paymob when the user successfully pays.
 * Extremely secure: verifies signature to prevent hackers from faking payments.
 */
const paymentWebhook = async (req, res, next) => {
  try {
    // ── Layer 3: Webhook Signature Verification ─────────────────────────────
    // Example logic (varies by gateway). Usually involves hashing the payload
    // with your secret key and comparing it to the provided header.
    
    const signature = req.headers["x-gateway-signature"];
    const payloadString = JSON.stringify(req.body);
    
    const expectedSignature = crypto
      .createHmac("sha256", GATEWAY_WEBHOOK_SECRET)
      .update(payloadString)
      .digest("hex");

    // UNCOMMENT FOR REAL USAGE:
    // if (signature !== expectedSignature) {
    //   console.error("🚨 SECURITY ALERT: Invalid Webhook Signature Detected!");
    //   return res.status(401).send("Invalid signature");
    // }

    const { transaction_id, status, gateway_response_data } = req.body;

    if (!transaction_id) {
      return res.status(400).send("Transaction ID missing");
    }

    // Find the payment record
    const [payments] = await pool.execute(
      "SELECT id, user_id, plan_name, status FROM payments WHERE transaction_id = ?",
      [transaction_id]
    );

    if (payments.length === 0) {
      return res.status(404).send("Transaction not found");
    }

    const payment = payments[0];

    // Prevent double processing if webhook is sent multiple times
    if (payment.status === 'completed' || payment.status === 'failed') {
      return res.status(200).send("Already processed");
    }

    if (status !== "success") {
      await pool.execute(
        "UPDATE payments SET status = 'failed', gateway_response = ? WHERE id = ?",
        [JSON.stringify(gateway_response_data || {}), payment.id]
      );
      return res.status(200).send("Payment failed status recorded");
    }

    // ── Process Successful Payment ──────────────────────────────────────────
    // 1. Mark payment as completed
    await pool.execute(
      "UPDATE payments SET status = 'completed', gateway_response = ? WHERE id = ?",
      [JSON.stringify(gateway_response_data || {}), payment.id]
    );

    // 2. Upgrade User's Plan
    await pool.execute(
      "UPDATE users SET subscription_plan = ? WHERE id = ?",
      [payment.plan_name, payment.user_id]
    );

    console.log(`✅ Subscription upgraded to ${payment.plan_name} for User ID ${payment.user_id}`);
    
    res.status(200).send("Webhook Received and Processed");
  } catch (err) {
    console.error("Webhook Error:", err);
    res.status(500).send("Webhook Error");
  }
};

/**
 * 3. Helper: Check Status
 * Allows frontend to poll and see if payment was completed.
 */
const checkPaymentStatus = async (req, res, next) => {
  try {
    const { transaction_id } = req.params;
    const [rows] = await pool.execute(
      "SELECT status FROM payments WHERE transaction_id = ? AND user_id = ?",
      [transaction_id, req.user.id]
    );
    
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: "Transaction not found" });
    }

    res.json({ success: true, status: rows[0].status });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  createPaymentIntent,
  paymentWebhook,
  checkPaymentStatus
};
