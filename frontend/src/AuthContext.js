import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { login as apiLogin, getMe } from './api';

const AuthContext = createContext(null);

// Storage key constants
const TOKEN_KEY = 'mth_token';
const USER_KEY = 'mth_user';
const PERSIST_KEY = 'mth_persist';

// Helper to get token from appropriate storage
const getStoredToken = () => {
  const persist = localStorage.getItem(PERSIST_KEY) === 'true';
  if (persist) {
    return localStorage.getItem(TOKEN_KEY);
  }
  return sessionStorage.getItem(TOKEN_KEY) || localStorage.getItem(TOKEN_KEY);
};

// Helper to store token
const storeToken = (token, persist) => {
  if (persist) {
    localStorage.setItem(TOKEN_KEY, token);
    localStorage.setItem(PERSIST_KEY, 'true');
    sessionStorage.removeItem(TOKEN_KEY);
  } else {
    sessionStorage.setItem(TOKEN_KEY, token);
    localStorage.removeItem(TOKEN_KEY);
    localStorage.removeItem(PERSIST_KEY);
  }
};

// Helper to clear tokens
const clearTokens = () => {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(USER_KEY);
  localStorage.removeItem(PERSIST_KEY);
  sessionStorage.removeItem(TOKEN_KEY);
  sessionStorage.removeItem(USER_KEY);
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within AuthProvider');
  }
  return context;
};

export const AuthProvider = ({ children }) => {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  const checkAuth = useCallback(async () => {
    const token = getStoredToken();
    if (!token) {
      setLoading(false);
      return;
    }

    try {
      const response = await getMe();
      setUser(response.data);
    } catch (error) {
      clearTokens();
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  const login = async (phone, password, rememberMe = false) => {
    const response = await apiLogin(phone, password);
    const { access_token } = response.data;
    
    // Store token based on "Keep me signed in" preference
    storeToken(access_token, rememberMe);
    
    const userResponse = await getMe();
    setUser(userResponse.data);
    
    // Store user data
    const storage = rememberMe ? localStorage : sessionStorage;
    storage.setItem(USER_KEY, JSON.stringify(userResponse.data));
    
    return userResponse.data;
  };

  const logout = () => {
    clearTokens();
    setUser(null);
  };

  const getUserDepartments = () => {
    if (!user) return [];
    const depts = [user.primary_department_id];
    if (user.secondary_departments) {
      user.secondary_departments.forEach(d => depts.push(d.id));
    }
    return depts;
  };

  return (
    <AuthContext.Provider value={{ 
      user, 
      loading, 
      login, 
      logout, 
      isAdmin: user?.is_admin || false,
      canViewCosts: user?.can_view_costs || false,
      getUserDepartments
    }}>
      {children}
    </AuthContext.Provider>
  );
};
