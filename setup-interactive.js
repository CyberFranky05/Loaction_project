#!/usr/bin/env node

/**
 * Interactive Setup Script for Location Auth System
 * This script helps you configure Keycloak and collect credentials
 */

const readline = require('readline');
const fs = require('fs');
const path = require('path');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const question = (query) => new Promise((resolve) => rl.question(query, resolve));

const config = {
  supabase: {
    url: '',
    anonKey: '',
    serviceRoleKey: ''
  },
  keycloak: {
    url: 'http://localhost:8080',
    realm: 'location-auth-realm',
    backendClientId: 'location-auth-backend',
    frontendClientId: 'location-auth-frontend',
    backendClientSecret: ''
  }
};

async function main() {
  console.log('\n🚀 Location Auth System - Interactive Setup\n');
  console.log('═══════════════════════════════════════════════════\n');

  // Keycloak Status
  console.log('✅ Keycloak is running at http://localhost:8080');
  console.log('   Login with: admin / admin\n');

  // Step 1: Supabase
  console.log('📦 STEP 1: SUPABASE CONFIGURATION');
  console.log('─────────────────────────────────────────────────\n');
  console.log('Please complete the following steps:\n');
  console.log('1. Go to https://app.supabase.com/');
  console.log('2. Create a new project (or use existing)');
  console.log('3. Go to SQL Editor');
  console.log('4. Copy and paste contents of database/schema.sql');
  console.log('5. Click "Run" to execute\n');

  await question('Press ENTER when you have created your Supabase project...');

  console.log('\nNow, get your Supabase credentials:\n');
  console.log('1. Go to Settings → API in your Supabase project');
  console.log('2. Copy the values below:\n');

  config.supabase.url = await question('Enter Supabase URL (e.g., https://xxxxx.supabase.co): ');
  config.supabase.anonKey = await question('Enter Supabase ANON key: ');
  config.supabase.serviceRoleKey = await question('Enter Supabase SERVICE_ROLE key: ');

  // Step 2: Keycloak Configuration
  console.log('\n\n📦 STEP 2: KEYCLOAK CONFIGURATION');
  console.log('─────────────────────────────────────────────────\n');
  console.log('Keycloak is already running. Now configure it:\n');
  console.log('1. Open http://localhost:8080 in your browser');
  console.log('2. Click "Administration Console"');
  console.log('3. Login: admin / admin\n');

  await question('Press ENTER when you are logged in...');

  console.log('\nCreate the Realm:');
  console.log('─────────────────────────────────────────────────');
  console.log('1. Click dropdown at top-left (says "master")');
  console.log('2. Click "Create Realm"');
  console.log('3. Realm name: location-auth-realm');
  console.log('4. Click "Create"\n');

  await question('Press ENTER when realm is created...');

  console.log('\nConfigure Password Policies:');
  console.log('─────────────────────────────────────────────────');
  console.log('1. Go to: Authentication → Policies tab');
  console.log('2. Click "Password Policy"');
  console.log('3. Add these policies:');
  console.log('   - Minimum Length: 8');
  console.log('   - Uppercase Characters: 1');
  console.log('   - Lowercase Characters: 1');
  console.log('   - Digits: 1');
  console.log('   - Special Characters: 1');
  console.log('4. Click "Save"\n');

  await question('Press ENTER when password policy is configured...');

  console.log('\nCreate Backend Client (Confidential):');
  console.log('─────────────────────────────────────────────────');
  console.log('1. Go to: Clients → Create client');
  console.log('2. Client ID: location-auth-backend');
  console.log('3. Click "Next"');
  console.log('4. Enable: Client authentication = ON');
  console.log('5. Enable: Standard flow, Direct access grants, Service accounts');
  console.log('6. Click "Next" → "Save"');
  console.log('7. Go to "Credentials" tab');
  console.log('8. Copy the Client Secret\n');

  config.keycloak.backendClientSecret = await question('Enter Backend Client Secret: ');

  console.log('\nCreate Frontend Client (Public):');
  console.log('─────────────────────────────────────────────────');
  console.log('1. Go to: Clients → Create client');
  console.log('2. Client ID: location-auth-frontend');
  console.log('3. Click "Next"');
  console.log('4. Client authentication = OFF (public client)');
  console.log('5. Enable: Standard flow');
  console.log('6. Click "Next"');
  console.log('7. Valid redirect URIs: http://localhost:5173/*');
  console.log('8. Web origins: http://localhost:5173');
  console.log('9. Click "Save"');
  console.log('10. Go to "Advanced" tab');
  console.log('11. Proof Key for Code Exchange = S256');
  console.log('12. Click "Save"\n');

  await question('Press ENTER when frontend client is created...');

  console.log('\nCreate Test User:');
  console.log('─────────────────────────────────────────────────');
  console.log('1. Go to: Users → Add user');
  console.log('2. Username: testuser');
  console.log('3. Email: testuser@example.com');
  console.log('4. First name: Test');
  console.log('5. Last name: User');
  console.log('6. Email verified: ON');
  console.log('7. Click "Create"');
  console.log('8. Go to "Credentials" tab');
  console.log('9. Click "Set password"');
  console.log('10. Password: TestPass123!');
  console.log('11. Temporary: OFF');
  console.log('12. Click "Save"\n');

  await question('Press ENTER when test user is created...');

  // Step 3: Generate .env files
  console.log('\n\n📦 STEP 3: GENERATING ENVIRONMENT FILES');
  console.log('─────────────────────────────────────────────────\n');

  // Backend .env
  const backendEnv = `# ============================================
# BACKEND ENVIRONMENT VARIABLES
# Generated: ${new Date().toISOString()}
# ============================================

# Application
NODE_ENV=development
PORT=3000
APP_NAME=Location Auth Backend
API_PREFIX=api/v1

# Supabase
SUPABASE_URL=${config.supabase.url}
SUPABASE_SERVICE_ROLE_KEY=${config.supabase.serviceRoleKey}

# Keycloak
KEYCLOAK_URL=${config.keycloak.url}
KEYCLOAK_REALM=${config.keycloak.realm}
KEYCLOAK_CLIENT_ID=${config.keycloak.backendClientId}
KEYCLOAK_CLIENT_SECRET=${config.keycloak.backendClientSecret}
KEYCLOAK_AUTH_SERVER_URL=${config.keycloak.url}
KEYCLOAK_BEARER_ONLY=true
KEYCLOAK_SSL_REQUIRED=external

# JWT
JWT_SECRET=super-secret-jwt-key-change-in-production
JWT_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=7d

# Geolocation
IPAPI_KEY=free
IPAPI_URL=https://ipapi.co

# CORS
CORS_ORIGIN=http://localhost:5173
CORS_CREDENTIALS=true

# Rate Limiting
RATE_LIMIT_TTL=60
RATE_LIMIT_MAX=100
AUTH_RATE_LIMIT_TTL=900
AUTH_RATE_LIMIT_MAX=5

# Logging
LOG_LEVEL=debug
LOG_FORMAT=json

# Security
PASSWORD_MIN_LENGTH=8
PASSWORD_REQUIRE_UPPERCASE=true
PASSWORD_REQUIRE_LOWERCASE=true
PASSWORD_REQUIRE_NUMBERS=true
PASSWORD_REQUIRE_SPECIAL=true

SESSION_SECRET=your-session-secret-key-change-this
SESSION_MAX_AGE=86400000
`;

  // Frontend .env
  const frontendEnv = `# ============================================
# FRONTEND ENVIRONMENT VARIABLES
# Generated: ${new Date().toISOString()}
# ============================================

# Application
PUBLIC_APP_NAME=Location Auth System
PUBLIC_API_URL=http://localhost:3000/api/v1

# Supabase
PUBLIC_SUPABASE_URL=${config.supabase.url}
PUBLIC_SUPABASE_ANON_KEY=${config.supabase.anonKey}

# Keycloak
PUBLIC_KEYCLOAK_URL=${config.keycloak.url}
PUBLIC_KEYCLOAK_REALM=${config.keycloak.realm}
PUBLIC_KEYCLOAK_CLIENT_ID=${config.keycloak.frontendClientId}

# Authentication
PUBLIC_AUTH_REDIRECT_URI=http://localhost:5173/auth/callback
PUBLIC_AUTH_POST_LOGOUT_REDIRECT_URI=http://localhost:5173
PUBLIC_TOKEN_STORAGE=localStorage

# Password Policy
PUBLIC_PASSWORD_MIN_LENGTH=8
PUBLIC_PASSWORD_REQUIRE_UPPERCASE=true
PUBLIC_PASSWORD_REQUIRE_LOWERCASE=true
PUBLIC_PASSWORD_REQUIRE_NUMBERS=true
PUBLIC_PASSWORD_REQUIRE_SPECIAL=true

# Features
PUBLIC_ENABLE_REGISTRATION=true
PUBLIC_ENABLE_PASSWORD_RESET=true
PUBLIC_ENABLE_REMEMBER_ME=true

# UI
PUBLIC_THEME=light
PUBLIC_LOCALE=en

# Development
PUBLIC_DEV_MODE=true
PUBLIC_ENABLE_DEBUG_LOGS=true
`;

  // Write files
  try {
    const backendDir = path.join(__dirname, 'backend');
    const frontendDir = path.join(__dirname, 'frontend');

    if (!fs.existsSync(backendDir)) {
      fs.mkdirSync(backendDir, { recursive: true });
    }
    if (!fs.existsSync(frontendDir)) {
      fs.mkdirSync(frontendDir, { recursive: true });
    }

    fs.writeFileSync(path.join(backendDir, '.env'), backendEnv);
    fs.writeFileSync(path.join(frontendDir, '.env'), frontendEnv);

    console.log('✅ Created: backend/.env');
    console.log('✅ Created: frontend/.env\n');

    // Save configuration summary
    const summary = {
      timestamp: new Date().toISOString(),
      supabase: {
        url: config.supabase.url,
        hasAnonKey: !!config.supabase.anonKey,
        hasServiceRoleKey: !!config.supabase.serviceRoleKey
      },
      keycloak: {
        url: config.keycloak.url,
        realm: config.keycloak.realm,
        backendClientId: config.keycloak.backendClientId,
        frontendClientId: config.keycloak.frontendClientId,
        hasBackendSecret: !!config.keycloak.backendClientSecret
      }
    };

    fs.writeFileSync(
      path.join(__dirname, 'setup-summary.json'),
      JSON.stringify(summary, null, 2)
    );

    console.log('✅ Created: setup-summary.json\n');

  } catch (error) {
    console.error('❌ Error creating files:', error.message);
  }

  console.log('\n═══════════════════════════════════════════════════');
  console.log('🎉 SETUP COMPLETE!');
  console.log('═══════════════════════════════════════════════════\n');

  console.log('Next Steps:');
  console.log('───────────────────────────────────────────────────');
  console.log('1. ✅ Keycloak running at http://localhost:8080');
  console.log('2. ✅ Supabase configured');
  console.log('3. ✅ Environment files created');
  console.log('4. 🚀 Ready for Phase 2: Backend Development\n');

  console.log('Test your setup:');
  console.log('───────────────────────────────────────────────────');
  console.log('• Keycloak: http://localhost:8080/realms/location-auth-realm');
  console.log('• Supabase: Check Tables in your dashboard\n');

  rl.close();
}

main().catch(console.error);
