// Client-side configuration
// This should match the server-side config in apps/server/src/config.ts
export const IS_APP_FREE = true;
export const BRAND_NAME = 'Email';
export const HIDE_OPENSOURCE = true;

// Feature flags that control app behavior
export const APP_CONFIG = {
  isFree: IS_APP_FREE,
  // When app is free, all features are unlimited
  features: {
    connections: {
      unlimited: IS_APP_FREE,
      maxConnections: IS_APP_FREE ? Infinity : 1,
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
} as const;

export type AppConfig = typeof APP_CONFIG;
