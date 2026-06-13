/*
 * Service worker do Make Bolão Great Again.
 *
 * Estratégia: NETWORK-FIRST para tudo que é do próprio domínio.
 *  - Online  -> sempre busca a versão mais nova do servidor (mata o problema
 *               do app "congelado" na versão da instalação).
 *  - Offline -> serve a última cópia em cache como fallback.
 *  - Requests cross-origin (Supabase, fontes) passam direto, sem cache.
 *
 * Atualização: instala com skipWaiting e assume o controle na hora
 * (clients.claim). O index.html detecta a troca de controlador e recarrega
 * uma vez, então a nova versão aparece sozinha ao reabrir o app.
 *
 * IMPORTANTE: bump CACHE_VERSION sempre que mudar a lógica deste arquivo.
 */
'use strict';

const CACHE_VERSION = 'v1';
const CACHE_NAME = 'mbga-' + CACHE_VERSION;

// App shell mínimo para o fallback offline. Os assets do Flutter (main.dart.js,
// canvaskit, etc.) têm nomes voláteis e são cacheados em runtime.
const SHELL = ['index.html', 'manifest.json'];

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    try {
      const cache = await caches.open(CACHE_NAME);
      // cache:'reload' garante que o shell venha do servidor, não do HTTP cache.
      await Promise.all(
        SHELL.map((url) => cache.add(new Request(url, { cache: 'reload' })).catch(() => {}))
      );
    } catch (e) {
      // Falha ao pré-cachear não deve impedir a instalação.
    }
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    // Remove caches de versões anteriores.
    const keys = await caches.keys();
    await Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)));
    await self.clients.claim();
  })());
});

self.addEventListener('message', (event) => {
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
  }
});

self.addEventListener('fetch', (event) => {
  const req = event.request;

  // Só lidamos com GET do mesmo domínio. O resto (POST, Supabase, fontes
  // do Google) passa direto pela rede, sem interceptação nem cache.
  if (req.method !== 'GET') return;

  let url;
  try {
    url = new URL(req.url);
  } catch (e) {
    return;
  }
  if (url.origin !== self.location.origin) return;

  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);
    try {
      // NETWORK-FIRST: a fonte da verdade é sempre o servidor.
      const fresh = await fetch(req);
      // Guarda uma cópia boa para uso offline.
      if (fresh && fresh.status === 200 && fresh.type === 'basic') {
        cache.put(req, fresh.clone());
      }
      return fresh;
    } catch (e) {
      // Sem rede: tenta o cache.
      const cached = await cache.match(req);
      if (cached) return cached;
      // Para navegações (SPA), cai no app shell.
      if (req.mode === 'navigate') {
        const shell = (await cache.match('index.html')) || (await cache.match('/'));
        if (shell) return shell;
      }
      throw e;
    }
  })());
});
