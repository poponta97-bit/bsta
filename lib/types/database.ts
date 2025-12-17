export type UserRole = 'customer' | 'salon_staff' | 'distributor_staff' | 'admin';
export type SkinType = 'dry' | 'oily' | 'combination' | 'sensitive' | 'normal';
export type ConcernType = 'wrinkles' | 'acne' | 'pigmentation' | 'dryness' | 'sensitivity' | 'pores' | 'dullness' | 'sagging';

export interface Profile {
  id: string;
  email: string;
  full_name?: string;
  role: UserRole;
  phone?: string;
  avatar_url?: string;
  distributor_id?: string;
  salon_id?: string;
  created_at: string;
  updated_at: string;
}

export interface Distributor {
  id: string;
  name: string;
  code: string;
  address?: string;
  phone?: string;
  email?: string;
  representative_name?: string;
  created_at: string;
  updated_at: string;
}

export interface Salon {
  id: string;
  distributor_id?: string;
  name: string;
  code: string;
  address?: string;
  phone?: string;
  email?: string;
  opening_hours?: Record<string, any>;
  representative_name?: string;
  created_at: string;
  updated_at: string;
}

export interface Customer {
  id: string;
  salon_id?: string;
  profile_id?: string;
  customer_number: string;
  full_name: string;
  furigana?: string;
  gender?: string;
  date_of_birth?: string;
  phone?: string;
  email?: string;
  address?: string;
  postal_code?: string;
  occupation?: string;
  notes?: string;
  tags?: string[];
  created_at: string;
  updated_at: string;
}
