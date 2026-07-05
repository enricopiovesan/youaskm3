import { describe, expect, it } from "vitest";

import {
  createHostedGapCollectorHandler,
  d1HostedGapCollectorStorage,
  envToHostedGapCollectorConfig,
  type D1DatabaseBinding,
  type HostedGapCollectorConfig,
  type HostedGapCollectorStorage,
  type PendingGapReportRecord,
  type PublicGapReport
} from "./worker";

const validReport: PublicGapReport = {
  schema_version: "public-gap-report/0.1.0",
  validation_version: "hosted-gap-collector/0.1.0",
  question: "What does this instance know about public collector setup?",
  missing_knowledge: "No public source explains the hosted collector deployment path.",
  published_scope: "youaskm3-public-demo",
  checked_evidence: ["search-index:0 results", "knowledge-graph:no matching node"],
  source_url: "https://example.test/chat?q=collector",
  submitted_at: "2026-07-05T12:00:00.000Z",
  reporter_context: "Visitor expected deployment notes."
};

const baseConfig = {
  allowedOrigins: ["https://example.test"],
  collectorId: "collector-test",
  maxBodyBytes: 4096,
  rateLimitMax: 2,
  rateLimitWindowSeconds: 3600,
  turnstileSecretKey: "turnstile-secret"
} satisfies HostedGapCollectorConfig;

const configWithoutChallenge: HostedGapCollectorConfig = {
  allowedOrigins: baseConfig.allowedOrigins,
  collectorId: baseConfig.collectorId,
  maxBodyBytes: baseConfig.maxBodyBytes,
  rateLimitMax: baseConfig.rateLimitMax,
  rateLimitWindowSeconds: baseConfig.rateLimitWindowSeconds
};

describe("hosted gap collector worker", () => {
  it("accepts a valid report, verifies challenge, and stores pending-only data", async () => {
    const storage = memoryStorage();
    const handler = createHostedGapCollectorHandler({
      storage,
      config: baseConfig,
      verifyChallenge: async (token) => token === "challenge-ok",
      clientKey: async () => "client-a",
      createReportId: () => "gap_test_1",
      now: () => new Date("2026-07-05T12:01:00.000Z")
    });

    const response = await handler(
      request({
        report: validReport,
        challenge_token: "challenge-ok"
      })
    );

    await expect(response.json()).resolves.toMatchObject({
      ok: true,
      code: "HOSTED_GAP_REPORT_ACCEPTED",
      report_id: "gap_test_1",
      status: "pending"
    });
    expect(response.status).toBe(202);
    expect(storage.records).toHaveLength(1);
    expect(storage.records[0]).toMatchObject({
      reportId: "gap_test_1",
      status: "pending",
      collectorId: "collector-test",
      clientKey: "client-a",
      origin: "https://example.test"
    });
    expect(storage.records[0]?.report).toMatchObject({
      schema_version: "public-gap-report/0.1.0",
      validation_version: "hosted-gap-collector/0.1.0",
      source_url: validReport.source_url,
      published_scope: validReport.published_scope,
      checked_evidence: validReport.checked_evidence,
      missing_knowledge: validReport.missing_knowledge,
      reporter_context: validReport.reporter_context
    });
    expect(JSON.stringify(storage.records[0])).not.toContain("imported");
  });

  it("rejects invalid payloads before storage", async () => {
    const storage = memoryStorage();
    const handler = createHostedGapCollectorHandler({
      storage,
      config: configWithoutChallenge,
      clientKey: async () => "client-a"
    });

    const response = await handler(request({ ...validReport, question: "" }));

    await expect(response.json()).resolves.toMatchObject({
      ok: false,
      code: "HOSTED_GAP_REPORT_INVALID"
    });
    expect(response.status).toBe(400);
    expect(storage.records).toHaveLength(0);
  });

  it("rejects oversized request bodies", async () => {
    const storage = memoryStorage();
    const handler = createHostedGapCollectorHandler({
      storage,
      config: { ...configWithoutChallenge, maxBodyBytes: 10 }
    });

    const response = await handler(request(validReport));

    await expect(response.json()).resolves.toMatchObject({
      ok: false,
      code: "HOSTED_GAP_REPORT_INVALID"
    });
    expect(response.status).toBe(413);
    expect(storage.records).toHaveLength(0);
  });

  it("rejects failed challenge and disallowed origins with stable abuse code", async () => {
    const failedChallenge = await createHostedGapCollectorHandler({
      storage: memoryStorage(),
      config: baseConfig,
      verifyChallenge: async () => false
    })(
      request({
        report: validReport,
        challenge_token: "bad-token"
      })
    );

    await expect(failedChallenge.json()).resolves.toMatchObject({
      ok: false,
      code: "HOSTED_GAP_ABUSE_CHALLENGE_FAILED"
    });
    expect(failedChallenge.status).toBe(403);

    const disallowedOrigin = await createHostedGapCollectorHandler({
      storage: memoryStorage(),
      config: configWithoutChallenge
    })(request(validReport, "https://evil.example"));

    await expect(disallowedOrigin.json()).resolves.toMatchObject({
      ok: false,
      code: "HOSTED_GAP_ABUSE_CHALLENGE_FAILED"
    });
    expect(disallowedOrigin.status).toBe(403);
  });

  it("rate limits before storing another pending report", async () => {
    const storage = memoryStorage();
    storage.recentCount = 2;
    const handler = createHostedGapCollectorHandler({
      storage,
      config: configWithoutChallenge,
      clientKey: async () => "client-a"
    });

    const response = await handler(request(validReport));

    await expect(response.json()).resolves.toMatchObject({
      ok: false,
      code: "HOSTED_GAP_RATE_LIMITED"
    });
    expect(response.status).toBe(429);
    expect(storage.records).toHaveLength(0);
  });

  it("maps storage failures to the stable storage code", async () => {
    const storage = memoryStorage();
    storage.failStore = true;
    const handler = createHostedGapCollectorHandler({
      storage,
      config: configWithoutChallenge,
      clientKey: async () => "client-a"
    });

    const response = await handler(request(validReport));

    await expect(response.json()).resolves.toMatchObject({
      ok: false,
      code: "HOSTED_GAP_STORAGE_FAILED"
    });
    expect(response.status).toBe(500);
  });

  it("adapts Cloudflare D1 storage without browser-facing secrets", async () => {
    const database = fakeD1();
    const storage = d1HostedGapCollectorStorage(database);

    await storage.storePendingReport({
      reportId: "gap_d1",
      collectorId: "collector-test",
      status: "pending",
      report: validReport,
      receivedAt: "2026-07-05T12:01:00.000Z",
      clientKey: "client-hash",
      origin: "https://example.test"
    });

    expect(database.insertValues).toContain("gap_d1");
    expect(database.insertValues).toContain("pending");
    expect(database.insertValues).toContain(validReport.validation_version);
    expect(database.insertValues.join(" ")).not.toContain("secret");
  });

  it("parses conservative deployment config from Worker environment", () => {
    expect(
      envToHostedGapCollectorConfig({
        GAP_REPORTS: fakeD1(),
        ALLOWED_ORIGINS: "https://example.test, https://www.example.test",
        COLLECTOR_ID: "collector-prod",
        MAX_BODY_BYTES: "2048",
        RATE_LIMIT_MAX: "5",
        RATE_LIMIT_WINDOW_SECONDS: "600"
      })
    ).toMatchObject({
      allowedOrigins: ["https://example.test", "https://www.example.test"],
      collectorId: "collector-prod",
      maxBodyBytes: 2048,
      rateLimitMax: 5,
      rateLimitWindowSeconds: 600
    });
  });
});

function request(body: unknown, origin = "https://example.test"): Request {
  return new Request("https://collector.example.test/gaps", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      origin
    },
    body: JSON.stringify(body)
  });
}

function memoryStorage(): HostedGapCollectorStorage & {
  records: PendingGapReportRecord[];
  recentCount: number;
  failStore: boolean;
} {
  return {
    records: [],
    recentCount: 0,
    failStore: false,
    async countRecentReports(): Promise<number> {
      return this.recentCount;
    },
    async storePendingReport(record: PendingGapReportRecord): Promise<void> {
      if (this.failStore) {
        throw new Error("storage unavailable");
      }
      this.records.push(record);
    }
  };
}

function fakeD1(): D1DatabaseBinding & { insertValues: unknown[] } {
  return {
    insertValues: [] as unknown[],
    prepare(query: string) {
      const statement = {
        bind: (...values: unknown[]) => {
          if (query.startsWith("INSERT")) {
            this.insertValues = values;
          }
          return statement;
        },
        first: async <T = unknown>() => 0 as T,
        run: async () => ({ success: true })
      };
      return statement;
    }
  };
}
