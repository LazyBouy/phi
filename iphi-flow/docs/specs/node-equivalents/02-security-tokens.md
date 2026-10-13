# 02 — Security tokens (SEC)

Two pieces: "JSON Web Tokens" (sign, verify and decode) and "One-Time Passwords" (time-based codes). They are separate because each needs its own connection type, and Activepieces gives a piece one connection type. Conventions: `00-index.md`. `JWT` = `packages/pieces/custom/json-web-tokens`, `OTP` = `packages/pieces/custom/one-time-passwords`.

## Requirements

### SEC-01 — JSON Web Tokens piece and connection

- **Values:** Display name "JSON Web Tokens"; description "Create, check and read signed JSON Web Tokens"; categories CORE. Connection (custom auth, stored encrypted like every Activepieces connection):

  | Field | Type | Notes |
  |---|---|---|
  | Key type | "Shared secret" / "Key pair" | default Shared secret |
  | Secret | secret text | Shared secret; HMAC algorithms |
  | Private key | secret text (PEM) | Key pair; needed to sign |
  | Public key | text (PEM) | Key pair; needed to verify |
  | Algorithm | HS256, HS384, HS512 for a shared secret; RS256, RS384, RS512, PS256, PS384, PS512, ES256, ES384, ES512 for a key pair | default HS256 or RS256 |

  The connection's validation signs and verifies a sample token, so a wrong key fails when the connection is saved.
- **AP target file(s):** `JWT/src/index.ts`, `JWT/src/lib/auth.ts`, `JWT/package.json`, `tsconfig.base.json`.
- **Notes:** The unsigned algorithm is never offered. The signing library is a well-known, pinned JSON Web Token library declared in the piece's own `package.json`; adding it needs the user's go (plan C4 batch 4).

### SEC-02 — Create Token

- **Values:**

  | Property | Type | Default | Notes |
  |---|---|---|---|
  | Claims | JSON object | `{}` | custom claims |
  | Subject | text | empty | written as `sub` |
  | Audience | text | empty | `aud` |
  | Issuer | text | empty | `iss` |
  | Token ID | text | empty | `jti` |
  | Expires in (seconds) | number | 3600 | sets `exp` = now + value; empty = no expiry |
  | Valid from (seconds from now) | number | empty | sets `nbf`; empty = valid at once |
  | Extra header fields | JSON object | `{}` | merged into the header; `alg` cannot be changed here |
  | Key ID | text | empty | `kid` header |

- **Rules:** The payload is the Claims object plus the standard claims above (standard fields win over the same names in Claims) and `iat` = now. Times are whole seconds since 1970. Uses the connection's algorithm.
- **Output:** `{ token, header, payload, expiresAt }` (`expiresAt` ISO text or null).
- **AP target file(s):** `JWT/src/lib/actions/create-token.ts`.
- **Notes:** The standard claim names are what other systems expect; the action writes them under those names.

### SEC-03 — Verify Token

- **Values:** "Token" (text, required); "Expected audience" (text); "Expected issuer" (text); "Allow expired tokens" (checkbox, off); "Allow tokens not yet valid" (checkbox, off); "Clock tolerance (seconds)" (number, default 0).
- **Rules:** Checks the signature with the connection's key and algorithm (a token signed with another algorithm fails), then the time claims and the expected audience and issuer.
- **Output:** `{ valid: true, header, payload }`.
- **Errors:** each failure stops the step with its own message: "The token's signature does not match this connection's key.", "The token expired at {time}.", "The token is not valid until {time}.", "The token's audience does not match.", "The token's issuer does not match.", "This is not a valid JSON Web Token."
- **AP target file(s):** `JWT/src/lib/actions/verify-token.ts`.
- **Notes:** Users who want a yes/no instead of a stop can turn on the step's continue-on-failure setting.

### SEC-04 — Read Token

- **Values:** "Token" (text, required).
- **Rules:** Reads the header and payload without checking the signature; does not need a connection (`requireAuth: false`). The description says plainly that the result is not verified.
- **Output:** `{ header, payload, expiresAt, isExpired }`.
- **Errors:** "This is not a valid JSON Web Token."
- **AP target file(s):** `JWT/src/lib/actions/read-token.ts`.
- **Notes:** —

### SEC-05 — One-Time Passwords piece and connection

- **Values:** Display name "One-Time Passwords"; description "Generate time-based one-time codes (TOTP)"; categories CORE. Connection: "Secret" (secret text, the base32 secret shown when two-step sign-in is set up; spaces and lower case accepted), validated by decoding it.
- **AP target file(s):** `OTP/src/index.ts`, `OTP/src/lib/auth.ts`, `OTP/package.json`, `tsconfig.base.json`.
- **Notes:** No third-party library: the code is computed with Node's built-in HMAC (RFC 6238).

### SEC-06 — Generate Code

- **Values:** "Algorithm" (SHA-1, SHA-256, SHA-512; default SHA-1); "Digits" (6, 7 or 8; default 6); "Period (seconds)" (number, default 30, at least 1).
- **Rules:** Standard RFC 6238 code for the current time; leading zeros kept (the code is text).
- **Output:** `{ code, secondsRemaining, validUntil }`.
- **Errors:** an invalid secret is caught when the connection is saved; at run time: "The connection's secret is not valid base32."
- **AP target file(s):** `OTP/src/lib/actions/generate-code.ts`, `OTP/src/lib/common/totp.ts`.
- **Notes:** Tests check against the published RFC 6238 test vectors.

### SEC-07 — Place in the piece panel and tests

- **Values:** Both pieces appear in Transform data → "Formats and files" next to Crypto. Unit tests: signing and verifying with every algorithm family (keys generated in the test), every failure message, time claims with a fixed clock, RFC 6238 vectors.
- **AP target file(s):** `WEB/features/pieces/utils/piece-search-utils.ts`, `JWT/test/*.test.ts`, `OTP/test/*.test.ts`.
- **Notes:** —
