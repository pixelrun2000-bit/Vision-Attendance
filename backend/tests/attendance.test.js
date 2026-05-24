const request = require("supertest");
const app = require("../src/app");
const { pool } = require("../src/config/db");

jest.mock("../src/config/db", () => ({
  pool: {
    execute: jest.fn(),
  },
}));

describe("Attendance API", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("should return today status", async () => {
    pool.execute.mockResolvedValueOnce([[ { id: 1, status: 'present', checkin_time: new Date() } ]]);

    const res = await request(app)
      .get("/api/attendance/today")
      .set("Authorization", "Bearer fake-token"); // Middleware should handle or be mocked

    // Note: Since we haven't mocked the auth middleware, this might fail with 401.
    // Let's see how the auth middleware works.
  });
});
