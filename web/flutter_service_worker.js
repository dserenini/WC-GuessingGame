/*
 * Stub de "cura" / migração.
 *
 * Versões antigas do app registravam um service worker do Flutter em
 * `flutter_service_worker.js` que cacheava tudo (cache-first) e deixava o app
 * preso na versão da instalação. Como o navegador continua checando o script
 * registrado por essa URL, mantemos este arquivo aqui para QUALQUER service
 * worker antigo se auto-desinstalar e o cliente recarregar limpo.
 *
 * O app novo NÃO registra este arquivo (build com --pwa-strategy=none). Ele
 * registra `sw.js`. Este stub existe só para libertar quem ficou preso.
 */
'use strict';

self.addEventListener('install', () => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    try {
      await self.registration.unregister();
    } catch (e) {
      console.warn('Falha ao desinstalar o service worker antigo:', e);
    }
    try {
      const clients = await self.clients.matchAll({ type: 'window' });
      // Recarrega os clientes para que parem de usar o SW antigo e baixem a
      // versão nova do servidor (que então registra o sw.js novo).
      clients.forEach((client) => {
        if (client.url && 'navigate' in client) {
          client.navigate(client.url);
        }
      });
    } catch (e) {
      console.warn('Falha ao recarregar clientes do service worker:', e);
    }
  })());
});
