export const IS_APP_FREE = true;
export const HIDE_OPENSOURCE = true;

// Feature flags that control app behavior
export const APP_CONFIG = {
  isFree: IS_APP_FREE,
  // When app is free, all features are unlimited
  features: {
    connections: {
      unlimited: IS_APP_FREE,
      maxConnections: IS_APP_FREE ? Infinity : 1,
      enabled: IS_APP_FREE, // Add enabled property for connections
    },
    aiChat: {
      unlimited: IS_APP_FREE,
      enabled: IS_APP_FREE,
    },
    brainActivity: {
      unlimited: IS_APP_FREE,
      enabled: IS_APP_FREE,
    },
  },
  // Server-side feature controls
  server: {
    allowUnlimitedConnections: IS_APP_FREE,
    allowAllAIFeatures: IS_APP_FREE,
    allowAllBrainFeatures: IS_APP_FREE,
    bypassSubscriptionChecks: IS_APP_FREE,
  },
} as const;

export type AppConfig = typeof APP_CONFIG;

// Helper functions for server-side feature checks
export const isFeatureEnabled = (feature: keyof typeof APP_CONFIG.features) => {
  return APP_CONFIG.features[feature].enabled;
};

export const isFeatureUnlimited = (feature: keyof typeof APP_CONFIG.features) => {
  return APP_CONFIG.features[feature].unlimited;
};

export const canCreateConnection = (currentConnections: number) => {
  if (APP_CONFIG.server.allowUnlimitedConnections) return true;
  return currentConnections < APP_CONFIG.features.connections.maxConnections;
};

export const canUseAIFeature = () => {
  return APP_CONFIG.server.allowAllAIFeatures;
};

export const canUseBrainFeature = () => {
  return APP_CONFIG.server.allowAllBrainFeatures;
};
