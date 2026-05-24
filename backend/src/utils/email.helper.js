// src/utils/email.helper.js
const nodemailer = require("nodemailer");

// Create a transporter using environment variables
// Note: For Gmail, use App Passwords. For others, use SMTP details.
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || "smtp.gmail.com",
  port: process.env.EMAIL_PORT || 587,
  secure: process.env.EMAIL_SECURE === "true", // true for 465, false for other ports
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS,
  },
});

/**
 * Sends a welcome email to a newly added user
 * @param {string} to - User's email
 * @param {string} name - User's full name
 * @param {string} username - User's username
 * @param {string} password - User's temporary password
 * @param {string} adminName - Name of the admin who added them
 */
const sendWelcomeEmail = async (to, name, username, password, adminName) => {
  try {
    if (!process.env.EMAIL_USER || !process.env.EMAIL_PASS) {
      console.log("⚠️ Email credentials not set. Skipping email send.");
      console.log(`[MOCK EMAIL to ${to}]: Welcome ${name}! User: ${username}, Pass: ${password}, Added by: ${adminName}`);
      return;
    }

    const info = await transporter.sendMail({
      from: `"Vision Attendance" <${process.env.EMAIL_USER}>`,
      to: to,
      subject: "Welcome to Vision Attendance - Your Account is Ready!",
      html: `
        <div style="font-family: sans-serif; max-width: 600px; margin: auto; border: 1px solid #eee; padding: 20px; border-radius: 10px;">
          <h2 style="color: #3b82f6;">Welcome to Vision Attendance!</h2>
          <p>Hello <strong>${name}</strong>,</p>
          <p>Your account has been successfully created by <strong>${adminName}</strong>.</p>
          <p>You can now log in to our mobile app using the following credentials:</p>
          <div style="background: #f9fafb; padding: 15px; border-radius: 8px; margin: 20px 0;">
            <p style="margin: 5px 0;"><strong>Username:</strong> ${username}</p>
            <p style="margin: 5px 0;"><strong>Password:</strong> ${password}</p>
          </div>
          <p>Please change your password after your first login for better security.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin: 20px 0;" />
          <p style="font-size: 12px; color: #9ca3af;">This is an automated message. Please do not reply.</p>
        </div>
      `,
    });

    console.log("Message sent: %s", info.messageId);
  } catch (error) {
    console.error("Error sending email:", error);
  }
};

module.exports = { sendWelcomeEmail };
