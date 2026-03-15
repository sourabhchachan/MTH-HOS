import React from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../AuthContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { 
  User, Phone, Building2, Shield, LogOut, Settings, 
  ChevronRight, BarChart3, Key
} from 'lucide-react';

const ProfilePage = () => {
  const navigate = useNavigate();
  const { user, logout, isAdmin, canViewCosts } = useAuth();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-gray-50 pb-24 safe-area-top">
      {/* Header */}
      <header className="bg-white border-b border-gray-100 px-4 py-4">
        <div className="flex items-center gap-3">
          <h1 className="text-xl font-bold text-orange-500">MTH</h1>
          <span className="text-gray-300">|</span>
          <span className="font-semibold text-gray-700">Profile</span>
        </div>
      </header>

      <main className="px-4 py-4 space-y-4">
        {/* User Info Card */}
        <Card className="border-gray-200 bg-white">
          <CardContent className="p-5">
            <div className="flex items-center gap-4">
              <div className="w-16 h-16 rounded-full bg-orange-100 flex items-center justify-center">
                <User className="w-8 h-8 text-orange-500" />
              </div>
              <div className="flex-1">
                <h2 className="text-xl font-semibold text-gray-900">{user?.name}</h2>
                <p className="text-sm text-gray-500">{user?.designation || 'Staff'}</p>
                <div className="flex items-center gap-2 mt-1">
                  {isAdmin && (
                    <Badge className="bg-orange-100 text-orange-700 border-orange-200">
                      Admin
                    </Badge>
                  )}
                  {canViewCosts && (
                    <Badge variant="outline" className="text-gray-600 border-gray-300">
                      Cost Access
                    </Badge>
                  )}
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Contact Info */}
        <Card className="border-gray-200 bg-white">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">Contact Information</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-gray-100 flex items-center justify-center">
                <Phone className="w-5 h-5 text-gray-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Phone Number</p>
                <p className="font-medium text-gray-900">{user?.phone || 'Not set'}</p>
              </div>
            </div>
            {user?.email && (
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-gray-100 flex items-center justify-center">
                  <span className="text-gray-600">@</span>
                </div>
                <div>
                  <p className="text-sm text-gray-500">Email</p>
                  <p className="font-medium text-gray-900">{user.email}</p>
                </div>
              </div>
            )}
            {user?.employee_code && (
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-lg bg-gray-100 flex items-center justify-center">
                  <Key className="w-5 h-5 text-gray-600" />
                </div>
                <div>
                  <p className="text-sm text-gray-500">Employee Code</p>
                  <p className="font-medium text-gray-900">{user.employee_code}</p>
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Department Info */}
        <Card className="border-gray-200 bg-white">
          <CardHeader className="pb-2">
            <CardTitle className="text-sm font-medium text-gray-500">Department</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-lg bg-orange-100 flex items-center justify-center">
                <Building2 className="w-5 h-5 text-orange-600" />
              </div>
              <div>
                <p className="text-sm text-gray-500">Primary Department</p>
                <p className="font-medium text-gray-900">
                  {user?.primary_department?.name || 'Not assigned'}
                </p>
              </div>
            </div>
            {user?.secondary_departments?.length > 0 && (
              <div>
                <p className="text-sm text-gray-500 mb-2">Secondary Departments</p>
                <div className="flex flex-wrap gap-2">
                  {user.secondary_departments.map((sd, idx) => (
                    <Badge key={idx} variant="outline" className="text-gray-600 border-gray-300">
                      {sd.department?.name || sd.name}
                    </Badge>
                  ))}
                </div>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Quick Actions */}
        {isAdmin && (
          <Card className="border-gray-200 bg-white">
            <CardHeader className="pb-2">
              <CardTitle className="text-sm font-medium text-gray-500">Admin Actions</CardTitle>
            </CardHeader>
            <CardContent className="space-y-1">
              <button
                onClick={() => navigate('/admin')}
                className="flex items-center justify-between w-full p-3 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <Settings className="w-5 h-5 text-gray-600" />
                  <span className="font-medium text-gray-900">Admin Setup</span>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400" />
              </button>
              <button
                onClick={() => navigate('/reports')}
                className="flex items-center justify-between w-full p-3 rounded-lg hover:bg-gray-50 transition-colors"
              >
                <div className="flex items-center gap-3">
                  <BarChart3 className="w-5 h-5 text-gray-600" />
                  <span className="font-medium text-gray-900">Reports & Analytics</span>
                </div>
                <ChevronRight className="w-5 h-5 text-gray-400" />
              </button>
            </CardContent>
          </Card>
        )}

        {/* Logout Button */}
        <Button 
          onClick={handleLogout}
          variant="outline"
          className="w-full h-14 border-red-200 text-red-600 hover:bg-red-50 hover:border-red-300"
          data-testid="logout-btn"
        >
          <LogOut className="w-5 h-5 mr-2" />
          Sign Out
        </Button>

        {/* App Version */}
        <p className="text-center text-xs text-gray-400 pt-4">
          MTH Hospital Operations System v1.0
        </p>
      </main>
    </div>
  );
};

export default ProfilePage;
