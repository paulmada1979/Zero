import { authProxy } from '@/lib/auth-proxy';
import { LoginClient } from './login-client';
import { useLoaderData } from 'react-router';
import { redirect } from 'react-router';

export async function clientLoader({ request }: { request: Request }) {
  const session = await authProxy.api.getSession({ headers: request.headers });
  if (session?.user.id) throw redirect('/mail/inbox');

  const isProd = !import.meta.env.DEV;

  const response = await fetch(import.meta.env.VITE_PUBLIC_BACKEND_URL + '/api/public/providers');
  const data = (await response.json()) as { allProviders: unknown[] };

  return {
    allProviders: data.allProviders,
    isProd,
  };
}

export default function LoginPage() {
  const { allProviders, isProd } = useLoaderData<typeof clientLoader>();

  return (
    <div className="flex min-h-screen w-full flex-col bg-white dark:bg-black">
      <LoginClient providers={allProviders} isProd={isProd} />
    </div>
  );
}
