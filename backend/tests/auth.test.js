const request = require("supertest");
const app = require("../src/app");
const { pool } = require("../src/config/db");
const bcrypt = require("bcryptjs");

jest.mock("../src/config/db", () => ({
  pool: {
    execute: jest.fn(),
  },
}));

describe("Auth API", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it("should register a new user", async () => {
    pool.execute.mockResolvedValueOnce([{ insertId: 1 }]); // insert user
    pool.execute.mockResolvedValueOnce([[ { id: 1, role: 'employee' } ]]); // fetch new user

    const res = await request(app)
      .post("/api/auth/register")
      .send({
        full_name_en: "Test User",
        username: "testuser",
        email: "test@example.com",
        password: "password123",
        role: "employee"
      });

    expect(res.statusCode).toEqual(201);
    expect(res.body.success).toBe(true);
    expect(res.body.user.id).toBe(1);
    expect(res.body.token).toBeDefined();
  });

  it("should return 400 if required fields are missing", async () => {
    const res = await request(app)
      .post("/api/auth/register")
      .send({
        full_name_en: "Test User"
      });

    expect(res.statusCode).toEqual(400);
    expect(res.body.success).toBe(false);
  });
});
