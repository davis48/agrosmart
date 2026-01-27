/**
 * Load Testing Configuration for AgriSmart CI
 * Uses k6 (https://k6.io/) for load testing
 * 
 * Installation: brew install k6 (macOS) or https://k6.io/docs/getting-started/installation
 * 
 * Run tests:
 *   k6 run backend/tests/load/scenarios.js
 *   k6 run --vus 10 --duration 30s backend/tests/load/scenarios.js
 */

// k6 specific globals are defined by the runtime, not a linter issue
// @ts-nocheck
import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Counter, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const loginSuccess = new Counter('login_success');
const apiLatency = new Trend('api_latency');

// Test configuration
export const options = {
  // Virtual users scenarios
  scenarios: {
    // Smoke test - verify system works
    smoke: {
      executor: 'constant-vus',
      vus: 1,
      duration: '1m',
      tags: { test_type: 'smoke' },
    },
    // Average load
    average_load: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 50 },  // Ramp up to 50 users
        { duration: '5m', target: 50 },  // Stay at 50 for 5 minutes
        { duration: '2m', target: 0 },   // Ramp down
      ],
      tags: { test_type: 'load' },
      startTime: '1m', // Start after smoke test
    },
    // Stress test
    stress: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '2m', target: 100 },
        { duration: '5m', target: 100 },
        { duration: '2m', target: 200 },
        { duration: '5m', target: 200 },
        { duration: '2m', target: 0 },
      ],
      tags: { test_type: 'stress' },
      startTime: '10m', // Start after load test
    },
  },
  // Thresholds
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1500'], // 95% under 500ms, 99% under 1.5s
    http_req_failed: ['rate<0.01'],                  // Less than 1% failed requests
    errors: ['rate<0.1'],                            // Less than 10% errors
  },
};

// Environment configuration
const BASE_URL = __ENV.API_URL || 'http://localhost:8000/api/v1';
const TEST_USER = {
  email: __ENV.TEST_EMAIL || 'loadtest@example.com',
  password: __ENV.TEST_PASSWORD || 'LoadTest123!',
};

// Helper functions
function getHeaders(token = null) {
  const headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return headers;
}

// Main test function
export default function() {
  let token = null;

  group('Authentication', function() {
    // Login
    const loginRes = http.post(
      `${BASE_URL}/auth/login`,
      JSON.stringify({
        email: TEST_USER.email,
        password: TEST_USER.password,
      }),
      { headers: getHeaders() }
    );

    const loginSuccess = check(loginRes, {
      'login successful': (r) => r.status === 200,
      'has access token': (r) => JSON.parse(r.body).accessToken !== undefined,
    });

    if (loginSuccess) {
      token = JSON.parse(loginRes.body).accessToken;
      loginSuccess.add(1);
    } else {
      errorRate.add(1);
    }

    apiLatency.add(loginRes.timings.duration);
    sleep(1);
  });

  if (!token) return;

  group('Dashboard Data', function() {
    // Get user profile
    const profileRes = http.get(
      `${BASE_URL}/auth/me`,
      { headers: getHeaders(token) }
    );
    check(profileRes, {
      'profile loaded': (r) => r.status === 200,
    });
    apiLatency.add(profileRes.timings.duration);

    // Get parcelles
    const parcellesRes = http.get(
      `${BASE_URL}/parcelles`,
      { headers: getHeaders(token) }
    );
    check(parcellesRes, {
      'parcelles loaded': (r) => r.status === 200,
    });
    apiLatency.add(parcellesRes.timings.duration);

    // Get weather
    const weatherRes = http.get(
      `${BASE_URL}/meteo/forecast?lat=5.36&lon=-4.0`,
      { headers: getHeaders(token) }
    );
    check(weatherRes, {
      'weather loaded': (r) => r.status === 200,
    });
    apiLatency.add(weatherRes.timings.duration);

    // Get alerts
    const alertsRes = http.get(
      `${BASE_URL}/alertes`,
      { headers: getHeaders(token) }
    );
    check(alertsRes, {
      'alerts loaded': (r) => r.status === 200,
    });
    apiLatency.add(alertsRes.timings.duration);

    sleep(2);
  });

  group('Marketplace', function() {
    // Get products
    const productsRes = http.get(
      `${BASE_URL}/marketplace/produits?page=1&limit=20`,
      { headers: getHeaders(token) }
    );
    check(productsRes, {
      'products loaded': (r) => r.status === 200,
    });
    apiLatency.add(productsRes.timings.duration);

    // Get group purchases
    const groupPurchasesRes = http.get(
      `${BASE_URL}/marketplace/achats-groupes`,
      { headers: getHeaders(token) }
    );
    check(groupPurchasesRes, {
      'group purchases loaded': (r) => r.status === 200,
    });
    apiLatency.add(groupPurchasesRes.timings.duration);

    sleep(1);
  });

  group('Sensors & Analytics', function() {
    // Get sensors
    const sensorsRes = http.get(
      `${BASE_URL}/capteurs`,
      { headers: getHeaders(token) }
    );
    check(sensorsRes, {
      'sensors loaded': (r) => r.status === 200,
    });
    apiLatency.add(sensorsRes.timings.duration);

    // Get analytics (if parcelle exists)
    const analyticsRes = http.get(
      `${BASE_URL}/analytics/dashboard`,
      { headers: getHeaders(token) }
    );
    check(analyticsRes, {
      'analytics loaded': (r) => r.status === 200 || r.status === 404,
    });
    apiLatency.add(analyticsRes.timings.duration);

    sleep(1);
  });

  // Simulate user think time
  sleep(Math.random() * 3 + 1);
}

// Lifecycle hooks
export function setup() {
  console.log(`Load test starting against: ${BASE_URL}`);
  
  // Verify API is reachable
  const healthRes = http.get(`${BASE_URL}/health`);
  if (healthRes.status !== 200) {
    throw new Error(`API is not reachable: ${BASE_URL}`);
  }
  
  return { startTime: new Date().toISOString() };
}

export function teardown(data) {
  console.log(`Load test completed. Started at: ${data.startTime}`);
}
