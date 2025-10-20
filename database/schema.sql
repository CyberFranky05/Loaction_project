-- ============================================
-- Supabase Database Schema
-- Location-Based Authentication System
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    keycloak_id VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_users_keycloak_id ON users(keycloak_id);
CREATE INDEX idx_users_email ON users(email);

-- Add comments
COMMENT ON TABLE users IS 'Stores user profile information synced from Keycloak';
COMMENT ON COLUMN users.keycloak_id IS 'UUID from Keycloak user ID';
COMMENT ON COLUMN users.email IS 'User email address (unique)';
COMMENT ON COLUMN users.name IS 'User display name';

-- ============================================
-- SIGN IN ATTEMPTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS sign_in_attempts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45) NOT NULL,
    country VARCHAR(100),
    city VARCHAR(100),
    region VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    timezone VARCHAR(50),
    isp VARCHAR(255),
    user_agent TEXT,
    browser VARCHAR(100),
    device VARCHAR(100),
    os VARCHAR(100),
    success BOOLEAN NOT NULL DEFAULT false,
    failure_reason VARCHAR(255),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for performance
CREATE INDEX idx_sign_in_attempts_user_id ON sign_in_attempts(user_id);
CREATE INDEX idx_sign_in_attempts_email ON sign_in_attempts(email);
CREATE INDEX idx_sign_in_attempts_timestamp ON sign_in_attempts(timestamp DESC);
CREATE INDEX idx_sign_in_attempts_success ON sign_in_attempts(success);
CREATE INDEX idx_sign_in_attempts_ip ON sign_in_attempts(ip_address);

-- Add comments
COMMENT ON TABLE sign_in_attempts IS 'Logs all authentication attempts with geolocation data';
COMMENT ON COLUMN sign_in_attempts.user_id IS 'Reference to users table (NULL for failed attempts by unknown users)';
COMMENT ON COLUMN sign_in_attempts.email IS 'Email used in sign-in attempt';
COMMENT ON COLUMN sign_in_attempts.ip_address IS 'IPv4 or IPv6 address';
COMMENT ON COLUMN sign_in_attempts.success IS 'Whether the sign-in attempt was successful';
COMMENT ON COLUMN sign_in_attempts.failure_reason IS 'Reason for failure (e.g., invalid password, user not found)';

-- ============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================

-- Enable RLS on tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE sign_in_attempts ENABLE ROW LEVEL SECURITY;

-- ============================================
-- USERS TABLE POLICIES
-- ============================================

-- Policy: Users can read their own data
CREATE POLICY "Users can view own profile"
    ON users
    FOR SELECT
    USING (auth.jwt() ->> 'sub' = keycloak_id);

-- Policy: Users can update their own data
CREATE POLICY "Users can update own profile"
    ON users
    FOR UPDATE
    USING (auth.jwt() ->> 'sub' = keycloak_id)
    WITH CHECK (auth.jwt() ->> 'sub' = keycloak_id);

-- Policy: Service role can insert users (for backend)
CREATE POLICY "Service role can insert users"
    ON users
    FOR INSERT
    WITH CHECK (true);

-- Policy: Service role can read all users
CREATE POLICY "Service role can read all users"
    ON users
    FOR SELECT
    USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================
-- SIGN IN ATTEMPTS TABLE POLICIES
-- ============================================

-- Policy: Users can read their own sign-in attempts
CREATE POLICY "Users can view own sign-in attempts"
    ON sign_in_attempts
    FOR SELECT
    USING (
        user_id IN (
            SELECT id FROM users WHERE keycloak_id = auth.jwt() ->> 'sub'
        )
    );

-- Policy: Service role can insert sign-in attempts
CREATE POLICY "Service role can insert sign-in attempts"
    ON sign_in_attempts
    FOR INSERT
    WITH CHECK (true);

-- Policy: Service role can read all sign-in attempts
CREATE POLICY "Service role can read all sign-in attempts"
    ON sign_in_attempts
    FOR SELECT
    USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function: Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger: Auto-update updated_at on users table
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VIEWS (Optional but useful)
-- ============================================

-- View: Recent sign-in attempts with user details
CREATE OR REPLACE VIEW recent_sign_in_attempts AS
SELECT 
    sia.id,
    sia.user_id,
    u.name,
    sia.email,
    sia.ip_address,
    sia.country,
    sia.city,
    sia.region,
    sia.latitude,
    sia.longitude,
    sia.user_agent,
    sia.browser,
    sia.device,
    sia.os,
    sia.success,
    sia.failure_reason,
    sia.timestamp
FROM sign_in_attempts sia
LEFT JOIN users u ON sia.user_id = u.id
ORDER BY sia.timestamp DESC
LIMIT 100;

-- View: Successful sign-ins by country
CREATE OR REPLACE VIEW sign_ins_by_country AS
SELECT 
    country,
    COUNT(*) as total_attempts,
    SUM(CASE WHEN success THEN 1 ELSE 0 END) as successful_attempts,
    SUM(CASE WHEN NOT success THEN 1 ELSE 0 END) as failed_attempts
FROM sign_in_attempts
WHERE country IS NOT NULL
GROUP BY country
ORDER BY total_attempts DESC;

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Uncomment to insert sample data
/*
INSERT INTO users (keycloak_id, name, email) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'John Doe', 'john.doe@example.com'),
('550e8400-e29b-41d4-a716-446655440001', 'Jane Smith', 'jane.smith@example.com');

INSERT INTO sign_in_attempts (user_id, email, ip_address, country, city, latitude, longitude, user_agent, success) VALUES
((SELECT id FROM users WHERE email = 'john.doe@example.com'), 'john.doe@example.com', '203.0.113.1', 'United States', 'New York', 40.7128, -74.0060, 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', true),
((SELECT id FROM users WHERE email = 'jane.smith@example.com'), 'jane.smith@example.com', '198.51.100.1', 'United Kingdom', 'London', 51.5074, -0.1278, 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)', false);
*/

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Check tables
-- SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';

-- Check policies
-- SELECT * FROM pg_policies WHERE schemaname = 'public';

-- Count records
-- SELECT 'users' as table_name, COUNT(*) as count FROM users
-- UNION ALL
-- SELECT 'sign_in_attempts', COUNT(*) FROM sign_in_attempts;
