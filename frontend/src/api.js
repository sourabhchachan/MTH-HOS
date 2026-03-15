import axios from 'axios';

const API_URL = process.env.REACT_APP_BACKEND_URL;

const api = axios.create({
  baseURL: `${API_URL}/api`,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor to add auth token
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('token');
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
      localStorage.removeItem('token');
      localStorage.removeItem('user');
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

export default api;
