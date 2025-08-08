import { env } from '../env';

// KV-based storage adapter for Better Auth
export const createKVStorage = () => {
  return {
    get: async (key: string) => {
      try {
        const value = await env.prompts_storage.get(key);
        return value;
      } catch (error) {
        console.error('KV get error:', error);
        return null;
      }
    },
    set: async (key: string, value: string, ttl?: number) => {
      try {
        // KV doesn't support TTL in the same way as Redis
        // We'll store the value with expiration metadata
        const data = {
          value,
          expiresAt: ttl ? Date.now() + ttl * 1000 : null,
        };
        await env.prompts_storage.put(key, JSON.stringify(data));
      } catch (error) {
        console.error('KV set error:', error);
      }
    },
    delete: async (key: string) => {
      try {
        await env.prompts_storage.delete(key);
      } catch (error) {
        console.error('KV delete error:', error);
      }
    },
  };
};

// Enhanced KV storage with TTL support
export const createEnhancedKVStorage = () => {
  return {
    get: async (key: string) => {
      try {
        const data = await env.prompts_storage.get(key);
        if (!data) return null;

        const parsed = JSON.parse(data);

        // Check if expired
        if (parsed.expiresAt && Date.now() > parsed.expiresAt) {
          await env.prompts_storage.delete(key);
          return null;
        }

        return parsed.value;
      } catch (error) {
        console.error('Enhanced KV get error:', error);
        return null;
      }
    },
    set: async (key: string, value: string, ttl?: number) => {
      try {
        const data = {
          value,
          expiresAt: ttl ? Date.now() + ttl * 1000 : null,
        };
        await env.prompts_storage.put(key, JSON.stringify(data));
      } catch (error) {
        console.error('Enhanced KV set error:', error);
      }
    },
    delete: async (key: string) => {
      try {
        await env.prompts_storage.delete(key);
      } catch (error) {
        console.error('Enhanced KV delete error:', error);
      }
    },
  };
};
