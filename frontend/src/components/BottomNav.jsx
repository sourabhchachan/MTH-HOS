import React from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { Home, ClipboardList, Package, User } from 'lucide-react';

const NAV_ITEMS = [
  { path: '/', icon: Home, label: 'Home' },
  { path: '/orders', icon: ClipboardList, label: 'Orders' },
  { path: '/dispatch', icon: Package, label: 'Dispatch' },
  { path: '/profile', icon: User, label: 'Profile' },
];

const BottomNav = () => {
  const navigate = useNavigate();
  const location = useLocation();

  // Don't show on login page, admin pages, reports, or system-test
  const hiddenPaths = ['/login', '/admin', '/reports', '/system-test', '/create-order', '/create-return', '/data-seed'];
  if (hiddenPaths.some(p => location.pathname.startsWith(p))) {
    return null;
  }

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-white border-t border-gray-200 safe-area-bottom">
      <div className="flex items-center justify-around h-16 max-w-lg mx-auto">
        {NAV_ITEMS.map((item) => {
          const isActive = location.pathname === item.path || 
            (item.path === '/orders' && location.pathname.startsWith('/orders')) ||
            (item.path === '/dispatch' && location.pathname === '/receive');
          
          return (
            <button
              key={item.path}
              onClick={() => navigate(item.path)}
              className={`flex flex-col items-center justify-center w-full h-full gap-1 transition-colors ${
                isActive 
                  ? 'text-orange-500' 
                  : 'text-gray-400 hover:text-gray-600 active:text-orange-400'
              }`}
              data-testid={`nav-${item.label.toLowerCase()}`}
            >
              <item.icon className={`w-6 h-6 ${isActive ? 'stroke-[2.5]' : ''}`} />
              <span className={`text-xs ${isActive ? 'font-semibold' : 'font-medium'}`}>
                {item.label}
              </span>
              {isActive && (
                <div className="absolute bottom-0 w-12 h-0.5 bg-orange-500 rounded-t-full" />
              )}
            </button>
          );
        })}
      </div>
    </nav>
  );
};

export default BottomNav;
