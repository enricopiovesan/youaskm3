export type HostedGapErrorCode =
  | "HOSTED_GAP_REPORT_INVALID"
  | "HOSTED_GAP_ABUSE_CHALLENGE_FAILED"
  | "HOSTED_GAP_RATE_LIMITED"
  | "HOSTED_GAP_STORAGE_FAILED";

export type PublicGapReport = {
  schema_version: "public-gap-report/0.1.0";
  validation_version: "hosted-gap-collector/0.1.0";
  question: string;
  missing_knowledge: string;
  published_scope: string;
  checked_evidence: string[];
  source_url: string;
  submitted_at: string;
  reporter_context?: string;
};

export type PendingGapReportRecord = {
  reportId: string;
  collectorId: string;
  status: "pending";
  report: PublicGapReport;
  receivedAt: string;
  clientKey: string;
  origin: string;
};

export type HostedGapCollectorStorage = {
  countRecentReports(clientKey: string, sinceIso: string): Promise<number>;
  storePendingReport(record: PendingGapReportRecord): Promise<void>;
};

export type HostedGapCollectorConfig = {
  allowedOrigins: string[];
  collectorId: string;
  maxBodyBytes: number;
  rateLimitMax: number;
  rateLimitWindowSeconds: number;
  turnstileSecretKey?: string;
};

type HostedGapCollectorEnv = {
  GAP_REPORTS: D1DatabaseBinding;
  ALLOWED_ORIGINS: string;
  COLLECTOR_ID?: string;
  MAX_BODY_BYTES?: string;
  RATE_LIMIT_MAX?: string;
  RATE_LIMIT_WINDOW_SECONDS?: string;
  TURNSTILE_SECRET_KEY?: string;
};

export type D1DatabaseBinding = {
  prepare(query: string): D1PreparedStatementBinding;
};

type D1PreparedStatementBinding = {
  bind(...values: unknown[]): D1PreparedStatementBinding;
  first<T = unknown>(column?: string): Promise<T | null>;
  run(): Promise<unknown>;
};

type ChallengeVerifier = (token: string, request: Request, config: HostedGapCollectorConfig) => Promise<boolean>;
type ClientKeyHasher = (request: Request) => Promise<string>;
type IdFactory = () => string;
type Clock = () => Date;

type HostedGapCollectorDependencies = {
  storage: HostedGapCollectorStorage;
  config: HostedGapCollectorConfig;
  verifyChallenge?: ChallengeVerifier;
  clientKey?: ClientKeyHasher;
  createReportId?: IdFactory;
  now?: Clock;
};

type GapReportEnvelope = {
  report: PublicGapReport;
  challengeToken?: string;
};

const DEFAULT_MAX_BODY_BYTES = 8192;
const DEFAULT_RATE_LIMIT_MAX = 10;
const DEFAULT_RATE_LIMIT_WINDOW_SECONDS = 3600;
const VALIDATION_VERSION = "hosted-gap-collector/0.1.0";

export function createHostedGapCollectorHandler(dependencies: HostedGapCollectorDependencies) {
  return async function handleHostedGapCollectorRequest(request: Request): Promise<Response> {
    if (request.method === "OPTIONS") {
      return corsResponse(null, dependencies.config, request, 204);
    }

    if (request.method !== "POST") {
      return errorResponse("HOSTED_GAP_REPORT_INVALID", "Only POST submissions are accepted.", dependencies.config, request, 405);
    }

    const origin = request.headers.get("origin") ?? "";
    if (!originAllowed(origin, dependencies.config.allowedOrigins)) {
      return errorResponse("HOSTED_GAP_ABUSE_CHALLENGE_FAILED", "Origin is not allowed.", dependencies.config, request, 403);
    }

    const bodyText = await readBoundedBody(request, dependencies.config.maxBodyBytes);
    if (bodyText === null) {
      return errorResponse("HOSTED_GAP_REPORT_INVALID", "Public gap report exceeds the configured body limit.", dependencies.config, request, 413);
    }

    const envelope = parseGapReportEnvelope(bodyText);
    if (!envelope.ok) {
      return errorResponse("HOSTED_GAP_REPORT_INVALID", envelope.message, dependencies.config, request, 400);
    }

    if (dependencies.config.turnstileSecretKey) {
      const challengeToken = envelope.value.challengeToken;
      const verifyChallenge = dependencies.verifyChallenge ?? verifyTurnstileChallenge;
      if (!challengeToken || !(await verifyChallenge(challengeToken, request, dependencies.config))) {
        return errorResponse(
          "HOSTED_GAP_ABUSE_CHALLENGE_FAILED",
          "Abuse challenge verification failed.",
          dependencies.config,
          request,
          403
        );
      }
    }

    const clientKey = await (dependencies.clientKey ?? defaultClientKey)(request);
    const now = (dependencies.now ?? (() => new Date()))();
    const windowStart = new Date(now.getTime() - dependencies.config.rateLimitWindowSeconds * 1000).toISOString();

    try {
      const recentReports = await dependencies.storage.countRecentReports(clientKey, windowStart);
      if (recentReports >= dependencies.config.rateLimitMax) {
        return errorResponse(
          "HOSTED_GAP_RATE_LIMITED",
          "Hosted gap report rate limit exceeded.",
          dependencies.config,
          request,
          429
        );
      }

      const reportId = (dependencies.createReportId ?? defaultReportId)();
      const receivedAt = now.toISOString();
      await dependencies.storage.storePendingReport({
        reportId,
        collectorId: dependencies.config.collectorId,
        status: "pending",
        report: envelope.value.report,
        receivedAt,
        clientKey,
        origin
      });

      return corsResponse(
        {
          ok: true,
          code: "HOSTED_GAP_REPORT_ACCEPTED",
          report_id: reportId,
          status: "pending",
          validation_version: VALIDATION_VERSION,
          received_at: receivedAt
        },
        dependencies.config,
        request,
        202
      );
    } catch {
      return errorResponse(
        "HOSTED_GAP_STORAGE_FAILED",
        "Hosted gap collector could not store the pending report.",
        dependencies.config,
        request,
        500
      );
    }
  };
}

export function envToHostedGapCollectorConfig(env: HostedGapCollectorEnv): HostedGapCollectorConfig {
  return {
    allowedOrigins: env.ALLOWED_ORIGINS.split(",").map((origin) => origin.trim()).filter(Boolean),
    collectorId: env.COLLECTOR_ID ?? "youaskm3-hosted-gap-collector",
    maxBodyBytes: positiveInteger(env.MAX_BODY_BYTES, DEFAULT_MAX_BODY_BYTES),
    rateLimitMax: positiveInteger(env.RATE_LIMIT_MAX, DEFAULT_RATE_LIMIT_MAX),
    rateLimitWindowSeconds: positiveInteger(env.RATE_LIMIT_WINDOW_SECONDS, DEFAULT_RATE_LIMIT_WINDOW_SECONDS),
    ...(env.TURNSTILE_SECRET_KEY ? { turnstileSecretKey: env.TURNSTILE_SECRET_KEY } : {})
  };
}

export function d1HostedGapCollectorStorage(database: D1DatabaseBinding): HostedGapCollectorStorage {
  return {
    async countRecentReports(clientKey: string, sinceIso: string): Promise<number> {
      const count = await database
        .prepare("SELECT COUNT(*) AS count FROM pending_gap_reports WHERE client_key = ?1 AND received_at >= ?2")
        .bind(clientKey, sinceIso)
        .first<number>("count");
      return count ?? 0;
    },
    async storePendingReport(record: PendingGapReportRecord): Promise<void> {
      await database
        .prepare(
          `INSERT INTO pending_gap_reports (
            report_id,
            collector_id,
            status,
            schema_version,
            validation_version,
            question,
            missing_knowledge,
            published_scope,
            checked_evidence_json,
            source_url,
            submitted_at,
            reporter_context,
            received_at,
            client_key,
            origin
          ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14, ?15)`
        )
        .bind(
          record.reportId,
          record.collectorId,
          record.status,
          record.report.schema_version,
          record.report.validation_version,
          record.report.question,
          record.report.missing_knowledge,
          record.report.published_scope,
          JSON.stringify(record.report.checked_evidence),
          record.report.source_url,
          record.report.submitted_at,
          record.report.reporter_context ?? null,
          record.receivedAt,
          record.clientKey,
          record.origin
        )
        .run();
    }
  };
}

export default {
  async fetch(request: Request, env: HostedGapCollectorEnv): Promise<Response> {
    const handler = createHostedGapCollectorHandler({
      storage: d1HostedGapCollectorStorage(env.GAP_REPORTS),
      config: envToHostedGapCollectorConfig(env)
    });
    return handler(request);
  }
};

function parseGapReportEnvelope(bodyText: string): { ok: true; value: GapReportEnvelope } | { ok: false; message: string } {
  let value: unknown;
  try {
    value = JSON.parse(bodyText);
  } catch {
    return { ok: false, message: "Public gap report body must be valid JSON." };
  }

  const candidate = objectValue(value);
  if (!candidate) {
    return { ok: false, message: "Public gap report body must be an object." };
  }

  const reportCandidate = objectValue(candidate.report) ?? candidate;
  const challengeToken = stringField(candidate.challenge_token) ?? stringField(candidate.turnstile_token);
  const report = publicGapReport(reportCandidate);
  if (!report.ok) {
    return report;
  }

  return { ok: true, value: { report: report.value, ...(challengeToken ? { challengeToken } : {}) } };
}

function publicGapReport(value: Record<string, unknown>): { ok: true; value: PublicGapReport } | { ok: false; message: string } {
  const schemaVersion = stringField(value.schema_version);
  const validationVersion = stringField(value.validation_version);
  const question = boundedString(value.question, 1, 1000);
  const missingKnowledge = boundedString(value.missing_knowledge, 1, 2000);
  const publishedScope = boundedString(value.published_scope, 1, 500);
  const checkedEvidence = stringArray(value.checked_evidence, 20, 500);
  const sourceUrl = boundedString(value.source_url, 1, 2048);
  const submittedAt = stringField(value.submitted_at);
  const reporterContext = boundedString(value.reporter_context, 0, 2000);

  if (schemaVersion !== "public-gap-report/0.1.0") {
    return { ok: false, message: "Unsupported public gap report schema_version." };
  }
  if (validationVersion !== VALIDATION_VERSION) {
    return { ok: false, message: "Unsupported public gap report validation_version." };
  }
  if (!question || !missingKnowledge || !publishedScope || !checkedEvidence || !sourceUrl || !submittedAt) {
    return { ok: false, message: "Public gap report is missing required fields or exceeds field limits." };
  }
  if (!validUrl(sourceUrl) || Number.isNaN(Date.parse(submittedAt))) {
    return { ok: false, message: "Public gap report source_url or submitted_at is invalid." };
  }

  return {
    ok: true,
    value: {
      schema_version: "public-gap-report/0.1.0",
      validation_version: VALIDATION_VERSION,
      question,
      missing_knowledge: missingKnowledge,
      published_scope: publishedScope,
      checked_evidence: checkedEvidence,
      source_url: sourceUrl,
      submitted_at: submittedAt,
      ...(reporterContext ? { reporter_context: reporterContext } : {})
    }
  };
}

async function readBoundedBody(request: Request, maxBodyBytes: number): Promise<string | null> {
  const contentLength = request.headers.get("content-length");
  if (contentLength && Number(contentLength) > maxBodyBytes) {
    return null;
  }

  const bodyText = await request.text();
  return new TextEncoder().encode(bodyText).byteLength <= maxBodyBytes ? bodyText : null;
}

async function verifyTurnstileChallenge(
  token: string,
  request: Request,
  config: HostedGapCollectorConfig
): Promise<boolean> {
  const body = new FormData();
  body.set("secret", config.turnstileSecretKey ?? "");
  body.set("response", token);
  const remoteIp = request.headers.get("cf-connecting-ip");
  if (remoteIp) {
    body.set("remoteip", remoteIp);
  }

  const response = await fetch("https://challenges.cloudflare.com/turnstile/v0/siteverify", {
    method: "POST",
    body
  });
  const verification = objectValue(await response.json());
  return response.ok && verification?.success === true;
}

async function defaultClientKey(request: Request): Promise<string> {
  const source = [
    request.headers.get("cf-connecting-ip") ?? "unknown-ip",
    request.headers.get("origin") ?? "unknown-origin",
    request.headers.get("user-agent") ?? "unknown-agent"
  ].join("|");
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(source));
  return [...new Uint8Array(digest)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

function defaultReportId(): string {
  return `gap_${crypto.randomUUID()}`;
}

function errorResponse(
  code: HostedGapErrorCode,
  message: string,
  config: HostedGapCollectorConfig,
  request: Request,
  status: number
): Response {
  return corsResponse({ ok: false, code, message }, config, request, status);
}

function corsResponse(body: unknown, config: HostedGapCollectorConfig, request: Request, status: number): Response {
  const origin = request.headers.get("origin") ?? "";
  const headers = new Headers({
    "access-control-allow-methods": "POST, OPTIONS",
    "access-control-allow-headers": "content-type",
    "content-type": "application/json; charset=utf-8",
    vary: "Origin"
  });
  if (originAllowed(origin, config.allowedOrigins)) {
    headers.set("access-control-allow-origin", origin);
  }
  return new Response(body === null ? null : JSON.stringify(body), { status, headers });
}

function originAllowed(origin: string, allowedOrigins: string[]): boolean {
  return allowedOrigins.includes(origin);
}

function positiveInteger(value: string | undefined, fallback: number): number {
  if (!value) {
    return fallback;
  }
  const parsed = Number(value);
  return Number.isSafeInteger(parsed) && parsed > 0 ? parsed : fallback;
}

function objectValue(value: unknown): Record<string, unknown> | null {
  return typeof value === "object" && value !== null && !Array.isArray(value) ? (value as Record<string, unknown>) : null;
}

function stringField(value: unknown): string | undefined {
  return typeof value === "string" ? value.trim() : undefined;
}

function boundedString(value: unknown, minLength: number, maxLength: number): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }
  const trimmed = value.trim();
  return trimmed.length >= minLength && trimmed.length <= maxLength ? trimmed : undefined;
}

function stringArray(value: unknown, maxItems: number, maxItemLength: number): string[] | undefined {
  if (!Array.isArray(value) || value.length > maxItems) {
    return undefined;
  }
  const items = value.map((item) => boundedString(item, 1, maxItemLength));
  return items.every((item): item is string => Boolean(item)) ? items : undefined;
}

function validUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "https:" || url.protocol === "http:";
  } catch {
    return false;
  }
}
