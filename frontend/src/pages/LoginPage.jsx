import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Checkbox } from '@/components/ui/checkbox';
import { Phone, Lock, AlertCircle } from 'lucide-react';

const LoginPage = () => {
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { login } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);

    try {
      await login(phone, password, rememberMe);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.detail || 'Login failed. Please check your credentials.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col bg-white safe-area-top safe-area-bottom">
      {/* Main content - centered vertically */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 py-8">
        <div className="w-full max-w-sm space-y-8">
          {/* Logo & Title - Clean, minimal */}
          <div className="text-center space-y-2">
            <h1 className="text-5xl font-bold text-orange-500 tracking-tight">MTH</h1>
          </div>

          {/* Login Form */}
          <form onSubmit={handleSubmit} className="space-y-5">
            {error && (
              <div className="flex items-center gap-3 p-4 rounded-xl bg-red-50 text-red-600 text-sm">
                <AlertCircle className="w-5 h-5 flex-shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <div className="space-y-2">
              <Label htmlFor="phone" className="text-sm font-medium text-gray-700">Phone Number</Label>
              <div className="relative">
                <Phone className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <Input
                  id="phone"
                  type="tel"
                  inputMode="numeric"
                  placeholder="Enter phone number"
                  value={phone}
                  onChange={(e) => setPhone(e.target.value)}
                  className="pl-12 h-14 text-base bg-gray-50 border-gray-200 rounded-xl focus:bg-white focus:border-orange-500 focus:ring-orange-500"
                  required
                  autoComplete="tel"
                  data-testid="login-phone-input"
                />
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="password" className="text-sm font-medium text-gray-700">Password</Label>
              <div className="relative">
                <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400" />
                <Input
                  id="password"
                  type="password"
                  placeholder="Enter password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="pl-12 h-14 text-base bg-gray-50 border-gray-200 rounded-xl focus:bg-white focus:border-orange-500 focus:ring-orange-500"
                  required
                  autoComplete="current-password"
                  data-testid="login-password-input"
                />
              </div>
            </div>

            {/* Keep me signed in checkbox */}
            <div className="flex items-center space-x-3">
              <Checkbox 
                id="remember" 
                checked={rememberMe} 
                onCheckedChange={setRememberMe}
                className="w-5 h-5 border-gray-300 data-[state=checked]:bg-orange-500 data-[state=checked]:border-orange-500"
                data-testid="remember-me-checkbox"
              />
              <Label 
                htmlFor="remember" 
                className="text-sm text-gray-600 cursor-pointer select-none"
              >
                Keep me signed in
              </Label>
            </div>

            <Button 
              type="submit" 
              className="w-full h-14 text-base font-semibold rounded-xl bg-orange-500 hover:bg-orange-600 active:bg-orange-700 text-white shadow-lg shadow-orange-500/25 transition-all duration-200 active:scale-[0.98]"
              disabled={loading}
              data-testid="login-submit-btn"
            >
              {loading ? (
                <div className="flex items-center gap-2">
                  <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  <span>Signing in...</span>
                </div>
              ) : (
                'Sign In'
              )}
            </Button>
          </form>
        </div>
      </div>

      {/* Demo credentials - at bottom */}
      <div className="pb-6 px-6">
        <div className="text-center text-xs text-gray-400 space-y-0.5">
          <p>Demo: 1234567890 / admin123</p>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
