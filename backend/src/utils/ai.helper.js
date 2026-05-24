// src/utils/ai.helper.js
const axios = require("axios");
const FormData = require("form-data");

const AI_BASE = process.env.AI_BASE_URL || "http://127.0.0.1:5000";
console.log(`[AI] Service URL: ${AI_BASE}`);

const forwardToAI = async (endpoint, imageBuffer, originalname, extraFields = {}) => {
  try {
    const form = new FormData();
    form.append("image", imageBuffer, { filename: originalname || "frame.jpg", contentType: "image/jpeg" });
    Object.entries(extraFields).forEach(([k, v]) => form.append(k, String(v)));

    const response = await axios.post(`${AI_BASE}${endpoint}`, form, {
      headers: form.getHeaders(),
      timeout: 60000,
    });
    return response.data;
  } catch (error) {
    if (error.code === "ECONNREFUSED") {
      const msg = "AI Service (Python) is NOT running. Please start it using 'python api/app.py' in the face_app directory.";
      console.error("❌ ERROR:", msg);
      throw new Error(msg);
    }
    if (error.response) {
      console.error("❌ AI Service Error:", error.response.status, error.response.statusText);
    } else {
      console.error("❌ AI Service Error:", error.message);
    }
    throw error;
  }
};

module.exports = { forwardToAI };
