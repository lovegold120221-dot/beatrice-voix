import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { RefreshCw, X } from 'lucide-react';
import { APP_VERSION } from '../version';

type Props = {
  visible: boolean;
  onDismiss: () => void;
  onUpdate: () => void;
};

export function PWAUpdatePrompt({ visible, onDismiss, onUpdate }: Props) {
  const [dismissed, setDismissed] = useState(false);

  const handleDismiss = () => {
    setDismissed(true);
    onDismiss();
  };

  return (
    <AnimatePresence>
      {visible && !dismissed && (
        <motion.div
          initial={{ opacity: 0, y: 50, scale: 0.95 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: 50, scale: 0.95 }}
          className="fixed bottom-24 left-4 right-4 z-[200] md:left-auto md:right-8 md:bottom-8 md:w-80"
        >
          <div className="bg-[#111111] border border-amber-500/20 rounded-[24px] shadow-[0_20px_50px_rgba(0,0,0,0.5)] p-5 flex flex-col gap-4 backdrop-blur-2xl">
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-amber-500/20 to-amber-600/10 flex items-center justify-center border border-amber-500/20">
                  <RefreshCw className="w-6 h-6 text-amber-400" />
                </div>
                <div className="flex flex-col">
                  <h3 className="text-[15px] font-bold text-white tracking-tight">Update Available</h3>
                  <p className="text-[11px] text-amber-400/80 font-medium uppercase tracking-wider">v{APP_VERSION}</p>
                </div>
              </div>
              <button
                onClick={handleDismiss}
                className="p-1.5 rounded-full hover:bg-white/5 text-zinc-500 transition-colors"
                aria-label="Dismiss"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <p className="text-xs text-zinc-300 leading-relaxed font-medium">
              A new version of Beatrice is ready. Refresh to get the latest features and improvements.
            </p>

            <button
              onClick={onUpdate}
              className="w-full bg-gradient-to-r from-amber-500 to-amber-600 text-black font-black py-3.5 rounded-2xl hover:brightness-110 active:scale-[0.98] transition-all text-xs uppercase tracking-[0.2em] shadow-lg shadow-amber-500/20 cursor-pointer"
            >
              Update Now
            </button>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
