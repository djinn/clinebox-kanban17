import { DurableObject } from 'cloudflare:workers';

export interface Env {
  KANBAN_SERVICE: DurableObjectNamespace<KanbanService>;
  ASSETS: Fetcher;
  DB: D1Database;
  KANBAN_KV: KVNamespace;
  APP_NAME: string;
  ENVIRONMENT?: string;
}

export class KanbanService extends DurableObject {
  async fetch(request: Request): Promise<Response> {
    // Proxy to the internal kanban server running in this DO's container
    const url = new URL(request.url);
    const upstream = new Request('http://localhost:3484' + url.pathname + url.search, {
      method: request.method,
      headers: request.headers,
      body: request.body,
    });
    try {
      return await fetch(upstream);
    } catch (err) {
      return new Response('Kanban unavailable', { status: 502 });
    }
  }
}

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === 'GET' && url.pathname === '/api/health') {
      return new Response(
        JSON.stringify({ status: 'ok', service: 'clinebox-kanban', environment: env.ENVIRONMENT || 'production', timestamp: new Date().toISOString() }),
        { status: 200, headers: { 'Content-Type': 'application/json' } },
      );
    }

    // For kanban paths, proxy to the DO container
    if (url.pathname === '/' || url.pathname.startsWith('/api/') || url.pathname.startsWith('/assets/')) {
      const id = env.KANBAN_SERVICE.idFromName('default');
      const stub = env.KANBAN_SERVICE.get(id);
      try {
        return await stub.fetch(request);
      } catch {
        // Fall through to assets
      }
    }

    try {
      const asset = await env.ASSETS.fetch(request);
      if (asset.status === 200) return asset;
    } catch {}

    return new Response('Not Found', { status: 404 });
  },
} satisfies ExportedHandler<Env>;
