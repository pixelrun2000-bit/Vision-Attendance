const request = require("supertest");
const app = require("../src/app");

describe("Health Check API", () => {
  it("should return 200 OK for /health", async () => {
    const res = await request(app).get("/health");
    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.service).toBe("Vision Attendance Backend");
  });

  it("should return 404 for unknown routes", async () => {
    const res = await request(app).get("/api/unknown");
    expect(res.statusCode).toEqual(404);
    expect(res.body.success).toBe(false);
  });
});
