// src/routes/payments.routes.js
const express = require("express");
const router = express.Router();
const paymentsController = require("../controllers/payments.controller");
const { authenticate } = require("../middleware/auth");

// Called by frontend to start a payment
router.post("/intent", authenticate, paymentsController.createPaymentIntent);

// Polling endpoint for frontend to check if webhook processed the payment
router.get("/status/:transaction_id", authenticate, paymentsController.checkPaymentStatus);

// Webhook endpoint for Payment Gateway (Paymob, Stripe, etc.)
// DO NOT protect this with JWT, it needs to be public for the gateway!
router.post("/webhook", paymentsController.paymentWebhook);

module.exports = router;
