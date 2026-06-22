package im

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"time"
)

// UserSigConfig holds Tencent IM configuration for signature generation.
type UserSigConfig struct {
	SDKAppID int64
	Secret   string
}

// genUserSig generates a userSig for Tencent IM login.
// Uses TLS v2 scheme: JSON payload -> base64 -> HMAC-SHA256 -> base64 -> concatenate.
func genUserSig(cfg *UserSigConfig, userID string) (string, error) {
	expire := int64(15552000) // 180 days in seconds
	curr := time.Now().Unix()

	// Build the JSON payload per Tencent IM TLS v2 spec
	payload := map[string]interface{}{
		"TLS.appid_at_3rd": fmt.Sprintf("%d", cfg.SDKAppID),
		"TLS.expire_after": fmt.Sprintf("%d", expire),
		"TLS.identifier":   userID,
		"TLS.sdk_appid":    cfg.SDKAppID,
		"TLS.time":         curr,
		"TLS.version":      "2",
	}

	b, err := json.Marshal(payload)
	if err != nil {
		return "", fmt.Errorf("failed to marshal payload: %w", err)
	}

	// Base64 encode the JSON (raw = no padding)
	base64Payload := base64.RawURLEncoding.EncodeToString(b)

	// HMAC-SHA256 sign the base64 string with the secret key
	mac := hmac.New(sha256.New, []byte(cfg.Secret))
	mac.Write([]byte(base64Payload))
	sig := mac.Sum(nil)

	// Base64 encode the signature
	base64Sig := base64.RawURLEncoding.EncodeToString(sig)

	// Final userSig: base64_payload.base64_signature
	return base64Payload + "." + base64Sig, nil
}

// GenerateUserSig is the public wrapper for genUserSig.
func GenerateUserSig(cfg *UserSigConfig, userID string) (string, error) {
	return genUserSig(cfg, userID)
}
