export type ProviderProfile = {
  id: string;
  label: string;
  endpoint: string;
  auth: "none" | "api-key";
  modelHint: string;
  publishable: boolean;
};

export type ProviderConfig = {
  activeProviderId: string;
  profiles: ProviderProfile[];
};

export type AuthorInstanceManifest = {
  instanceId: string;
  title: string;
  shellUrl: string;
  providerProfiles: string[];
  knowledgeBase: string;
};

export const DEFAULT_PROVIDER_CONFIG: ProviderConfig = {
  activeProviderId: "browser-demo",
  profiles: [
    {
      id: "browser-demo",
      label: "Browser demo",
      endpoint: "local://browser-runtime",
      auth: "none",
      modelHint: "contract-shaped local adapter",
      publishable: true
    },
    {
      id: "claude-api",
      label: "Claude API",
      endpoint: "https://api.anthropic.com/v1/messages",
      auth: "api-key",
      modelHint: "claude-sonnet or later",
      publishable: false
    },
    {
      id: "openai-api",
      label: "OpenAI API",
      endpoint: "https://api.openai.com/v1/responses",
      auth: "api-key",
      modelHint: "gpt-5 or later",
      publishable: false
    }
  ]
};

export const DEFAULT_AUTHOR_INSTANCE: AuthorInstanceManifest = {
  instanceId: "youaskm3-author",
  title: "youaskm3 author instance",
  shellUrl: "https://enricopiovesan.github.io/youaskm3/",
  providerProfiles: ["browser-demo", "claude-api", "openai-api"],
  knowledgeBase: "knowledge/"
};

export function activeProvider(
  config: ProviderConfig
): ProviderProfile | undefined {
  return config.profiles.find((profile) => profile.id === config.activeProviderId);
}

export function providerOptionLabels(config: ProviderConfig): string[] {
  return config.profiles.map((profile) => profile.label);
}

export function updateActiveProvider(
  config: ProviderConfig,
  providerId: string
): ProviderConfig {
  if (!config.profiles.some((profile) => profile.id === providerId)) {
    throw new Error(`unknown provider profile: ${providerId}`);
  }

  return {
    ...config,
    activeProviderId: providerId
  };
}

export function providerSummary(config: ProviderConfig): string {
  const provider = activeProvider(config);
  if (!provider) {
    throw new Error("active provider is missing");
  }

  const authCopy =
    provider.auth === "api-key"
      ? "expects a user-supplied API key"
      : "runs without a remote API key";

  return `${provider.label} uses ${provider.endpoint}, ${authCopy}, and hints ${provider.modelHint}.`;
}
