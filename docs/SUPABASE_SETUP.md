# Supabase Setup Guide

## Step 1: Create Supabase Project

1. Go to [Supabase Dashboard](https://app.supabase.com/)
2. Click **"New Project"**
3. Fill in the details:
   - **Project Name**: `location-auth-system` (or your preferred name)
   - **Database Password**: Create a strong password (save this!)
   - **Region**: Choose closest to your users
   - **Pricing Plan**: Select Free tier for development

4. Wait 2-3 minutes for project creation

## Step 2: Execute Database Schema

1. In your Supabase project, go to **SQL Editor** (left sidebar)
2. Click **"New Query"**
3. Copy the entire contents of `database/schema.sql`
4. Paste into the SQL editor
5. Click **"Run"** or press `Ctrl+Enter`
6. Verify success - you should see "Success. No rows returned"

## Step 3: Verify Tables Created

1. Go to **Table Editor** (left sidebar)
2. You should see two tables:
   - ✅ `users`
   - ✅ `sign_in_attempts`

3. Click on each table to verify columns

## Step 4: Get API Credentials

### Project URL
1. Go to **Settings** → **API**
2. Copy **Project URL**
   - Format: `https://xxxxx.supabase.co`
   - Save as: `SUPABASE_URL`

### API Keys
You'll need two keys:

#### For Backend (Service Role Key)
1. In **Settings** → **API** → **Project API keys**
2. Copy **service_role** key (secret!)
3. ⚠️ **NEVER expose this in frontend code**
4. Save as: `SUPABASE_SERVICE_ROLE_KEY`

#### For Frontend (Anon Key)
1. Copy **anon** / **public** key
2. Safe to use in frontend
3. Save as: `SUPABASE_ANON_KEY`

### Database Connection String (Optional)
1. Go to **Settings** → **Database**
2. Scroll to **Connection String**
3. Copy **URI** format
4. Save as: `SUPABASE_DB_URL` (if needed for direct connections)

## Step 5: Configure Row Level Security (RLS)

RLS is already configured in the schema, but verify:

1. Go to **Authentication** → **Policies**
2. Select `users` table:
   - ✅ Users can view own profile
   - ✅ Users can update own profile
   - ✅ Service role can insert users
   - ✅ Service role can read all users

3. Select `sign_in_attempts` table:
   - ✅ Users can view own sign-in attempts
   - ✅ Service role can insert sign-in attempts
   - ✅ Service role can read all sign-in attempts

## Step 6: Test Database Connection

Run this test query in SQL Editor:

```sql
-- Insert test user
INSERT INTO users (keycloak_id, name, email) 
VALUES ('test-123', 'Test User', 'test@example.com');

-- Insert test sign-in attempt
INSERT INTO sign_in_attempts (
    email, ip_address, country, city, success
) VALUES (
    'test@example.com', '192.168.1.1', 'Test Country', 'Test City', true
);

-- Query to verify
SELECT * FROM users;
SELECT * FROM sign_in_attempts;

-- Clean up test data
DELETE FROM sign_in_attempts WHERE email = 'test@example.com';
DELETE FROM users WHERE email = 'test@example.com';
```

## Step 7: Configure Authentication (Optional)

If you want to use Supabase Auth alongside Keycloak:

1. Go to **Authentication** → **Providers**
2. Enable **Email** provider
3. Configure **Email Templates** (optional)
4. Set **Site URL** in **Authentication** → **URL Configuration**

**Note**: We're primarily using Keycloak for auth, but this can be useful for testing.

## Environment Variables Summary

Add these to your `.env` files:

### Backend `.env`:
```env
SUPABASE_URL=https://xxxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJhbGc...your-service-role-key
```

### Frontend `.env`:
```env
PUBLIC_SUPABASE_URL=https://xxxxx.supabase.co
PUBLIC_SUPABASE_ANON_KEY=eyJhbGc...your-anon-key
```

## Troubleshooting

### Issue: RLS policies blocking queries
**Solution**: Ensure you're using the service_role key in backend, not anon key

### Issue: Cannot insert data
**Solution**: Check RLS policies and ensure service role is being used

### Issue: Connection timeout
**Solution**: Check if your IP is whitelisted in Supabase dashboard (Settings → Database → Connection Pooling)

### Issue: Tables not showing
**Solution**: Re-run the schema.sql file and check for errors in SQL Editor

## Next Steps

✅ Supabase database is ready!

Now proceed to:
- Configure Keycloak (see `docs/KEYCLOAK_SETUP.md`)
- Set up environment variables
- Start building the backend (NestJS)
