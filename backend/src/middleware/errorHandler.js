// src/middleware/errorHandler.js
const errorHandler = (err, req, res, next) => {
  console.error("❌ Error:", err.stack || err.message);

  if (err.code === "ER_DUP_ENTRY") {
    return res.status(409).json({ success: false, message: "Duplicate entry - record already exists" });
  }
  if (err.name === "ValidationError") {
    return res.status(400).json({ success: false, message: err.message });
  }
  if (err.message === "Only image files are allowed (jpg, jpeg, png, webp)") {
    return res.status(400).json({ success: false, message: err.message });
  }

  res.status(err.status || 500).json({
    success: false,
    message: err.message || "Internal server error",
  });
};

module.exports = errorHandler;
