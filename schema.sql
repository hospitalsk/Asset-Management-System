-- ==============================================================================
-- สคริปต์สร้างฐานข้อมูล Supabase สำหรับ ระบบบริหารจัดการครุภัณฑ์
-- โรงพยาบาลสังขละบุรี (Sangkhlaburi Hospital Asset Management)
-- ==============================================================================

-- 1. สร้างตารางผู้ใช้งานระบบและกำหนดสิทธิ์ (users)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(100) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'department_staff', -- admin, supply_officer, department_staff
    department VARCHAR(255) DEFAULT 'งานบริการทางการแพทย์',
    phone VARCHAR(50),
    status VARCHAR(50) DEFAULT 'active', -- active, suspended
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. สร้างตารางหมวดหมู่ครุภัณฑ์ (categories)
CREATE TABLE IF NOT EXISTS categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL UNIQUE,
    icon VARCHAR(100) DEFAULT 'box',
    color VARCHAR(50) DEFAULT '#0d9488',
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. สร้างตารางสถานที่จัดเก็บ / ประจำ (locations)
CREATE TABLE IF NOT EXISTS locations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    building VARCHAR(255),
    room VARCHAR(100),
    responsible_person VARCHAR(255),
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. ตารางครุภัณฑ์หลัก (assets)
CREATE TABLE IF NOT EXISTS assets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_code VARCHAR(100) NOT NULL UNIQUE,
    asset_name VARCHAR(255) NOT NULL,
    category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
    brand VARCHAR(150),
    model VARCHAR(150),
    serial_number VARCHAR(150),
    acquisition_date DATE,
    price NUMERIC(14, 2) DEFAULT 0.00,
    funding_source VARCHAR(255) DEFAULT 'เงินงบประมาณ',
    location_id UUID REFERENCES locations(id) ON DELETE SET NULL,
    responsible_person VARCHAR(255),
    status VARCHAR(50) DEFAULT 'ใช้งานปกติ', -- ใช้งานปกติ, ยืมใช้งาน, อยู่ระหว่างซ่อม, ชำรุด, จำหน่ายแล้ว, สูญหาย
    condition VARCHAR(50) DEFAULT 'ดี',     -- ดี, พอใช้, ชำรุดรอซ่อม, ชำรุดรอจำหน่าย
    image_file_id VARCHAR(255),
    image_url TEXT,
    note TEXT,
    verification_code VARCHAR(50) NOT NULL UNIQUE,
    is_demo BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ตารางประวัติการเคลื่อนไหว / ย้าย / ยืม / คืน / จำหน่าย / สูญหาย (asset_movements)
CREATE TABLE IF NOT EXISTS asset_movements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL, -- ย้าย, ยืม, คืน, จำหน่าย, สูญหาย
    from_location_id UUID REFERENCES locations(id),
    to_location_id UUID REFERENCES locations(id),
    borrower_name VARCHAR(255),
    action_date TIMESTAMPTZ DEFAULT NOW(),
    expected_return_date DATE,
    actual_return_date TIMESTAMPTZ,
    recorded_by VARCHAR(255),
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. ตารางประวัติการซ่อมบำรุง (maintenance_records)
CREATE TABLE IF NOT EXISTS maintenance_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    asset_id UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    repair_type VARCHAR(100) NOT NULL, -- ซ่อมแซม, บำรุงรักษาเชิงป้องกัน, สอบเทียบ
    description TEXT NOT NULL,
    cost NUMERIC(12, 2) DEFAULT 0.00,
    vendor VARCHAR(255),
    start_date DATE NOT NULL,
    end_date DATE,
    status VARCHAR(50) DEFAULT 'กำลังซ่อม', -- แจ้งซ่อม, กำลังซ่อม, ซ่อมเสร็จสิ้น, ยกเลิก
    recorded_by VARCHAR(255),
    note TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. ตารางบันทึกประวัติการใช้งาน (audit_logs)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(100),
    details TEXT,
    user_name VARCHAR(150) DEFAULT 'เจ้าหน้าที่พัสดุ',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. ตารางการตั้งค่าหน่วยงาน (app_settings)
CREATE TABLE IF NOT EXISTS app_settings (
    id VARCHAR(50) PRIMARY KEY DEFAULT 'default',
    system_name VARCHAR(255) DEFAULT 'ระบบบริหารจัดการครุภัณฑ์',
    agency_name VARCHAR(255) DEFAULT 'โรงพยาบาลสังขละบุรี',
    fiscal_year VARCHAR(20) DEFAULT '2567',
    logo_url TEXT,
    address TEXT DEFAULT 'หมู่ที่ 3 ตำบลหนองลู อำเภอสังขละบุรี จังหวัดกาญจนบุรี 71240',
    phone VARCHAR(100) DEFAULT '034-595087',
    creator_name VARCHAR(150) DEFAULT 'นายสมเกียรติ มั่นคง (เจ้าหน้าที่พัสดุ)',
    checker_name VARCHAR(150) DEFAULT 'นางสาวพัชรี สุขใจ (หัวหน้าฝ่ายบริหารทั่วไป)',
    approver_name VARCHAR(150) DEFAULT 'นายแพทย์ผู้อำนวยการโรงพยาบาลสังขละบุรี',
    footer_text TEXT DEFAULT 'โรงพยาบาลสังขละบุรี สำนักงานสาธารณสุขจังหวัดกาญจนบุรี',
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Storage Bucket สำหรับรูปภาพครุภัณฑ์
INSERT INTO storage.buckets (id, name, public) 
VALUES ('asset-images', 'asset-images', true)
ON CONFLICT (id) DO NOTHING;

-- นโยบาย Storage
CREATE POLICY "Public Read Access for Asset Images" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'asset-images');

CREATE POLICY "Allow Upload for Asset Images" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'asset-images');

CREATE POLICY "Allow Update for Asset Images" 
ON storage.objects FOR UPDATE 
WITH CHECK (bucket_id = 'asset-images');

CREATE POLICY "Allow Delete for Asset Images" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'asset-images');

-- 9. นโยบาย Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE assets ENABLE ROW LEVEL SECURITY;
ALTER TABLE asset_movements ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read users" ON users FOR SELECT USING (true);
CREATE POLICY "Allow all actions users" ON users FOR ALL USING (true);

CREATE POLICY "Allow public read categories" ON categories FOR SELECT USING (true);
CREATE POLICY "Allow all actions categories" ON categories FOR ALL USING (true);

CREATE POLICY "Allow public read locations" ON locations FOR SELECT USING (true);
CREATE POLICY "Allow all actions locations" ON locations FOR ALL USING (true);

CREATE POLICY "Allow public read assets" ON assets FOR SELECT USING (true);
CREATE POLICY "Allow all actions assets" ON assets FOR ALL USING (true);

CREATE POLICY "Allow public read asset_movements" ON asset_movements FOR SELECT USING (true);
CREATE POLICY "Allow all actions asset_movements" ON asset_movements FOR ALL USING (true);

CREATE POLICY "Allow public read maintenance_records" ON maintenance_records FOR SELECT USING (true);
CREATE POLICY "Allow all actions maintenance_records" ON maintenance_records FOR ALL USING (true);

CREATE POLICY "Allow public read audit_logs" ON audit_logs FOR SELECT USING (true);
CREATE POLICY "Allow all actions audit_logs" ON audit_logs FOR ALL USING (true);

CREATE POLICY "Allow public read app_settings" ON app_settings FOR SELECT USING (true);
CREATE POLICY "Allow all actions app_settings" ON app_settings FOR ALL USING (true);

-- 10. ข้อมูลผู้ใช้งานเริ่มต้น (Initial Seed Users สำหรับโรงพยาบาลสังขละบุรี)
INSERT INTO users (id, username, password, full_name, role, department, phone, status)
VALUES 
(
    '00000000-0000-0000-0000-000000000001',
    'admin',
    'admin123',
    'นายแพทย์ผู้อำนวยการ (ผู้ดูแลระบบสูงสุด)',
    'admin',
    'กลุ่มงานบริหารทั่วไป/เทคโนโลยีสารสนเทศ',
    '034-595087 ต่อ 101',
    'active'
),
(
    '00000000-0000-0000-0000-000000000002',
    'supply',
    'supply123',
    'นายสมเกียรติ มั่นคง (เจ้าหน้าที่พัสดุ)',
    'supply_officer',
    'กลุ่มงานบริหารทั่วไป/งานพัสดุและบำรุงรักษา',
    '034-595087 ต่อ 105',
    'active'
),
(
    '00000000-0000-0000-0000-000000000003',
    'nurse_er',
    'nurse123',
    'พว.สุดารัตน์ ใจดี (พยาบาลวิชาชีพชำนาญการ)',
    'department_staff',
    'ห้องฉุกเฉินและอุบัติเหตุ (ER)',
    '034-595087 ต่อ 112',
    'active'
)
ON CONFLICT (username) DO NOTHING;

-- 11. ข้อมูลตัวอย่างเริ่มต้น (Initial Seed Data สำหรับโรงพยาบาลสังขละบุรี)
INSERT INTO app_settings (id, system_name, agency_name, fiscal_year, address, phone, creator_name, checker_name, approver_name, footer_text)
VALUES (
    'default',
    'ระบบบริหารจัดการครุภัณฑ์',
    'โรงพยาบาลสังขละบุรี',
    '2567',
    'หมู่ที่ 3 ตำบลหนองลู อำเภอสังขละบุรี จังหวัดกาญจนบุรี 71240',
    '034-595087',
    'นายสมเกียรติ มั่นคง (เจ้าหน้าที่พัสดุ)',
    'นางสาวพัชรี สุขใจ (หัวหน้าฝ่ายบริหารทั่วไป)',
    'นายแพทย์ผู้อำนวยการโรงพยาบาลสังขละบุรี',
    'โรงพยาบาลสังขละบุรี สำนักงานสาธารณสุขจังหวัดกาญจนบุรี'
) ON CONFLICT (id) DO NOTHING;

INSERT INTO categories (id, name, icon, color, note) VALUES
    ('11111111-1111-1111-1111-111111111111', 'ครุภัณฑ์การแพทย์', 'activity', '#0d9488', 'เครื่องมือและอุปกรณ์ทางการแพทย์เพื่อการรักษา'),
    ('22222222-2222-2222-2222-222222222222', 'ครุภัณฑ์สำนักงาน', 'briefcase', '#3b82f6', 'โต๊ะ ตู้ เก้าอี้ และอุปกรณ์สำนักงาน'),
    ('33333333-3333-3333-3333-333333333333', 'ครุภัณฑ์คอมพิวเตอร์', 'monitor', '#6366f1', 'คอมพิวเตอร์ แม่ข่าย และระบบเครือข่าย'),
    ('44444444-4444-4444-4444-444444444444', 'ครุภัณฑ์ยานพาหนะ', 'truck', '#f59e0b', 'รถพยาบาลฉุกเฉินและรถยนต์ส่วนกลาง')
ON CONFLICT (id) DO NOTHING;

INSERT INTO locations (id, name, building, room, responsible_person, note) VALUES
    ('aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'ห้องฉุกเฉินและอุบัติเหตุ (ER)', 'อาคารผู้ป่วยนอก', 'ชั้น 1 ห้อง 101', 'พว.สุดารัตน์ ใจดี', 'เปิดบริการ 24 ชั่วโมง'),
    ('aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'ห้องผ่าตัด (OR)', 'อาคารศัลยกรรม', 'ชั้น 2 ห้อง 204', 'นพ.ประเสริฐ กาญจนกิจ', 'พื้นที่ปลอดเชื้อ'),
    ('aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'หอผู้ป่วยใน (IPD)', 'อาคารเฉลิมพระเกียรติ', 'ชั้น 3', 'พว.นันทนา รักษ์ไทย', 'วอร์ดรวม'),
    ('aaaaaaa4-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'ห้องตรวจผู้ป่วยนอก (OPD)', 'อาคารผู้ป่วยนอก', 'ชั้น 1', 'นางสาววาสนา ศรีสุข', 'คลินิกโรคทั่วไป'),
    ('aaaaaaa5-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'กลุ่มงานบริหารทั่วไป/พัสดุ', 'อาคารอำนวยการ', 'ชั้น 2 ห้อง 201', 'นายสมเกียรติ มั่นคง', 'งานจัดซื้อและคลังพัสดุ')
ON CONFLICT (id) DO NOTHING;

INSERT INTO assets (
    id, asset_code, asset_name, category_id, brand, model, serial_number, 
    acquisition_date, price, funding_source, location_id, responsible_person, 
    status, condition, image_file_id, image_url, note, verification_code, is_demo
) VALUES
(
    'bbbbbbb1-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'สธ-6530-001-0042',
    'เครื่องกระตุกหัวใจด้วยไฟฟ้าอัตโนมัติ (Defibrillator)',
    '11111111-1111-1111-1111-111111111111',
    'Zoll', 'R Series Plus', 'SN-ZL-2023-8891',
    '2023-03-15', 385000.00, 'งบลงทุนค่าเสื่อมราคา',
    'aaaaaaa1-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'พว.สุดารัตน์ ใจดี',
    'ใช้งานปกติ', 'ดี',
    NULL, 'https://images.unsplash.com/photo-1516549655169-df83a0774514?w=600&auto=format&fit=crop&q=80',
    'ตรวจเช็คแบตเตอรี่ทุกเดือน พร้อมใช้งานฉุกเฉิน',
    'SKB-VER-88219', true
),
(
    'bbbbbbb2-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'สธ-6530-002-0018',
    'เครื่องตรวจอวัยวะภายในด้วยคลื่นเสียงความถี่สูง (Ultrasound)',
    '11111111-1111-1111-1111-111111111111',
    'GE Healthcare', 'Logiq P9', 'SN-GE-991204',
    '2022-08-20', 1250000.00, 'งบประมาณแผ่นดิน',
    'aaaaaaa4-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'พญ.กานดา สุวรรณ',
    'ใช้งานปกติ', 'ดี',
    NULL, 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=600&auto=format&fit=crop&q=80',
    'หัวตรวจ 3 หัว บันทึกภาพลงระบบ PACS ได้',
    'SKB-VER-45192', true
),
(
    'bbbbbbb3-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'สธ-7440-003-0105',
    'เครื่องติดตามการทำงานของหัวใจและสัญญาณชีพ (Patient Monitor)',
    '11111111-1111-1111-1111-111111111111',
    'Mindray', 'ePM 12M', 'SN-MD-309182',
    '2021-11-10', 180000.00, 'เงินบำรุงโรงพยาบาล',
    'aaaaaaa3-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'พว.นันทนา รักษ์ไทย',
    'อยู่ระหว่างซ่อม', 'ชำรุดรอซ่อม',
    NULL, 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?w=600&auto=format&fit=crop&q=80',
    'สายวัด SpO2 ขัดข้อง ส่งเคลมศูนย์ซ่อม Mindray',
    'SKB-VER-77310', true
),
(
    'bbbbbbb4-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'สธ-8415-004-0056',
    'เครื่องช่วยหายใจชนิดควบคุมด้วยปริมาตรและความดัน (Ventilator)',
    '11111111-1111-1111-1111-111111111111',
    'Hamilton', 'Hamilton-C3', 'SN-HM-554109',
    '2022-01-05', 890000.00, 'งบพัฒนาจังหวัดกาญจนบุรี',
    'aaaaaaa2-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'นพ.ประเสริฐ กาญจนกิจ',
    'ใช้งานปกติ', 'ดี',
    NULL, 'https://images.unsplash.com/photo-1583912267670-6575ad4e8bb8?w=600&auto=format&fit=crop&q=80',
    'สอบเทียบมาตรฐานประจำปีเรียบร้อย',
    'SKB-VER-33290', true
),
(
    'bbbbbbb5-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'สธ-6710-005-0210',
    'เครื่องคอมพิวเตอร์แม่ข่ายระบบ HIS (Hospital Server)',
    '33333333-3333-3333-3333-333333333333',
    'Dell', 'PowerEdge R750', 'SN-DL-883011',
    '2023-06-12', 245000.00, 'เงินบำรุงโรงพยาบาล',
    'aaaaaaa5-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'นายพิชิต เทคโนโลยี',
    'ใช้งานปกติ', 'ดี',
    NULL, 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=600&auto=format&fit=crop&q=80',
    'สำรองข้อมูลทุกเที่ยงคืน RAID 10',
    'SKB-VER-91024', true
)
ON CONFLICT (id) DO NOTHING;
