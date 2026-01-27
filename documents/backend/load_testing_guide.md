# Load Testing Setup for AgriSmart CI

## Installation

### macOS
```bash
brew install k6
```

### Linux
```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update
sudo apt-get install k6
```

### Docker
```bash
docker pull grafana/k6
```

## Running Tests

### Quick smoke test
```bash
k6 run tests/load/scenarios.js --duration 30s --vus 1
```

### Average load test
```bash
k6 run tests/load/scenarios.js
```

### Custom configuration
```bash
# With environment variables
API_URL=https://api.agrismart.ci TEST_EMAIL=test@test.com TEST_PASSWORD=Test123! k6 run tests/load/scenarios.js

# Specific VUs and duration
k6 run --vus 50 --duration 5m tests/load/scenarios.js

# Output to JSON
k6 run --out json=results.json tests/load/scenarios.js

# Output to InfluxDB (for Grafana dashboards)
k6 run --out influxdb=http://localhost:8086/k6 tests/load/scenarios.js
```

## Test Scenarios

### Smoke Test
- **VUs**: 1
- **Duration**: 1 minute
- **Purpose**: Verify system works under minimal load

### Average Load Test
- **VUs**: Ramp up to 50
- **Duration**: ~9 minutes
- **Purpose**: Test normal production load

### Stress Test
- **VUs**: Ramp up to 200
- **Duration**: ~16 minutes
- **Purpose**: Find system breaking point

## Performance Thresholds

| Metric | Target |
|--------|--------|
| Response time (p95) | < 500ms |
| Response time (p99) | < 1500ms |
| Error rate | < 1% |

## Test User Setup

Before running tests, create a test user:

```sql
-- In MySQL/Prisma
INSERT INTO users (id, nom, prenoms, email, telephone, password_hash, role, statut)
VALUES (
  UUID(),
  'Load',
  'Test',
  'loadtest@example.com',
  '+2250700000001',
  '$2b$10$...', -- bcrypt hash of 'LoadTest123!'
  'PRODUCTEUR',
  'ACTIF'
);
```

Or via API:
```bash
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "nom": "Load",
    "prenoms": "Test",
    "email": "loadtest@example.com",
    "telephone": "+2250700000001",
    "password": "LoadTest123!"
  }'
```

## Interpreting Results

### Good Results
```
✓ http_req_duration..............: avg=120ms min=50ms med=100ms max=500ms p(90)=200ms p(95)=300ms
✓ http_req_failed................: 0.00%
✓ errors.........................: 0.00%
```

### Warning Signs
- p95 > 500ms: Consider optimization
- Error rate > 0.5%: Check server logs
- High variation in response times: Possible resource contention

### Action Items
1. **Slow responses**: Check database queries, add indexes, optimize N+1
2. **Timeouts**: Increase connection pool, add caching
3. **Errors under load**: Check memory, increase limits
4. **Consistent slowness**: Consider horizontal scaling

## CI Integration

Add to GitHub Actions:
```yaml
- name: Run Load Tests
  uses: grafana/k6-action@v0.3.0
  with:
    filename: tests/load/scenarios.js
    flags: --vus 10 --duration 1m
  env:
    API_URL: ${{ secrets.STAGING_API_URL }}
    TEST_EMAIL: ${{ secrets.LOAD_TEST_EMAIL }}
    TEST_PASSWORD: ${{ secrets.LOAD_TEST_PASSWORD }}
```
