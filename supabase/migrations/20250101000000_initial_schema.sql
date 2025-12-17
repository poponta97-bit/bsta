-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create enum types
CREATE TYPE user_role AS ENUM ('customer', 'salon_staff', 'distributor_staff', 'admin');
CREATE TYPE skin_type AS ENUM ('dry', 'oily', 'combination', 'sensitive', 'normal');
CREATE TYPE concern_type AS ENUM ('wrinkles', 'acne', 'pigmentation', 'dryness', 'sensitivity', 'pores', 'dullness', 'sagging');

-- Profiles table (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role user_role NOT NULL DEFAULT 'customer',
  phone TEXT,
  avatar_url TEXT,
  distributor_id UUID,
  salon_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Distributors table
CREATE TABLE distributors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  address TEXT,
  phone TEXT,
  email TEXT,
  representative_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Salons table
CREATE TABLE salons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  distributor_id UUID REFERENCES distributors(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  address TEXT,
  phone TEXT,
  email TEXT,
  opening_hours JSONB,
  representative_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add foreign keys to profiles
ALTER TABLE profiles
  ADD CONSTRAINT fk_profiles_distributor
  FOREIGN KEY (distributor_id) REFERENCES distributors(id) ON DELETE SET NULL,
  ADD CONSTRAINT fk_profiles_salon
  FOREIGN KEY (salon_id) REFERENCES salons(id) ON DELETE SET NULL;

-- Customers table
CREATE TABLE customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  salon_id UUID REFERENCES salons(id) ON DELETE CASCADE,
  profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  customer_number TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  furigana TEXT,
  gender TEXT,
  date_of_birth DATE,
  phone TEXT,
  email TEXT,
  address TEXT,
  postal_code TEXT,
  occupation TEXT,
  notes TEXT,
  tags TEXT[],
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Products table
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  cost DECIMAL(10, 2),
  stock_quantity INTEGER DEFAULT 0,
  image_url TEXT,
  ingredients TEXT[],
  usage_instructions TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Salon menus table
CREATE TABLE salon_menus (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  salon_id UUID REFERENCES salons(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  duration_minutes INTEGER,
  price DECIMAL(10, 2) NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Skin diagnoses table
CREATE TABLE skin_diagnoses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  salon_id UUID REFERENCES salons(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  diagnosis_date DATE NOT NULL DEFAULT CURRENT_DATE,

  -- Basic skin info
  skin_type skin_type,
  concerns concern_type[],

  -- Detailed analysis
  moisture_level INTEGER CHECK (moisture_level >= 0 AND moisture_level <= 100),
  oil_level INTEGER CHECK (oil_level >= 0 AND oil_level <= 100),
  elasticity_level INTEGER CHECK (elasticity_level >= 0 AND elasticity_level <= 100),
  pore_condition INTEGER CHECK (pore_condition >= 0 AND pore_condition <= 100),
  pigmentation_level INTEGER CHECK (pigmentation_level >= 0 AND pigmentation_level <= 100),

  -- Lifestyle factors
  sleep_hours DECIMAL(3, 1),
  sleep_quality INTEGER CHECK (sleep_quality >= 1 AND sleep_quality <= 5),
  stress_level INTEGER CHECK (stress_level >= 1 AND stress_level <= 5),
  exercise_frequency TEXT,
  water_intake_ml INTEGER,

  -- Diet information
  diet_habits JSONB,

  -- Current skincare routine
  current_products JSONB,
  skincare_routine TEXT,

  -- Environmental factors
  sun_exposure TEXT,
  indoor_heating_cooling TEXT,

  -- Medical history
  allergies TEXT[],
  medications TEXT[],
  skin_conditions TEXT[],

  -- Photos
  photo_urls JSONB,

  -- AI analysis results
  ai_analysis_result JSONB,

  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Treatment records table
CREATE TABLE treatment_records (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  salon_id UUID REFERENCES salons(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  menu_id UUID REFERENCES salon_menus(id) ON DELETE SET NULL,
  diagnosis_id UUID REFERENCES skin_diagnoses(id) ON DELETE SET NULL,

  treatment_date DATE NOT NULL DEFAULT CURRENT_DATE,
  start_time TIME,
  end_time TIME,

  -- Treatment details
  services_provided TEXT[],
  products_used JSONB,

  -- Before/after
  condition_before TEXT,
  condition_after TEXT,
  before_photos JSONB,
  after_photos JSONB,

  -- Results
  customer_feedback TEXT,
  satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),

  -- Financial
  price DECIMAL(10, 2),
  discount DECIMAL(10, 2) DEFAULT 0,
  final_price DECIMAL(10, 2),

  next_visit_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Purchase history table
CREATE TABLE purchase_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  salon_id UUID REFERENCES salons(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES profiles(id) ON DELETE SET NULL,

  purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,

  -- Products purchased
  items JSONB NOT NULL,

  -- Financial details
  subtotal DECIMAL(10, 2) NOT NULL,
  tax DECIMAL(10, 2) NOT NULL DEFAULT 0,
  discount DECIMAL(10, 2) DEFAULT 0,
  total DECIMAL(10, 2) NOT NULL,

  payment_method TEXT,
  payment_status TEXT DEFAULT 'completed',

  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Knowledge base table
CREATE TABLE knowledge_base (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  tags TEXT[],
  related_concerns concern_type[],
  related_skin_types skin_type[],
  author_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_published BOOLEAN DEFAULT true,
  view_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Skincare advice table
CREATE TABLE skincare_advice (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  diagnosis_id UUID REFERENCES skin_diagnoses(id) ON DELETE CASCADE,

  -- Recommended routine
  morning_routine JSONB,
  evening_routine JSONB,
  weekly_routine JSONB,

  -- Product recommendations
  recommended_products JSONB,
  products_to_avoid TEXT[],

  -- Specific advice
  advice_text TEXT,
  tips TEXT[],

  -- Frequency and duration
  review_in_weeks INTEGER,

  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Diet advice table
CREATE TABLE diet_advice (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  diagnosis_id UUID REFERENCES skin_diagnoses(id) ON DELETE CASCADE,

  -- Nutritional recommendations
  recommended_foods JSONB,
  foods_to_avoid JSONB,
  supplements JSONB,

  -- Meal suggestions
  meal_plan JSONB,

  -- Hydration
  daily_water_intake_ml INTEGER,

  advice_text TEXT,
  notes TEXT,

  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Exercise advice table
CREATE TABLE exercise_advice (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  diagnosis_id UUID REFERENCES skin_diagnoses(id) ON DELETE CASCADE,

  -- Exercise recommendations
  recommended_exercises JSONB,
  frequency TEXT,
  duration_minutes INTEGER,
  intensity_level TEXT,

  -- Specific for skin
  facial_exercises JSONB,
  yoga_poses JSONB,

  advice_text TEXT,
  tips TEXT[],

  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sleep advice table
CREATE TABLE sleep_advice (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  diagnosis_id UUID REFERENCES skin_diagnoses(id) ON DELETE CASCADE,

  -- Sleep recommendations
  recommended_sleep_hours DECIMAL(3, 1),
  ideal_bedtime TIME,
  ideal_wake_time TIME,

  -- Sleep hygiene tips
  bedtime_routine JSONB,
  environment_tips TEXT[],
  products_for_sleep JSONB,

  advice_text TEXT,
  notes TEXT,

  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_distributor ON profiles(distributor_id);
CREATE INDEX idx_profiles_salon ON profiles(salon_id);
CREATE INDEX idx_salons_distributor ON salons(distributor_id);
CREATE INDEX idx_customers_salon ON customers(salon_id);
CREATE INDEX idx_customers_profile ON customers(profile_id);
CREATE INDEX idx_skin_diagnoses_customer ON skin_diagnoses(customer_id);
CREATE INDEX idx_skin_diagnoses_salon ON skin_diagnoses(salon_id);
CREATE INDEX idx_skin_diagnoses_date ON skin_diagnoses(diagnosis_date);
CREATE INDEX idx_treatment_records_customer ON treatment_records(customer_id);
CREATE INDEX idx_treatment_records_salon ON treatment_records(salon_id);
CREATE INDEX idx_treatment_records_date ON treatment_records(treatment_date);
CREATE INDEX idx_purchase_history_customer ON purchase_history(customer_id);
CREATE INDEX idx_purchase_history_salon ON purchase_history(salon_id);
CREATE INDEX idx_purchase_history_date ON purchase_history(purchase_date);
CREATE INDEX idx_knowledge_base_category ON knowledge_base(category);
CREATE INDEX idx_knowledge_base_tags ON knowledge_base USING GIN(tags);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers to all tables
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_distributors_updated_at BEFORE UPDATE ON distributors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_salons_updated_at BEFORE UPDATE ON salons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_salon_menus_updated_at BEFORE UPDATE ON salon_menus FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_skin_diagnoses_updated_at BEFORE UPDATE ON skin_diagnoses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_treatment_records_updated_at BEFORE UPDATE ON treatment_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_purchase_history_updated_at BEFORE UPDATE ON purchase_history FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_knowledge_base_updated_at BEFORE UPDATE ON knowledge_base FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_skincare_advice_updated_at BEFORE UPDATE ON skincare_advice FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_diet_advice_updated_at BEFORE UPDATE ON diet_advice FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_exercise_advice_updated_at BEFORE UPDATE ON exercise_advice FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sleep_advice_updated_at BEFORE UPDATE ON sleep_advice FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
