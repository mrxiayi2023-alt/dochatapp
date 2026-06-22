package model

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：担保交易数据模型

import "time"

// 担保单状态
const (
	EscrowPending         = "pending"
	EscrowActive          = "active"
	EscrowPhaseConfirming = "phase_confirming"
	EscrowCompleted       = "completed"
	EscrowDispute         = "dispute"
	EscrowCancelled       = "cancelled"
)

// 押金方式
const (
	DepositUnilateral = 0 // 单向上押
	DepositBilateral  = 1 // 双向上押
)

// EscrowOrder 担保单
type EscrowOrder struct {
	ID                   string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	ContractNo           string    `gorm:"type:varchar(50);uniqueIndex" json:"contract_no"`
	InitiatorID          string    `gorm:"type:uuid;not null;index" json:"initiator_id"`
	CounterpartyID       string    `gorm:"type:uuid;not null" json:"counterparty_id"`
	CounterpartyName     string    `gorm:"type:varchar(100)" json:"counterparty_name"`
	CounterpartyPhone    string    `gorm:"type:varchar(20)" json:"counterparty_phone"`
	Title                string    `gorm:"type:varchar(200);not null" json:"title"`
	Amount               float64   `gorm:"not null" json:"amount"`
	BreachRate           float64   `gorm:"default:0.05" json:"breach_rate"`
	DepositMode          int       `gorm:"default:0" json:"deposit_mode"`
	DepositPayer         int       `gorm:"default:0" json:"deposit_payer"`
	Installment          bool      `gorm:"default:false" json:"installment"`
	Phase1Percent        int       `gorm:"default:0" json:"phase1_percent"`
	Phase2Percent        int       `gorm:"default:0" json:"phase2_percent"`
	Phase3Percent        int       `gorm:"default:0" json:"phase3_percent"`
	FeePayer             int       `gorm:"default:0" json:"fee_payer"`
	Status               string    `gorm:"type:varchar(20);default:'pending'" json:"status"`
	Terms                string    `gorm:"type:text" json:"terms"`
	DeliveryTime         string    `gorm:"type:varchar(50)" json:"delivery_time"`
	Breach               string    `gorm:"type:text" json:"breach"`
	ArbitrationVerdict   string    `gorm:"type:text" json:"arbitration_verdict"`
	InitiatorDeposit     bool      `gorm:"default:false" json:"initiator_deposit"`
	CounterpartyDeposit  bool      `gorm:"default:false" json:"counterparty_deposit"`
	PendingPhase         int       `gorm:"default:0" json:"pending_phase"`
	CompletedPhases      string    `gorm:"type:text;default:'[]'" json:"completed_phases"`
	CounterpartyRejected bool      `gorm:"default:false" json:"counterparty_rejected"`
	CreatedAt            time.Time `json:"created_at"`
	UpdatedAt            time.Time `json:"updated_at"`
}

// EscrowEvidence 仲裁证据
type EscrowEvidence struct {
	ID         string    `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
	EscrowID   string    `gorm:"type:uuid;not null;index" json:"escrow_id"`
	UploaderID string    `gorm:"type:uuid;not null" json:"uploader_id"`
	FileName   string    `gorm:"type:varchar(200)" json:"file_name"`
	FileURL    string    `gorm:"type:varchar(500)" json:"file_url"`
	Note       string    `gorm:"type:text" json:"note"`
	CreatedAt  time.Time `json:"created_at"`
}

// EscrowListResponse wraps paginated escrow results.
type EscrowListResponse struct {
	Items    []EscrowOrder `json:"items"`
	Total    int64         `json:"total"`
	Page     int           `json:"page"`
	PageSize int           `json:"page_size"`
}
