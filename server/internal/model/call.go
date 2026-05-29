package model

import "time"

// Call statuses
const (
	CallStatusRinging  = "ringing"
	CallStatusAccepted = "accepted"
	CallStatusRejected = "rejected"
	CallStatusEnded    = "ended"
)

// CallType values
const (
	CallTypeAudio = "audio"
	CallTypeVideo = "video"
)

// Call represents a 1v1 audio/video call.
type Call struct {
	ID        string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	CallerID  string    `gorm:"type:uuid;not null;index" json:"caller_id"`
	CalleeID  string    `gorm:"type:uuid;not null;index" json:"callee_id"`
	CallType  string    `gorm:"type:varchar(10);not null" json:"call_type"`
	Status    string    `gorm:"type:varchar(20);not null;default:ringing" json:"status"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
