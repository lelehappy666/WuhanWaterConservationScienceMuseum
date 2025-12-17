import React from 'react';
import { useLocation, useNavigate } from 'react-router-dom';
import { ChevronLeft, MoreHorizontal, Circle } from 'lucide-react';
import { DebugPanel } from './DebugPanel';

interface LayoutProps {
  children: React.ReactNode;
  title?: string;
  showBack?: boolean;
  actions?: React.ReactNode;
}

export const Layout: React.FC<LayoutProps> = ({ children, title = "Home", showBack = false, actions }) => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-ios-bg">
      {/* iOS Style Status Bar Placeholder (Visual only for web) */}
      <div className="h-[env(safe-area-inset-top)] w-full bg-white/80 backdrop-blur-md fixed top-0 z-50"></div>
      
      {/* Navigation Bar */}
      <header className="sticky top-0 z-40 bg-white/80 backdrop-blur-md border-b border-gray-200 px-4 h-14 flex items-center justify-between transition-all duration-300">
        <div className="flex-1 flex items-center justify-start">
          {showBack && (
            <button 
              onClick={() => navigate(-1)}
              className="p-2 -ml-2 rounded-full hover:bg-gray-100 active:bg-gray-200 transition-colors"
            >
              <ChevronLeft className="w-6 h-6 text-ios-text" />
            </button>
          )}
        </div>
        
        <div className="flex-1 flex justify-center">
          <h1 className="text-lg font-semibold text-ios-text truncate max-w-[200px]">{title}</h1>
        </div>
        
        <div className="flex-1 flex items-center justify-end space-x-2">
          {actions || (
            <>
              <button className="p-2 rounded-full hover:bg-gray-100">
                <MoreHorizontal className="w-5 h-5 text-ios-text" />
              </button>
              <button className="p-2 rounded-full hover:bg-gray-100">
                <Circle className="w-5 h-5 text-ios-text" />
              </button>
            </>
          )}
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-4 py-6 pb-20 safe-area-bottom">
        {children}
      </main>

      {/* Debug Panel - Shows connection status directly on screen */}
      <DebugPanel />
    </div>
  );
};
