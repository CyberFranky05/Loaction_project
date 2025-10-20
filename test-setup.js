#!/usr/bin/env node

/**
 * Test Script - Verify Keycloak and Supabase Setup
 * Run this after completing configuration
 */

const https = require('https');
const http = require('http');

// Colors for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[36m'
};

function log(message, color = 'reset') {
  console.log(`${colors[color]}${message}${colors.reset}`);
}

async function makeRequest(url, options = {}) {
  return new Promise((resolve, reject) => {
    const protocol = url.startsWith('https') ? https : http;
    
    protocol.get(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(data) });
        } catch {
          resolve({ status: res.statusCode, data });
        }
      });
    }).on('error', reject);
  });
}

async function testKeycloak() {
  log('\n🔐 Testing Keycloak...', 'blue');
  log('─────────────────────────────────────────────────');
  
  try {
    // Test 1: Check if Keycloak is running
    const realmUrl = 'http://localhost:8080/realms/location-auth-realm/.well-known/openid-configuration';
    log('Testing Keycloak realm endpoint...', 'yellow');
    
    const response = await makeRequest(realmUrl);
    
    if (response.status === 200) {
      log('✅ Keycloak is running and realm exists!', 'green');
      log(`   Issuer: ${response.data.issuer}`, 'green');
      log(`   Token endpoint: ${response.data.token_endpoint}`, 'green');
      return true;
    } else {
      log(`❌ Unexpected status: ${response.status}`, 'red');
      return false;
    }
  } catch (error) {
    log(`❌ Keycloak test failed: ${error.message}`, 'red');
    log('   Make sure Keycloak is running: docker ps | findstr keycloak', 'yellow');
    return false;
  }
}

async function testSupabase(url, key) {
  log('\n📦 Testing Supabase...', 'blue');
  log('─────────────────────────────────────────────────');
  
  if (!url || !key) {
    log('⚠️  Supabase credentials not provided', 'yellow');
    log('   Please provide SUPABASE_URL and SUPABASE_KEY as arguments', 'yellow');
    return false;
  }
  
  try {
    log('Testing Supabase connection...', 'yellow');
    
    const testUrl = `${url}/rest/v1/users?select=count&limit=1`;
    const response = await makeRequest(testUrl, {
      headers: {
        'apikey': key,
        'Authorization': `Bearer ${key}`
      }
    });
    
    if (response.status === 200) {
      log('✅ Supabase connection successful!', 'green');
      log('   Tables are accessible', 'green');
      return true;
    } else if (response.status === 401) {
      log('❌ Authentication failed - check your API key', 'red');
      return false;
    } else {
      log(`⚠️  Unexpected status: ${response.status}`, 'yellow');
      return false;
    }
  } catch (error) {
    log(`❌ Supabase test failed: ${error.message}`, 'red');
    return false;
  }
}

function checkEnvironmentFiles() {
  log('\n📂 Checking Environment Files...', 'blue');
  log('─────────────────────────────────────────────────');
  
  const fs = require('fs');
  const path = require('path');
  
  const backendEnvPath = path.join(__dirname, 'backend', '.env');
  const frontendEnvPath = path.join(__dirname, 'frontend', '.env');
  
  let allGood = true;
  
  if (fs.existsSync(backendEnvPath)) {
    log('✅ backend/.env exists', 'green');
    
    const content = fs.readFileSync(backendEnvPath, 'utf-8');
    if (content.includes('xxxxx') || content.includes('your-')) {
      log('   ⚠️  Contains placeholder values - needs configuration', 'yellow');
      allGood = false;
    }
  } else {
    log('❌ backend/.env not found', 'red');
    allGood = false;
  }
  
  if (fs.existsSync(frontendEnvPath)) {
    log('✅ frontend/.env exists', 'green');
    
    const content = fs.readFileSync(frontendEnvPath, 'utf-8');
    if (content.includes('xxxxx') || content.includes('your-')) {
      log('   ⚠️  Contains placeholder values - needs configuration', 'yellow');
      allGood = false;
    }
  } else {
    log('❌ frontend/.env not found', 'red');
    allGood = false;
  }
  
  return allGood;
}

async function main() {
  log('\n═══════════════════════════════════════════════════', 'blue');
  log('🧪 Setup Verification Test', 'blue');
  log('═══════════════════════════════════════════════════', 'blue');
  
  const envCheck = checkEnvironmentFiles();
  const keycloakCheck = await testKeycloak();
  
  // Get Supabase credentials from command line args or env
  const supabaseUrl = process.argv[2] || process.env.SUPABASE_URL;
  const supabaseKey = process.argv[3] || process.env.SUPABASE_ANON_KEY;
  
  const supabaseCheck = await testSupabase(supabaseUrl, supabaseKey);
  
  log('\n═══════════════════════════════════════════════════', 'blue');
  log('📊 Test Results Summary', 'blue');
  log('═══════════════════════════════════════════════════', 'blue');
  
  log(`Environment Files: ${envCheck ? '✅ PASS' : '❌ FAIL'}`, envCheck ? 'green' : 'red');
  log(`Keycloak: ${keycloakCheck ? '✅ PASS' : '❌ FAIL'}`, keycloakCheck ? 'green' : 'red');
  log(`Supabase: ${supabaseCheck ? '✅ PASS' : '⚠️  SKIP (no credentials)'}`, supabaseCheck ? 'green' : 'yellow');
  
  if (envCheck && keycloakCheck && supabaseCheck) {
    log('\n🎉 All tests passed! Ready for Phase 2!', 'green');
  } else {
    log('\n⚠️  Some tests failed. Review the checklist.', 'yellow');
    log('See SETUP_CHECKLIST.md for detailed steps', 'yellow');
  }
  
  log('\nUsage:', 'blue');
  log('  node test-setup.js [SUPABASE_URL] [SUPABASE_KEY]', 'yellow');
  log('\nExample:', 'blue');
  log('  node test-setup.js https://xxx.supabase.co eyJhbGc...', 'yellow');
  log('');
}

main().catch(console.error);
