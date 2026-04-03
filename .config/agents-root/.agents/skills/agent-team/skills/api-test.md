# API Testing

How to test API endpoints locally using `curl`. No additional tools required.

Use this skill to verify API behavior as part of integration testing or after implementing new endpoints.

---

## Basic patterns

```bash
# GET — pretty-print JSON response
curl -s http://localhost:3000/api/users | jq .

# POST with JSON body
curl -s -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice", "email": "alice@example.com"}' | jq .

# PUT
curl -s -X PUT http://localhost:3000/api/users/1 \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice Updated"}' | jq .

# DELETE
curl -s -X DELETE http://localhost:3000/api/users/1 -w "%{http_code}"
```

The `-s` flag suppresses progress output. The `-w "%{http_code}"` flag prints the HTTP status code after the response body.

---

## Checking status codes

```bash
# Print only the status code
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/users

# Print status code and body
curl -s -w "\nStatus: %{http_code}" http://localhost:3000/api/users | jq .

# Assert a specific status code in a script
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/users)
if [ "$STATUS" != "200" ]; then
  echo "Expected 200, got $STATUS"
  exit 1
fi
```

---

## Auth patterns

```bash
# Bearer token
curl -s http://localhost:3000/api/me \
  -H "Authorization: Bearer $TOKEN" | jq .

# API key header
curl -s http://localhost:3000/api/data \
  -H "X-API-Key: $API_KEY" | jq .

# Cookie auth — save cookies to file, then reuse
curl -s -c /tmp/cookies.txt -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"pass"}' | jq .

curl -s -b /tmp/cookies.txt http://localhost:3000/api/me | jq .
```

---

## Chained requests — login then use token

```bash
# Extract token from login response and use it immediately
TOKEN=$(curl -s -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@test.com","password":"pass"}' | jq -r '.token')

echo "Token: $TOKEN"

# Use it
curl -s http://localhost:3000/api/me \
  -H "Authorization: Bearer $TOKEN" | jq .

# Verify a protected route rejects unauthenticated requests
UNAUTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/me)
echo "Unauthenticated status: $UNAUTH_STATUS"  # expect 401
```

---

## Verifying response shape

```bash
# Check a specific field value
curl -s http://localhost:3000/api/users/1 | jq '.email == "alice@example.com"'

# Check field exists and is not null
curl -s http://localhost:3000/api/users/1 | jq '.id != null'

# Check array length
curl -s http://localhost:3000/api/users | jq 'length'

# Extract and compare multiple fields
curl -s http://localhost:3000/api/users/1 | jq '{id, email, name}'
```

---

## Request body from file

For complex bodies or to avoid shell escaping issues:

```bash
cat > /tmp/body.json << 'EOF'
{
  "name": "Alice",
  "email": "alice@example.com",
  "roles": ["admin", "user"]
}
EOF

curl -s -X POST http://localhost:3000/api/users \
  -H "Content-Type: application/json" \
  -d @/tmp/body.json | jq .
```

---

## Common failure modes

**`Connection refused`** — the dev server isn't running, or the port is wrong. Start the server first and confirm the port from the dev server output.

**`curl: (60) SSL certificate problem`** — self-signed certificate in local dev. Add `-k` to skip verification for local testing only. Never use `-k` in CI or against production.

**Empty response body** — the server returned a non-JSON response or a 204. Check the status code with `-w "%{http_code}"` and check the raw response with `-v` (verbose) to see headers and body.

**`jq: parse error`** — the response isn't valid JSON. Print raw first: `curl -s http://localhost:3000/api/endpoint` without `| jq` to see what's actually returned.

**`401 Unauthorized` when auth should pass** — token may be expired or malformed. Print the raw token value with `echo $TOKEN` and verify it's a valid JWT (not empty, not the string "null").

---

## Structured test output format

When reporting API verification results, use this format:

```
Endpoint: POST /api/auth/login
Status: 200 ✅ (expected 200)
Response shape: { token: string, user: { id, email } } ✅
Auth token extracted: yes

Endpoint: GET /api/me (unauthenticated)
Status: 401 ✅ (expected 401)

Endpoint: GET /api/me (authenticated)
Status: 200 ✅ (expected 200)
Response: { id: 1, email: "user@test.com", name: "Test User" } ✅
```
