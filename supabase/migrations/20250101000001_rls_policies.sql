-- Enable Row Level Security on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE distributors ENABLE ROW LEVEL SECURITY;
ALTER TABLE salons ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE salon_menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE skin_diagnoses ENABLE ROW LEVEL SECURITY;
ALTER TABLE treatment_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_base ENABLE ROW LEVEL SECURITY;
ALTER TABLE skincare_advice ENABLE ROW LEVEL SECURITY;
ALTER TABLE diet_advice ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_advice ENABLE ROW LEVEL SECURITY;
ALTER TABLE sleep_advice ENABLE ROW LEVEL SECURITY;

-- Helper function to get user role
CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- Helper function to check if user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- Helper function to get user's salon_id
CREATE OR REPLACE FUNCTION get_user_salon_id()
RETURNS UUID AS $$
  SELECT salon_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- Helper function to get user's distributor_id
CREATE OR REPLACE FUNCTION get_user_distributor_id()
RETURNS UUID AS $$
  SELECT distributor_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
  ON profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
  ON profiles FOR UPDATE
  USING (auth.uid() = id);

CREATE POLICY "Admins can view all profiles"
  ON profiles FOR SELECT
  USING (is_admin());

CREATE POLICY "Admins can insert profiles"
  ON profiles FOR INSERT
  WITH CHECK (is_admin());

CREATE POLICY "Admins can update all profiles"
  ON profiles FOR UPDATE
  USING (is_admin());

CREATE POLICY "Salon staff can view profiles in their salon"
  ON profiles FOR SELECT
  USING (
    get_user_role() = 'salon_staff' AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view profiles in their distributor"
  ON profiles FOR SELECT
  USING (
    get_user_role() = 'distributor_staff' AND
    distributor_id = get_user_distributor_id()
  );

-- Distributors policies
CREATE POLICY "Admins can manage distributors"
  ON distributors FOR ALL
  USING (is_admin());

CREATE POLICY "Distributor staff can view their distributor"
  ON distributors FOR SELECT
  USING (id = get_user_distributor_id());

-- Salons policies
CREATE POLICY "Admins can manage salons"
  ON salons FOR ALL
  USING (is_admin());

CREATE POLICY "Distributor staff can view salons in their distributor"
  ON salons FOR SELECT
  USING (distributor_id = get_user_distributor_id());

CREATE POLICY "Distributor staff can manage salons in their distributor"
  ON salons FOR ALL
  USING (
    get_user_role() = 'distributor_staff' AND
    distributor_id = get_user_distributor_id()
  );

CREATE POLICY "Salon staff can view their salon"
  ON salons FOR SELECT
  USING (id = get_user_salon_id());

-- Customers policies
CREATE POLICY "Admins can manage all customers"
  ON customers FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage customers in their salon"
  ON customers FOR ALL
  USING (
    get_user_role() = 'salon_staff' AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view customers in their distributor's salons"
  ON customers FOR SELECT
  USING (
    get_user_role() = 'distributor_staff' AND
    EXISTS (
      SELECT 1 FROM salons
      WHERE salons.id = customers.salon_id
      AND salons.distributor_id = get_user_distributor_id()
    )
  );

CREATE POLICY "Customers can view their own profile"
  ON customers FOR SELECT
  USING (profile_id = auth.uid());

-- Products policies
CREATE POLICY "Everyone can view active products"
  ON products FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage products"
  ON products FOR ALL
  USING (is_admin());

CREATE POLICY "Distributor staff can view all products"
  ON products FOR SELECT
  USING (get_user_role() = 'distributor_staff');

CREATE POLICY "Salon staff can view all products"
  ON products FOR SELECT
  USING (get_user_role() = 'salon_staff');

-- Salon menus policies
CREATE POLICY "Admins can manage all menus"
  ON salon_menus FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage menus in their salon"
  ON salon_menus FOR ALL
  USING (
    get_user_role() = 'salon_staff' AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Users can view active menus"
  ON salon_menus FOR SELECT
  USING (is_active = true);

-- Skin diagnoses policies
CREATE POLICY "Admins can manage all diagnoses"
  ON skin_diagnoses FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage diagnoses in their salon"
  ON skin_diagnoses FOR ALL
  USING (
    get_user_role() = 'salon_staff' AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view diagnoses in their distributor's salons"
  ON skin_diagnoses FOR SELECT
  USING (
    get_user_role() = 'distributor_staff' AND
    EXISTS (
      SELECT 1 FROM salons
      WHERE salons.id = skin_diagnoses.salon_id
      AND salons.distributor_id = get_user_distributor_id()
    )
  );

CREATE POLICY "Customers can view their own diagnoses"
  ON skin_diagnoses FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM customers
      WHERE customers.id = skin_diagnoses.customer_id
      AND customers.profile_id = auth.uid()
    )
  );

-- Treatment records policies
CREATE POLICY "Admins can manage all treatment records"
  ON treatment_records FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage records in their salon"
  ON treatment_records FOR ALL
  USING (
    get_user_role() = 'salon_staff' AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view records in their distributor's salons"
  ON treatment_records FOR SELECT
  USING (
    get_user_role() = 'distributor_staff' AND
    EXISTS (
      SELECT 1 FROM salons
      WHERE salons.id = treatment_records.salon_id
      AND salons.distributor_id = get_user_distributor_id()
    )
  );

CREATE POLICY "Customers can view their own treatment records"
  ON treatment_records FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM customers
      WHERE customers.id = treatment_records.customer_id
      AND customers.profile_id = auth.uid()
    )
  );

-- Purchase history policies
CREATE POLICY "Admins can manage all purchase history"
  ON purchase_history FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage purchase history in their salon"
  ON purchase_history FOR ALL
  USING (
    get_user_role() = 'salon_staff' AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view purchase history in their distributor's salons"
  ON purchase_history FOR SELECT
  USING (
    get_user_role() = 'distributor_staff' AND
    EXISTS (
      SELECT 1 FROM salons
      WHERE salons.id = purchase_history.salon_id
      AND salons.distributor_id = get_user_distributor_id()
    )
  );

CREATE POLICY "Customers can view their own purchase history"
  ON purchase_history FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM customers
      WHERE customers.id = purchase_history.customer_id
      AND customers.profile_id = auth.uid()
    )
  );

-- Knowledge base policies
CREATE POLICY "Everyone can view published knowledge base articles"
  ON knowledge_base FOR SELECT
  USING (is_published = true);

CREATE POLICY "Admins can manage knowledge base"
  ON knowledge_base FOR ALL
  USING (is_admin());

CREATE POLICY "Staff can view all knowledge base articles"
  ON knowledge_base FOR SELECT
  USING (
    get_user_role() IN ('salon_staff', 'distributor_staff')
  );

-- Skincare advice policies
CREATE POLICY "Admins can manage all skincare advice"
  ON skincare_advice FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage advice for their salon's customers"
  ON skincare_advice FOR ALL
  USING (
    get_user_role() = 'salon_staff' AND
    EXISTS (
      SELECT 1 FROM skin_diagnoses
      WHERE skin_diagnoses.id = skincare_advice.diagnosis_id
      AND skin_diagnoses.salon_id = get_user_salon_id()
    )
  );

CREATE POLICY "Customers can view their own skincare advice"
  ON skincare_advice FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM skin_diagnoses
      JOIN customers ON customers.id = skin_diagnoses.customer_id
      WHERE skin_diagnoses.id = skincare_advice.diagnosis_id
      AND customers.profile_id = auth.uid()
    )
  );

-- Diet advice policies
CREATE POLICY "Admins can manage all diet advice"
  ON diet_advice FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage diet advice for their salon's customers"
  ON diet_advice FOR ALL
  USING (
    get_user_role() = 'salon_staff' AND
    EXISTS (
      SELECT 1 FROM skin_diagnoses
      WHERE skin_diagnoses.id = diet_advice.diagnosis_id
      AND skin_diagnoses.salon_id = get_user_salon_id()
    )
  );

CREATE POLICY "Customers can view their own diet advice"
  ON diet_advice FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM skin_diagnoses
      JOIN customers ON customers.id = skin_diagnoses.customer_id
      WHERE skin_diagnoses.id = diet_advice.diagnosis_id
      AND customers.profile_id = auth.uid()
    )
  );

-- Exercise advice policies
CREATE POLICY "Admins can manage all exercise advice"
  ON exercise_advice FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage exercise advice for their salon's customers"
  ON exercise_advice FOR ALL
  USING (
    get_user_role() = 'salon_staff' AND
    EXISTS (
      SELECT 1 FROM skin_diagnoses
      WHERE skin_diagnoses.id = exercise_advice.diagnosis_id
      AND skin_diagnoses.salon_id = get_user_salon_id()
    )
  );

CREATE POLICY "Customers can view their own exercise advice"
  ON exercise_advice FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM skin_diagnoses
      JOIN customers ON customers.id = skin_diagnoses.customer_id
      WHERE skin_diagnoses.id = exercise_advice.diagnosis_id
      AND customers.profile_id = auth.uid()
    )
  );

-- Sleep advice policies
CREATE POLICY "Admins can manage all sleep advice"
  ON sleep_advice FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage sleep advice for their salon's customers"
  ON sleep_advice FOR ALL
  USING (
    get_user_role() = 'salon_staff' AND
    EXISTS (
      SELECT 1 FROM skin_diagnoses
      WHERE skin_diagnoses.id = sleep_advice.diagnosis_id
      AND skin_diagnoses.salon_id = get_user_salon_id()
    )
  );

CREATE POLICY "Customers can view their own sleep advice"
  ON sleep_advice FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM skin_diagnoses
      JOIN customers ON customers.id = skin_diagnoses.customer_id
      WHERE skin_diagnoses.id = sleep_advice.diagnosis_id
      AND customers.profile_id = auth.uid()
    )
  );
