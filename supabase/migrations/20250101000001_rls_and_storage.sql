-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE distributors ENABLE ROW LEVEL SECURITY;
ALTER TABLE salons ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_transfer_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE salon_menus ENABLE ROW LEVEL SECURITY;
ALTER TABLE skin_diagnoses ENABLE ROW LEVEL SECURITY;
ALTER TABLE diagnosis_photo_retention_policy ENABLE ROW LEVEL SECURITY;
ALTER TABLE treatment_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE purchase_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_base ENABLE ROW LEVEL SECURITY;
ALTER TABLE knowledge_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE skincare_advice ENABLE ROW LEVEL SECURITY;
ALTER TABLE diet_advice ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_advice ENABLE ROW LEVEL SECURITY;
ALTER TABLE sleep_advice ENABLE ROW LEVEL SECURITY;
ALTER TABLE line_notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

CREATE OR REPLACE FUNCTION get_user_role()
RETURNS user_role AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_salon_id()
RETURNS UUID AS $$
  SELECT salon_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_user_distributor_id()
RETURNS UUID AS $$
  SELECT distributor_id FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_salon_staff()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'salon_staff'
  );
$$ LANGUAGE sql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION is_distributor_staff()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM profiles
    WHERE id = auth.uid() AND role = 'distributor_staff'
  );
$$ LANGUAGE sql SECURITY DEFINER;

-- ============================================
-- PROFILES POLICIES
-- ============================================

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

CREATE POLICY "Admins can delete profiles"
  ON profiles FOR DELETE
  USING (is_admin());

CREATE POLICY "Salon staff can view profiles in their salon"
  ON profiles FOR SELECT
  USING (
    is_salon_staff() AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view profiles in their distributor"
  ON profiles FOR SELECT
  USING (
    is_distributor_staff() AND
    distributor_id = get_user_distributor_id()
  );

-- ============================================
-- DISTRIBUTORS POLICIES
-- ============================================

CREATE POLICY "Admins can manage distributors"
  ON distributors FOR ALL
  USING (is_admin());

CREATE POLICY "Distributor staff can view their distributor"
  ON distributors FOR SELECT
  USING (id = get_user_distributor_id());

CREATE POLICY "Salon staff can view their distributor"
  ON distributors FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM salons
      WHERE salons.id = get_user_salon_id()
      AND salons.distributor_id = distributors.id
    )
  );

-- ============================================
-- SALONS POLICIES
-- ============================================

CREATE POLICY "Admins can manage salons"
  ON salons FOR ALL
  USING (is_admin());

CREATE POLICY "Distributor staff can view salons in their distributor"
  ON salons FOR SELECT
  USING (distributor_id = get_user_distributor_id());

CREATE POLICY "Distributor staff can manage salons in their distributor"
  ON salons FOR ALL
  USING (
    is_distributor_staff() AND
    distributor_id = get_user_distributor_id()
  );

CREATE POLICY "Salon staff can view their salon"
  ON salons FOR SELECT
  USING (id = get_user_salon_id());

CREATE POLICY "Salon staff can update their salon"
  ON salons FOR UPDATE
  USING (
    is_salon_staff() AND
    id = get_user_salon_id()
  );

-- ============================================
-- CUSTOMERS POLICIES
-- ============================================

CREATE POLICY "Admins can manage all customers"
  ON customers FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage customers in their salon"
  ON customers FOR ALL
  USING (
    is_salon_staff() AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view customers in their distributor's salons"
  ON customers FOR SELECT
  USING (
    is_distributor_staff() AND
    EXISTS (
      SELECT 1 FROM salons
      WHERE salons.id = customers.salon_id
      AND salons.distributor_id = get_user_distributor_id()
    )
  );

CREATE POLICY "Customers can view their own profile"
  ON customers FOR SELECT
  USING (profile_id = auth.uid());

CREATE POLICY "Customers can update their own profile"
  ON customers FOR UPDATE
  USING (profile_id = auth.uid());

-- ============================================
-- CUSTOMER TRANSFER LOGS POLICIES
-- ============================================

CREATE POLICY "Admins can view all transfer logs"
  ON customer_transfer_logs FOR SELECT
  USING (is_admin());

CREATE POLICY "Admins can create transfer logs"
  ON customer_transfer_logs FOR INSERT
  WITH CHECK (is_admin());

CREATE POLICY "Distributor staff can view transfer logs in their distributor"
  ON customer_transfer_logs FOR SELECT
  USING (
    is_distributor_staff() AND
    (EXISTS (
      SELECT 1 FROM salons
      WHERE salons.id = customer_transfer_logs.from_salon_id
      AND salons.distributor_id = get_user_distributor_id()
    ) OR EXISTS (
      SELECT 1 FROM salons
      WHERE salons.id = customer_transfer_logs.to_salon_id
      AND salons.distributor_id = get_user_distributor_id()
    ))
  );

-- ============================================
-- PRODUCTS POLICIES
-- ============================================

CREATE POLICY "Everyone can view active products"
  ON products FOR SELECT
  USING (is_active = true);

CREATE POLICY "Admins can manage products"
  ON products FOR ALL
  USING (is_admin());

CREATE POLICY "Distributor staff can view all products"
  ON products FOR SELECT
  USING (is_distributor_staff());

CREATE POLICY "Salon staff can view all products"
  ON products FOR SELECT
  USING (is_salon_staff());

-- ============================================
-- INVENTORY POLICIES
-- ============================================

CREATE POLICY "Admins can manage all inventory"
  ON inventory FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage inventory in their salon"
  ON inventory FOR ALL
  USING (
    is_salon_staff() AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view inventory in their distributor's salons"
  ON inventory FOR SELECT
  USING (
    is_distributor_staff() AND
    EXISTS (
      SELECT 1 FROM salons
      WHERE salons.id = inventory.salon_id
      AND salons.distributor_id = get_user_distributor_id()
    )
  );

-- ============================================
-- SALON MENUS POLICIES
-- ============================================

CREATE POLICY "Admins can manage all menus"
  ON salon_menus FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage menus in their salon"
  ON salon_menus FOR ALL
  USING (
    is_salon_staff() AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Users can view active menus"
  ON salon_menus FOR SELECT
  USING (is_active = true);

CREATE POLICY "Distributor staff can view menus in their distributor's salons"
  ON salon_menus FOR SELECT
  USING (
    is_distributor_staff() AND
    EXISTS (
      SELECT 1 FROM salons
      WHERE salons.id = salon_menus.salon_id
      AND salons.distributor_id = get_user_distributor_id()
    )
  );

-- ============================================
-- SKIN DIAGNOSES POLICIES
-- ============================================

CREATE POLICY "Admins can manage all diagnoses"
  ON skin_diagnoses FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage diagnoses in their salon"
  ON skin_diagnoses FOR ALL
  USING (
    is_salon_staff() AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view diagnoses in their distributor's salons"
  ON skin_diagnoses FOR SELECT
  USING (
    is_distributor_staff() AND
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

-- ============================================
-- DIAGNOSIS PHOTO RETENTION POLICY
-- ============================================

CREATE POLICY "Admins can manage retention policies"
  ON diagnosis_photo_retention_policy FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage retention policy for their salon"
  ON diagnosis_photo_retention_policy FOR ALL
  USING (
    is_salon_staff() AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view retention policies"
  ON diagnosis_photo_retention_policy FOR SELECT
  USING (
    is_distributor_staff() AND
    EXISTS (
      SELECT 1 FROM salons
      WHERE salons.id = diagnosis_photo_retention_policy.salon_id
      AND salons.distributor_id = get_user_distributor_id()
    )
  );

-- ============================================
-- TREATMENT RECORDS POLICIES
-- ============================================

CREATE POLICY "Admins can manage all treatment records"
  ON treatment_records FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage records in their salon"
  ON treatment_records FOR ALL
  USING (
    is_salon_staff() AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view records in their distributor's salons"
  ON treatment_records FOR SELECT
  USING (
    is_distributor_staff() AND
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

-- ============================================
-- PRODUCT USAGE POLICIES
-- ============================================

CREATE POLICY "Admins can manage product usage"
  ON product_usage FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage product usage in their salon"
  ON product_usage FOR ALL
  USING (
    is_salon_staff() AND
    EXISTS (
      SELECT 1 FROM treatment_records
      WHERE treatment_records.id = product_usage.treatment_record_id
      AND treatment_records.salon_id = get_user_salon_id()
    )
  );

CREATE POLICY "Users can view product usage for their treatments"
  ON product_usage FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM treatment_records
      JOIN customers ON customers.id = treatment_records.customer_id
      WHERE treatment_records.id = product_usage.treatment_record_id
      AND customers.profile_id = auth.uid()
    )
  );

-- ============================================
-- PURCHASE HISTORY POLICIES
-- ============================================

CREATE POLICY "Admins can manage all purchase history"
  ON purchase_history FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage purchase history in their salon"
  ON purchase_history FOR ALL
  USING (
    is_salon_staff() AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view purchase history in their distributor's salons"
  ON purchase_history FOR SELECT
  USING (
    is_distributor_staff() AND
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

-- ============================================
-- ORDERS POLICIES
-- ============================================

CREATE POLICY "Admins can manage all orders"
  ON orders FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage orders for their salon"
  ON orders FOR ALL
  USING (
    is_salon_staff() AND
    salon_id = get_user_salon_id()
  );

CREATE POLICY "Distributor staff can view orders in their distributor"
  ON orders FOR SELECT
  USING (distributor_id = get_user_distributor_id());

CREATE POLICY "Distributor staff can manage orders in their distributor"
  ON orders FOR ALL
  USING (
    is_distributor_staff() AND
    distributor_id = get_user_distributor_id()
  );

-- ============================================
-- ORDER ITEMS POLICIES
-- ============================================

CREATE POLICY "Admins can manage all order items"
  ON order_items FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage order items for their salon's orders"
  ON order_items FOR ALL
  USING (
    is_salon_staff() AND
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.salon_id = get_user_salon_id()
    )
  );

CREATE POLICY "Distributor staff can view order items"
  ON order_items FOR SELECT
  USING (
    is_distributor_staff() AND
    EXISTS (
      SELECT 1 FROM orders
      WHERE orders.id = order_items.order_id
      AND orders.distributor_id = get_user_distributor_id()
    )
  );

-- ============================================
-- KNOWLEDGE BASE POLICIES
-- ============================================

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

CREATE POLICY "Authors can update their own articles"
  ON knowledge_base FOR UPDATE
  USING (author_id = auth.uid());

-- ============================================
-- KNOWLEDGE VERSIONS POLICIES
-- ============================================

CREATE POLICY "Admins can view all knowledge versions"
  ON knowledge_versions FOR SELECT
  USING (is_admin());

CREATE POLICY "Staff can view knowledge versions"
  ON knowledge_versions FOR SELECT
  USING (
    get_user_role() IN ('salon_staff', 'distributor_staff')
  );

-- ============================================
-- SKINCARE ADVICE POLICIES
-- ============================================

CREATE POLICY "Admins can manage all skincare advice"
  ON skincare_advice FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage advice for their salon's customers"
  ON skincare_advice FOR ALL
  USING (
    is_salon_staff() AND
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

CREATE POLICY "Distributor staff can view advice in their distributor"
  ON skincare_advice FOR SELECT
  USING (
    is_distributor_staff() AND
    EXISTS (
      SELECT 1 FROM skin_diagnoses
      JOIN salons ON salons.id = skin_diagnoses.salon_id
      WHERE skin_diagnoses.id = skincare_advice.diagnosis_id
      AND salons.distributor_id = get_user_distributor_id()
    )
  );

-- ============================================
-- DIET ADVICE POLICIES
-- ============================================

CREATE POLICY "Admins can manage all diet advice"
  ON diet_advice FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage diet advice for their salon's customers"
  ON diet_advice FOR ALL
  USING (
    is_salon_staff() AND
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

CREATE POLICY "Distributor staff can view diet advice in their distributor"
  ON diet_advice FOR SELECT
  USING (
    is_distributor_staff() AND
    EXISTS (
      SELECT 1 FROM skin_diagnoses
      JOIN salons ON salons.id = skin_diagnoses.salon_id
      WHERE skin_diagnoses.id = diet_advice.diagnosis_id
      AND salons.distributor_id = get_user_distributor_id()
    )
  );

-- ============================================
-- EXERCISE ADVICE POLICIES
-- ============================================

CREATE POLICY "Admins can manage all exercise advice"
  ON exercise_advice FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage exercise advice for their salon's customers"
  ON exercise_advice FOR ALL
  USING (
    is_salon_staff() AND
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

CREATE POLICY "Distributor staff can view exercise advice in their distributor"
  ON exercise_advice FOR SELECT
  USING (
    is_distributor_staff() AND
    EXISTS (
      SELECT 1 FROM skin_diagnoses
      JOIN salons ON salons.id = skin_diagnoses.salon_id
      WHERE skin_diagnoses.id = exercise_advice.diagnosis_id
      AND salons.distributor_id = get_user_distributor_id()
    )
  );

-- ============================================
-- SLEEP ADVICE POLICIES
-- ============================================

CREATE POLICY "Admins can manage all sleep advice"
  ON sleep_advice FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage sleep advice for their salon's customers"
  ON sleep_advice FOR ALL
  USING (
    is_salon_staff() AND
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

CREATE POLICY "Distributor staff can view sleep advice in their distributor"
  ON sleep_advice FOR SELECT
  USING (
    is_distributor_staff() AND
    EXISTS (
      SELECT 1 FROM skin_diagnoses
      JOIN salons ON salons.id = skin_diagnoses.salon_id
      WHERE skin_diagnoses.id = sleep_advice.diagnosis_id
      AND salons.distributor_id = get_user_distributor_id()
    )
  );

-- ============================================
-- LINE NOTIFICATIONS POLICIES
-- ============================================

CREATE POLICY "Admins can manage all notifications"
  ON line_notifications FOR ALL
  USING (is_admin());

CREATE POLICY "Salon staff can manage notifications for their salon's customers"
  ON line_notifications FOR ALL
  USING (
    is_salon_staff() AND
    EXISTS (
      SELECT 1 FROM customers
      WHERE customers.id = line_notifications.customer_id
      AND customers.salon_id = get_user_salon_id()
    )
  );

CREATE POLICY "Customers can view their own notifications"
  ON line_notifications FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM customers
      WHERE customers.id = line_notifications.customer_id
      AND customers.profile_id = auth.uid()
    )
  );

CREATE POLICY "Customers can update read status"
  ON line_notifications FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM customers
      WHERE customers.id = line_notifications.customer_id
      AND customers.profile_id = auth.uid()
    )
  );

-- ============================================
-- STORAGE BUCKETS & POLICIES
-- ============================================

-- Create storage buckets
INSERT INTO storage.buckets (id, name, public) VALUES
  ('avatars', 'avatars', true),
  ('diagnosis-photos', 'diagnosis-photos', false),
  ('treatment-photos', 'treatment-photos', false),
  ('product-images', 'product-images', true),
  ('knowledge-images', 'knowledge-images', true)
ON CONFLICT (id) DO NOTHING;

-- Avatars bucket policies
CREATE POLICY "Public avatars are viewable by everyone"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their own avatar"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can update their own avatar"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

CREATE POLICY "Users can delete their own avatar"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'avatars' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

-- Diagnosis photos bucket policies
CREATE POLICY "Salon staff can view diagnosis photos in their salon"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'diagnosis-photos' AND
    (
      is_admin() OR
      (is_salon_staff() AND
       (storage.foldername(name))[1] = get_user_salon_id()::text)
    )
  );

CREATE POLICY "Salon staff can upload diagnosis photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'diagnosis-photos' AND
    is_salon_staff() AND
    (storage.foldername(name))[1] = get_user_salon_id()::text
  );

CREATE POLICY "Salon staff can delete diagnosis photos"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'diagnosis-photos' AND
    is_salon_staff() AND
    (storage.foldername(name))[1] = get_user_salon_id()::text
  );

CREATE POLICY "Customers can view their own diagnosis photos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'diagnosis-photos' AND
    EXISTS (
      SELECT 1 FROM customers
      WHERE customers.profile_id = auth.uid()
      AND (storage.foldername(name))[2] = customers.id::text
    )
  );

-- Treatment photos bucket policies
CREATE POLICY "Salon staff can view treatment photos in their salon"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'treatment-photos' AND
    (
      is_admin() OR
      (is_salon_staff() AND
       (storage.foldername(name))[1] = get_user_salon_id()::text)
    )
  );

CREATE POLICY "Salon staff can upload treatment photos"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'treatment-photos' AND
    is_salon_staff() AND
    (storage.foldername(name))[1] = get_user_salon_id()::text
  );

CREATE POLICY "Salon staff can delete treatment photos"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'treatment-photos' AND
    is_salon_staff() AND
    (storage.foldername(name))[1] = get_user_salon_id()::text
  );

CREATE POLICY "Customers can view their own treatment photos"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'treatment-photos' AND
    EXISTS (
      SELECT 1 FROM customers
      WHERE customers.profile_id = auth.uid()
      AND (storage.foldername(name))[2] = customers.id::text
    )
  );

-- Product images bucket policies
CREATE POLICY "Public product images are viewable by everyone"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'product-images');

CREATE POLICY "Admins can upload product images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'product-images' AND
    is_admin()
  );

CREATE POLICY "Admins can update product images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'product-images' AND
    is_admin()
  );

CREATE POLICY "Admins can delete product images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'product-images' AND
    is_admin()
  );

-- Knowledge images bucket policies
CREATE POLICY "Public knowledge images are viewable by everyone"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'knowledge-images');

CREATE POLICY "Admins can upload knowledge images"
  ON storage.objects FOR INSERT
  WITH CHECK (
    bucket_id = 'knowledge-images' AND
    is_admin()
  );

CREATE POLICY "Admins can update knowledge images"
  ON storage.objects FOR UPDATE
  USING (
    bucket_id = 'knowledge-images' AND
    is_admin()
  );

CREATE POLICY "Admins can delete knowledge images"
  ON storage.objects FOR DELETE
  USING (
    bucket_id = 'knowledge-images' AND
    is_admin()
  );
