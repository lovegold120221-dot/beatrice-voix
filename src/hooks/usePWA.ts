import { useState, useEffect, useCallback } from 'react';
import { APP_VERSION, setInstalledVersion, getInstalledVersion, isUpdateAvailable, needsInitialInstall } from '../version';

export type PWAMode = 'loading' | 'install' | 'update' | 'current';

export function usePWA() {
  const [mode, setMode] = useState<PWAMode>('loading');
  const [deferredPrompt, setDeferredPrompt] = useState<any>(null);
  const [swRegistration, setSwRegistration] = useState<ServiceWorkerRegistration | null>(null);

  const isStandalone = typeof window !== 'undefined' && (
    window.matchMedia('(display-mode: standalone)').matches ||
    (window.navigator as any).standalone
  );

  const checkVersion = useCallback((reg?: ServiceWorkerRegistration) => {
    const registration = reg || swRegistration;
    if (registration?.active) {
      registration.active.postMessage({ type: 'CHECK_VERSION', version: APP_VERSION });
    }
  }, [swRegistration]);

  useEffect(() => {
    if (!('serviceWorker' in navigator)) {
      setMode('current');
      return;
    }

    // Detect install prompt
    const handleBeforeInstall = (e: any) => {
      e.preventDefault();
      setDeferredPrompt(e);
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstall);

    // Register SW and listen for updates
    navigator.serviceWorker.register('/sw.js')
      .then((reg) => {
        setSwRegistration(reg);

        // Listen for update found
        reg.addEventListener('updatefound', () => {
          const newWorker = reg.installing;
          if (newWorker) {
            newWorker.addEventListener('statechange', () => {
              if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
                setMode('update');
              }
            });
          }
        });

        // Listen for messages from SW (version response)
        navigator.serviceWorker.addEventListener('message', (event) => {
          if (event.data?.type === 'VERSION_RESPONSE') {
            if (event.data.updateAvailable) {
              setMode('update');
            }
          }
        });

        // If SW is already active, check version
        if (reg.active) {
          reg.active.postMessage({ type: 'CHECK_VERSION', version: APP_VERSION });
        }
      })
      .catch(() => {});

    return () => {
      window.removeEventListener('beforeinstallprompt', handleBeforeInstall);
    };
  }, []);

  // Determine final mode after loading
  useEffect(() => {
    if (mode !== 'loading') return;

    if (isStandalone) {
      if (isUpdateAvailable()) {
        setMode('update');
      } else {
        setMode('current');
      }
    } else {
      if (deferredPrompt) {
        setMode('install');
      } else {
        setMode('current');
      }
    }
  }, [isStandalone, deferredPrompt, mode]);

  const install = useCallback(async () => {
    if (!deferredPrompt) return;
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    if (outcome === 'accepted') {
      setInstalledVersion(APP_VERSION);
      setDeferredPrompt(null);
      setMode('current');
    }
  }, [deferredPrompt]);

  const dismissInstall = useCallback(() => {
    setDeferredPrompt(null);
    setMode('current');
  }, []);

  const dismissUpdate = useCallback(() => {
    setMode('current');
  }, []);

  const triggerUpdate = useCallback(() => {
    if (swRegistration?.waiting) {
      swRegistration.waiting.postMessage({ type: 'SKIP_WAITING' });
    }
    window.location.reload();
  }, [swRegistration]);

  // Track install success on standalone
  useEffect(() => {
    if (isStandalone && needsInitialInstall()) {
      setInstalledVersion(APP_VERSION);
    }
  }, [isStandalone]);

  return {
    mode,
    isStandalone,
    install,
    dismissInstall,
    dismissUpdate,
    triggerUpdate,
    deferredPrompt,
  };
}
