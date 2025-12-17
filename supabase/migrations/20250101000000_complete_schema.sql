-- ============================================
-- Bsta スキンケア AI肌診断・CRMシステム
-- 完全データベーススキーマ
-- ============================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- ENUM TYPES
-- ============================================

CREATE TYPE user_role AS ENUM ('customer', 'salon_staff', 'distributor_staff', 'admin');
CREATE TYPE skin_type AS ENUM ('dry', 'oily', 'combination', 'sensitive', 'normal');
CREATE TYPE concern_type AS ENUM ('wrinkles', 'acne', 'pigmentation', 'dryness', 'sensitivity', 'pores', 'dullness', 'sagging');
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled');
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'failed', 'refunded');
CREATE TYPE notification_type AS ENUM ('diagnosis', 'treatment', 'purchase', 'appointment', 'general');

-- ============================================
-- PROFILES TABLE (User Management)
-- ============================================

CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT,
  role user_role NOT NULL DEFAULT 'customer',
  phone TEXT,
  avatar_url TEXT,
  line_user_id TEXT UNIQUE,
  distributor_id UUID,
  salon_id UUID,
  is_active BOOLEAN DEFAULT true,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- DISTRIBUTORS TABLE
-- ============================================

CREATE TABLE distributors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  address TEXT,
  phone TEXT,
  email TEXT,
  representative_name TEXT,
  contract_start_date DATE,
  contract_end_date DATE,
  is_active BOOLEAN DEFAULT true,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- SALONS TABLE
-- ============================================

CREATE TABLE salons (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  distributor_id UUID REFERENCES distributors(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  address TEXT,
  postal_code TEXT,
  phone TEXT,
  email TEXT,
  opening_hours JSONB,
  representative_name TEXT,
  business_registration_number TEXT,
  is_active BOOLEAN DEFAULT true,
  settings JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add foreign keys to profiles after salons table is created
ALTER TABLE profiles
  ADD CONSTRAINT fk_profiles_distributor
  FOREIGN KEY (distributor_id) REFERENCES distributors(id) ON DELETE SET NULL,
  ADD CONSTRAINT fk_profiles_salon
  FOREIGN KEY (salon_id) REFERENCES salons(id) ON DELETE SET NULL;

-- ============================================
-- CUSTOMERS TABLE
-- ============================================

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
  line_user_id TEXT,

  -- Customer preferences
  preferred_contact_method TEXT,
  marketing_consent BOOLEAN DEFAULT false,

  -- Loyalty & Analytics
  total_visits INTEGER DEFAULT 0,
  total_spent DECIMAL(10, 2) DEFAULT 0,
  last_visit_date DATE,
  next_predicted_visit_date DATE,
  customer_lifetime_value DECIMAL(10, 2) DEFAULT 0,
  churn_risk_score DECIMAL(3, 2),

  notes TEXT,
  tags TEXT[],
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- CUSTOMER TRANSFER LOGS
-- ============================================

CREATE TABLE customer_transfer_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  from_salon_id UUID REFERENCES salons(id) ON DELETE SET NULL,
  to_salon_id UUID REFERENCES salons(id) ON DELETE SET NULL,
  transferred_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reason TEXT,
  notes TEXT,
  transferred_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- PRODUCTS TABLE
-- ============================================

CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  code TEXT UNIQUE NOT NULL,
  category TEXT NOT NULL,
  subcategory TEXT,
  description TEXT,

  -- Pricing
  price DECIMAL(10, 2) NOT NULL,
  cost DECIMAL(10, 2),
  tax_rate DECIMAL(5, 2) DEFAULT 10.00,

  -- Product details
  size TEXT,
  unit TEXT,
  barcode TEXT UNIQUE,
  sku TEXT UNIQUE,

  -- Inventory
  stock_quantity INTEGER DEFAULT 0,
  reorder_level INTEGER DEFAULT 0,
  reorder_quantity INTEGER DEFAULT 0,

  -- Media & Info
  image_url TEXT,
  images JSONB,
  ingredients TEXT[],
  usage_instructions TEXT,
  warnings TEXT,

  -- Product attributes
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  display_order INTEGER DEFAULT 0,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- INVENTORY TABLE
-- ============================================

CREATE TABLE inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  salon_id UUID REFERENCES salons(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL DEFAULT 0,
  reorder_level INTEGER DEFAULT 0,
  last_restocked_at TIMESTAMPTZ,
  last_counted_at TIMESTAMPTZ,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(product_id, salon_id)
);

-- ============================================
-- SALON MENUS TABLE
-- ============================================

CREATE TABLE salon_menus (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  salon_id UUID REFERENCES salons(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  duration_minutes INTEGER,
  price DECIMAL(10, 2) NOT NULL,
  cost DECIMAL(10, 2),
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- SKIN DIAGNOSES TABLE
-- ============================================

CREATE TABLE skin_diagnoses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  salon_id UUID REFERENCES salons(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  diagnosis_date DATE NOT NULL DEFAULT CURRENT_DATE,

  -- Basic skin info
  skin_type skin_type,
  concerns concern_type[],

  -- Detailed analysis (0-100 scale)
  moisture_level INTEGER CHECK (moisture_level >= 0 AND moisture_level <= 100),
  oil_level INTEGER CHECK (oil_level >= 0 AND oil_level <= 100),
  elasticity_level INTEGER CHECK (elasticity_level >= 0 AND elasticity_level <= 100),
  pore_condition INTEGER CHECK (pore_condition >= 0 AND pore_condition <= 100),
  pigmentation_level INTEGER CHECK (pigmentation_level >= 0 AND pigmentation_level <= 100),
  texture_score INTEGER CHECK (texture_score >= 0 AND texture_score <= 100),
  redness_level INTEGER CHECK (redness_level >= 0 AND redness_level <= 100),

  -- Lifestyle factors
  sleep_hours DECIMAL(3, 1),
  sleep_quality INTEGER CHECK (sleep_quality >= 1 AND sleep_quality <= 5),
  stress_level INTEGER CHECK (stress_level >= 1 AND stress_level <= 5),
  exercise_frequency TEXT,
  water_intake_ml INTEGER,
  alcohol_consumption TEXT,
  smoking_status TEXT,

  -- Diet information
  diet_habits JSONB,

  -- Current skincare routine
  current_products JSONB,
  skincare_routine TEXT,

  -- Environmental factors
  sun_exposure TEXT,
  indoor_heating_cooling TEXT,
  pollution_exposure TEXT,

  -- Medical history
  allergies TEXT[],
  medications TEXT[],
  skin_conditions TEXT[],
  previous_treatments TEXT[],

  -- Photos
  photo_urls JSONB,
  photo_retention_days INTEGER DEFAULT 365,

  -- AI analysis results
  ai_analysis_result JSONB,
  ai_confidence_score DECIMAL(3, 2),

  -- Overall score
  overall_skin_score INTEGER CHECK (overall_skin_score >= 0 AND overall_skin_score <= 100),

  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- DIAGNOSIS PHOTO RETENTION POLICY
-- ============================================

CREATE TABLE diagnosis_photo_retention_policy (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  salon_id UUID REFERENCES salons(id) ON DELETE CASCADE,
  default_retention_days INTEGER NOT NULL DEFAULT 365,
  auto_delete_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(salon_id)
);

-- ============================================
-- TREATMENT RECORDS TABLE
-- ============================================

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
  duration_minutes INTEGER,

  -- Treatment details
  services_provided TEXT[],
  products_used JSONB,
  techniques_used TEXT[],

  -- Before/after
  condition_before TEXT,
  condition_after TEXT,
  before_photos JSONB,
  after_photos JSONB,

  -- Results
  customer_feedback TEXT,
  satisfaction_rating INTEGER CHECK (satisfaction_rating >= 1 AND satisfaction_rating <= 5),
  skin_improvement_score INTEGER CHECK (skin_improvement_score >= 1 AND skin_improvement_score <= 10),

  -- Financial
  price DECIMAL(10, 2),
  discount DECIMAL(10, 2) DEFAULT 0,
  tax DECIMAL(10, 2) DEFAULT 0,
  final_price DECIMAL(10, 2),
  payment_method TEXT,
  payment_status payment_status DEFAULT 'pending',

  -- Follow-up
  next_visit_date DATE,
  recommended_frequency TEXT,
  follow_up_notes TEXT,

  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- PRODUCT USAGE TABLE
-- ============================================

CREATE TABLE product_usage (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  treatment_record_id UUID REFERENCES treatment_records(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  quantity DECIMAL(10, 2) NOT NULL,
  unit TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- PURCHASE HISTORY TABLE
-- ============================================

CREATE TABLE purchase_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  salon_id UUID REFERENCES salons(id) ON DELETE CASCADE,
  staff_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  treatment_record_id UUID REFERENCES treatment_records(id) ON DELETE SET NULL,

  purchase_date DATE NOT NULL DEFAULT CURRENT_DATE,
  order_number TEXT UNIQUE,

  -- Products purchased
  items JSONB NOT NULL,

  -- Financial details
  subtotal DECIMAL(10, 2) NOT NULL,
  tax DECIMAL(10, 2) NOT NULL DEFAULT 0,
  discount DECIMAL(10, 2) DEFAULT 0,
  shipping_fee DECIMAL(10, 2) DEFAULT 0,
  total DECIMAL(10, 2) NOT NULL,

  payment_method TEXT,
  payment_status payment_status DEFAULT 'completed',

  -- Repurchase prediction
  predicted_repurchase_date DATE,
  repurchase_probability DECIMAL(3, 2),

  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- ORDERS TABLE
-- ============================================

CREATE TABLE orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  salon_id UUID REFERENCES salons(id) ON DELETE CASCADE,
  distributor_id UUID REFERENCES distributors(id) ON DELETE SET NULL,
  order_number TEXT UNIQUE NOT NULL,
  order_date DATE NOT NULL DEFAULT CURRENT_DATE,
  status order_status DEFAULT 'pending',

  -- Shipping
  shipping_address TEXT,
  shipping_postal_code TEXT,
  shipping_phone TEXT,
  expected_delivery_date DATE,
  actual_delivery_date DATE,
  tracking_number TEXT,

  -- Financial
  subtotal DECIMAL(10, 2) NOT NULL,
  tax DECIMAL(10, 2) DEFAULT 0,
  shipping_fee DECIMAL(10, 2) DEFAULT 0,
  total DECIMAL(10, 2) NOT NULL,

  notes TEXT,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- ORDER ITEMS TABLE
-- ============================================

CREATE TABLE order_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
  product_id UUID REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER NOT NULL,
  unit_price DECIMAL(10, 2) NOT NULL,
  subtotal DECIMAL(10, 2) NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- KNOWLEDGE BASE TABLE
-- ============================================

CREATE TABLE knowledge_base (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  summary TEXT,
  tags TEXT[],
  related_concerns concern_type[],
  related_skin_types skin_type[],

  -- Media
  featured_image TEXT,
  images JSONB,
  videos JSONB,

  -- Metadata
  author_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_published BOOLEAN DEFAULT true,
  publish_date DATE,
  view_count INTEGER DEFAULT 0,
  helpful_count INTEGER DEFAULT 0,

  -- SEO
  meta_description TEXT,
  slug TEXT UNIQUE,

  -- Versioning
  version INTEGER DEFAULT 1,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- KNOWLEDGE VERSIONS TABLE
-- ============================================

CREATE TABLE knowledge_versions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  knowledge_id UUID REFERENCES knowledge_base(id) ON DELETE CASCADE,
  version INTEGER NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  changed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  change_summary TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- SKINCARE ADVICE TABLE
-- ============================================

CREATE TABLE skincare_advice (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  diagnosis_id UUID REFERENCES skin_diagnoses(id) ON DELETE CASCADE,

  -- Recommended routine
  morning_routine JSONB,
  evening_routine JSONB,
  weekly_routine JSONB,
  monthly_routine JSONB,

  -- Product recommendations
  recommended_products JSONB,
  products_to_avoid TEXT[],

  -- Specific advice
  advice_text TEXT,
  tips TEXT[],
  dos_and_donts JSONB,

  -- Frequency and duration
  review_in_weeks INTEGER,
  expected_improvement_timeline TEXT,

  -- AI generated
  ai_generated BOOLEAN DEFAULT false,
  ai_confidence_score DECIMAL(3, 2),

  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- DIET ADVICE TABLE
-- ============================================

CREATE TABLE diet_advice (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  diagnosis_id UUID REFERENCES skin_diagnoses(id) ON DELETE CASCADE,

  -- Nutritional recommendations
  recommended_foods JSONB,
  foods_to_avoid JSONB,
  supplements JSONB,
  vitamins_minerals JSONB,

  -- Meal suggestions
  meal_plan JSONB,
  recipes JSONB,

  -- Hydration
  daily_water_intake_ml INTEGER,
  hydration_tips TEXT[],

  -- Specific guidance
  advice_text TEXT,
  notes TEXT,

  -- AI generated
  ai_generated BOOLEAN DEFAULT false,
  ai_confidence_score DECIMAL(3, 2),

  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- EXERCISE ADVICE TABLE
-- ============================================

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
  breathing_exercises JSONB,

  -- Guidance
  advice_text TEXT,
  tips TEXT[],
  warnings TEXT[],

  -- AI generated
  ai_generated BOOLEAN DEFAULT false,
  ai_confidence_score DECIMAL(3, 2),

  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- SLEEP ADVICE TABLE
-- ============================================

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
  relaxation_techniques TEXT[],

  -- Guidance
  advice_text TEXT,
  notes TEXT,

  -- AI generated
  ai_generated BOOLEAN DEFAULT false,
  ai_confidence_score DECIMAL(3, 2),

  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- LINE NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE line_notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES customers(id) ON DELETE CASCADE,
  notification_type notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  link_url TEXT,

  -- Status
  sent_at TIMESTAMPTZ,
  read_at TIMESTAMPTZ,
  is_sent BOOLEAN DEFAULT false,

  -- Related records
  related_diagnosis_id UUID REFERENCES skin_diagnoses(id) ON DELETE SET NULL,
  related_treatment_id UUID REFERENCES treatment_records(id) ON DELETE SET NULL,
  related_purchase_id UUID REFERENCES purchase_history(id) ON DELETE SET NULL,

  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ============================================
-- INDEXES
-- ============================================

-- Profiles
CREATE INDEX idx_profiles_role ON profiles(role);
CREATE INDEX idx_profiles_distributor ON profiles(distributor_id);
CREATE INDEX idx_profiles_salon ON profiles(salon_id);
CREATE INDEX idx_profiles_email ON profiles(email);
CREATE INDEX idx_profiles_line_user_id ON profiles(line_user_id);

-- Distributors
CREATE INDEX idx_distributors_code ON distributors(code);
CREATE INDEX idx_distributors_is_active ON distributors(is_active);

-- Salons
CREATE INDEX idx_salons_distributor ON salons(distributor_id);
CREATE INDEX idx_salons_code ON salons(code);
CREATE INDEX idx_salons_is_active ON salons(is_active);

-- Customers
CREATE INDEX idx_customers_salon ON customers(salon_id);
CREATE INDEX idx_customers_profile ON customers(profile_id);
CREATE INDEX idx_customers_customer_number ON customers(customer_number);
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_phone ON customers(phone);
CREATE INDEX idx_customers_line_user_id ON customers(line_user_id);
CREATE INDEX idx_customers_last_visit ON customers(last_visit_date);
CREATE INDEX idx_customers_next_predicted_visit ON customers(next_predicted_visit_date);

-- Products
CREATE INDEX idx_products_code ON products(code);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_is_active ON products(is_active);
CREATE INDEX idx_products_barcode ON products(barcode);
CREATE INDEX idx_products_sku ON products(sku);

-- Inventory
CREATE INDEX idx_inventory_product ON inventory(product_id);
CREATE INDEX idx_inventory_salon ON inventory(salon_id);

-- Salon Menus
CREATE INDEX idx_salon_menus_salon ON salon_menus(salon_id);
CREATE INDEX idx_salon_menus_category ON salon_menus(category);
CREATE INDEX idx_salon_menus_is_active ON salon_menus(is_active);

-- Skin Diagnoses
CREATE INDEX idx_skin_diagnoses_customer ON skin_diagnoses(customer_id);
CREATE INDEX idx_skin_diagnoses_salon ON skin_diagnoses(salon_id);
CREATE INDEX idx_skin_diagnoses_staff ON skin_diagnoses(staff_id);
CREATE INDEX idx_skin_diagnoses_date ON skin_diagnoses(diagnosis_date);
CREATE INDEX idx_skin_diagnoses_skin_type ON skin_diagnoses(skin_type);

-- Treatment Records
CREATE INDEX idx_treatment_records_customer ON treatment_records(customer_id);
CREATE INDEX idx_treatment_records_salon ON treatment_records(salon_id);
CREATE INDEX idx_treatment_records_staff ON treatment_records(staff_id);
CREATE INDEX idx_treatment_records_date ON treatment_records(treatment_date);
CREATE INDEX idx_treatment_records_diagnosis ON treatment_records(diagnosis_id);

-- Purchase History
CREATE INDEX idx_purchase_history_customer ON purchase_history(customer_id);
CREATE INDEX idx_purchase_history_salon ON purchase_history(salon_id);
CREATE INDEX idx_purchase_history_date ON purchase_history(purchase_date);
CREATE INDEX idx_purchase_history_order_number ON purchase_history(order_number);
CREATE INDEX idx_purchase_history_predicted_repurchase ON purchase_history(predicted_repurchase_date);

-- Orders
CREATE INDEX idx_orders_salon ON orders(salon_id);
CREATE INDEX idx_orders_distributor ON orders(distributor_id);
CREATE INDEX idx_orders_order_number ON orders(order_number);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_date ON orders(order_date);

-- Order Items
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);

-- Knowledge Base
CREATE INDEX idx_knowledge_base_category ON knowledge_base(category);
CREATE INDEX idx_knowledge_base_tags ON knowledge_base USING GIN(tags);
CREATE INDEX idx_knowledge_base_is_published ON knowledge_base(is_published);
CREATE INDEX idx_knowledge_base_slug ON knowledge_base(slug);

-- LINE Notifications
CREATE INDEX idx_line_notifications_customer ON line_notifications(customer_id);
CREATE INDEX idx_line_notifications_type ON line_notifications(notification_type);
CREATE INDEX idx_line_notifications_sent ON line_notifications(is_sent);
CREATE INDEX idx_line_notifications_created ON line_notifications(created_at);

-- ============================================
-- TRIGGERS & FUNCTIONS
-- ============================================

-- Updated at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add updated_at triggers
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_distributors_updated_at BEFORE UPDATE ON distributors FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_salons_updated_at BEFORE UPDATE ON salons FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_customers_updated_at BEFORE UPDATE ON customers FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_inventory_updated_at BEFORE UPDATE ON inventory FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_salon_menus_updated_at BEFORE UPDATE ON salon_menus FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_skin_diagnoses_updated_at BEFORE UPDATE ON skin_diagnoses FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_treatment_records_updated_at BEFORE UPDATE ON treatment_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_purchase_history_updated_at BEFORE UPDATE ON purchase_history FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_orders_updated_at BEFORE UPDATE ON orders FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_knowledge_base_updated_at BEFORE UPDATE ON knowledge_base FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_skincare_advice_updated_at BEFORE UPDATE ON skincare_advice FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_diet_advice_updated_at BEFORE UPDATE ON diet_advice FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_exercise_advice_updated_at BEFORE UPDATE ON exercise_advice FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_sleep_advice_updated_at BEFORE UPDATE ON sleep_advice FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- AUTO-CALCULATE REPURCHASE PREDICTION
-- ============================================

CREATE OR REPLACE FUNCTION calculate_repurchase_prediction()
RETURNS TRIGGER AS $$
DECLARE
  avg_days INTEGER;
BEGIN
  -- Calculate average days between purchases for this customer
  SELECT AVG(EXTRACT(DAY FROM (purchase_date - LAG(purchase_date) OVER (ORDER BY purchase_date))))::INTEGER
  INTO avg_days
  FROM purchase_history
  WHERE customer_id = NEW.customer_id;

  -- If we have historical data, predict next purchase
  IF avg_days IS NOT NULL AND avg_days > 0 THEN
    NEW.predicted_repurchase_date := NEW.purchase_date + (avg_days || ' days')::INTERVAL;
    NEW.repurchase_probability := LEAST(1.0, 0.7 + (0.3 / (1 + EXP(-(avg_days - 30) / 10.0))));
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_repurchase_prediction
BEFORE INSERT OR UPDATE ON purchase_history
FOR EACH ROW
EXECUTE FUNCTION calculate_repurchase_prediction();

-- ============================================
-- UPDATE CUSTOMER STATS
-- ============================================

CREATE OR REPLACE FUNCTION update_customer_stats()
RETURNS TRIGGER AS $$
BEGIN
  -- Update customer statistics
  UPDATE customers
  SET
    total_visits = (SELECT COUNT(*) FROM treatment_records WHERE customer_id = NEW.customer_id),
    total_spent = (SELECT COALESCE(SUM(total), 0) FROM purchase_history WHERE customer_id = NEW.customer_id),
    last_visit_date = NEW.treatment_date,
    updated_at = NOW()
  WHERE id = NEW.customer_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_customer_stats_treatment
AFTER INSERT ON treatment_records
FOR EACH ROW
EXECUTE FUNCTION update_customer_stats();

-- ============================================
-- KNOWLEDGE BASE VERSIONING
-- ============================================

CREATE OR REPLACE FUNCTION create_knowledge_version()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create version if content changed
  IF TG_OP = 'UPDATE' AND (OLD.title != NEW.title OR OLD.content != NEW.content) THEN
    INSERT INTO knowledge_versions (knowledge_id, version, title, content, changed_by, change_summary)
    VALUES (NEW.id, NEW.version, OLD.title, OLD.content, NEW.author_id, 'Updated content');

    NEW.version := NEW.version + 1;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_create_knowledge_version
BEFORE UPDATE ON knowledge_base
FOR EACH ROW
EXECUTE FUNCTION create_knowledge_version();

-- ============================================
-- AUTO-UPDATE INVENTORY ON PRODUCT USAGE
-- ============================================

CREATE OR REPLACE FUNCTION update_inventory_on_usage()
RETURNS TRIGGER AS $$
DECLARE
  v_salon_id UUID;
BEGIN
  -- Get salon_id from treatment record
  SELECT salon_id INTO v_salon_id
  FROM treatment_records
  WHERE id = NEW.treatment_record_id;

  -- Update inventory
  UPDATE inventory
  SET quantity = quantity - NEW.quantity,
      updated_at = NOW()
  WHERE product_id = NEW.product_id
    AND salon_id = v_salon_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_inventory_on_usage
AFTER INSERT ON product_usage
FOR EACH ROW
EXECUTE FUNCTION update_inventory_on_usage();
