import axios from 'axios';

const API_URL = process.env.REACT_APP_BACKEND_URL;

// Token storage keys (matching AuthContext)
const TOKEN_KEY = 'mth_token';
const PERSIST_KEY = 'mth_persist';

// Helper to get token from appropriate storage
const getStoredToken = () => {
  const persist = localStorage.getItem(PERSIST_KEY) === 'true';
  if (persist) {
    return localStorage.getItem(TOKEN_KEY);
  }
  return sessionStorage.getItem(TOKEN_KEY) || localStorage.getItem(TOKEN_KEY);
};

// Helper to clear tokens
const clearTokens = () => {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem('mth_user');
  localStorage.removeItem(PERSIST_KEY);
  sessionStorage.removeItem(TOKEN_KEY);
  sessionStorage.removeItem('mth_user');
};

const api = axios.create({
  baseURL: `${API_URL}/api`,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = getStoredToken();
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor for error handling
api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.status === 401) {
      clearTokens();
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Auth
export const login = (phone, password) => api.post('/auth/login', { phone, password });
export const getMe = () => api.get('/auth/me');
export const changePassword = (currentPassword, newPassword) => 
  api.post('/auth/change-password', { current_password: currentPassword, new_password: newPassword });

// Dashboard
export const getDashboard = () => api.get('/dashboard');

// Departments
export const getDepartments = () => api.get('/departments');
export const createDepartment = (data) => api.post('/departments', data);
export const updateDepartment = (id, data) => api.put(`/departments/${id}`, data);

// Users
export const getUsers = () => api.get('/users');
export const createUser = (data) => api.post('/users', data);
export const updateUser = (id, data) => api.put(`/users/${id}`, data);

// Patients
export const getPatients = (search = '') => api.get('/patients', { params: { search } });
export const createPatient = (data) => api.post('/patients', data);
export const getPatient = (id) => api.get(`/patients/${id}`);

// IPD
export const getIPDs = (params = {}) => api.get('/ipd', { params });
export const createIPD = (data) => api.post('/ipd', data);
export const updateIPD = (id, data) => api.put(`/ipd/${id}`, data);

// Vendors
export const getVendors = () => api.get('/vendors');
export const createVendor = (data) => api.post('/vendors', data);

// Item Categories
export const getItemCategories = () => api.get('/item-categories');
export const createItemCategory = (data) => api.post('/item-categories', data);

// Items
export const getItems = (params = {}) => api.get('/items', { params });
export const getOrderableItems = () => api.get('/items/orderable');
export const createItem = (data) => api.post('/items', data);
export const updateItem = (id, data) => api.put(`/items/${id}`, data);

// Orders
export const getOrders = (params = {}) => api.get('/orders', { params });
export const getOrder = (id) => api.get(`/orders/${id}`);
export const createOrder = (data) => api.post('/orders', data);
export const cancelOrder = (id, reason) => api.put(`/orders/${id}/cancel`, null, { params: { reason } });

// Dispatch
export const getDispatchQueue = () => api.get('/dispatch-queue');
export const dispatchItem = (data) => api.post('/dispatch', data);

// Receive
export const getPendingReceive = () => api.get('/pending-receive');
export const receiveItem = (data) => api.post('/receive', data);

// Return Reasons
export const getReturnReasons = () => api.get('/return-reasons');
export const createReturnReason = (data) => api.post('/return-reasons', data);

// ============ Admin Setup APIs ============

// Vendors (Admin)
export const getAllVendors = () => api.get('/setup/vendors/all');
export const updateVendor = (id, data) => api.put(`/setup/vendors/${id}`, data);
export const toggleVendorActive = (id) => api.put(`/setup/vendors/${id}/toggle-active`);

// Departments (Admin)
export const getAllDepartments = () => api.get('/setup/departments/all');

// Items (Admin)
export const getAllItems = () => api.get('/setup/items/all');
export const getItemCSVTemplate = () => api.get('/setup/items/csv-template');
export const uploadItemsCSV = (file) => {
  const formData = new FormData();
  formData.append('file', file);
  return api.post('/setup/items/csv-upload', formData, {
    headers: { 'Content-Type': 'multipart/form-data' }
  });
};

// Users (Admin)
export const getAllUsers = () => api.get('/setup/users/all');
export const resetUserPassword = (id, password) => api.put(`/setup/users/${id}/reset-password`, { new_password: password });

// Patients (Admin)
export const getAllPatients = (search = '') => api.get('/setup/patients', { params: { search } });
export const createPatientAdmin = (data) => api.post('/setup/patients', data);
export const updatePatientAdmin = (id, data) => api.put(`/setup/patients/${id}`, data);

// Assets
export const getAssets = (params = {}) => api.get('/assets', { params });
export const createAsset = (data) => api.post('/assets', data);
export const updateAsset = (id, data) => api.put(`/assets/${id}`, data);
export const getMaintenanceDue = (daysAhead = 7) => api.get('/assets/maintenance-due', { params: { days_ahead: daysAhead } });
export const recordMaintenance = (data) => api.post('/assets/maintenance', data);

// Seed categories
export const seedCategories = () => api.post('/setup/seed-categories');

// ============ Data Seeding APIs ============
export const getSeedStatus = () => api.get('/seed/status');
export const seedAllData = () => api.post('/seed/all');
export const seedDepartments = () => api.post('/seed/departments');
export const seedVendors = () => api.post('/seed/vendors');
export const seedCategoriesData = () => api.post('/seed/categories');

export default api;
