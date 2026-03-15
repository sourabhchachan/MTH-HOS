import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { login as apiLogin, getMe } from './api';

const AuthContext = createContext(null);

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
    const token = localStorage.getItem('token');
    if (!token) {
      setLoading(false);
      return;
    }

    try {
      const response = await getMe();
      setUser(response.data);
    } catch (error) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    checkAuth();
  }, [checkAuth]);

  const login = async (phone, password) => {
    const response = await apiLogin(phone, password);
    const { access_token } = response.data;
    localStorage.setItem('token', access_token);
    
    const userResponse = await getMe();
    setUser(userResponse.data);
    localStorage.setItem('user', JSON.stringify(userResponse.data));
    
    return userResponse.data;
  };

  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
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
