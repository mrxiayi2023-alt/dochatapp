package repository

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：担保交易数据库操作

import (
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	"dochatapp/server/internal/model"

	"gorm.io/gorm"
)

// EscrowRepository handles database operations for escrow orders.
type EscrowRepository struct {
	db *gorm.DB
}

// NewEscrowRepository creates a new EscrowRepository.
func NewEscrowRepository(db *gorm.DB) *EscrowRepository {
	return &EscrowRepository{db: db}
}

// Create inserts a new escrow order.
func (r *EscrowRepository) Create(order *model.EscrowOrder) error {
	order.ContractNo = fmt.Sprintf("ES%d", time.Now().UnixNano())
	return r.db.Create(order).Error
}

// FindByID retrieves an escrow order by ID.
func (r *EscrowRepository) FindByID(id string) (*model.EscrowOrder, error) {
	var order model.EscrowOrder
	err := r.db.Where("id = ?", id).First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

// ListByUser returns paginated escrow orders for a user.
func (r *EscrowRepository) ListByUser(userID string, page, pageSize int) ([]model.EscrowOrder, int64, error) {
	query := r.db.Model(&model.EscrowOrder{}).
		Where("initiator_id = ? OR counterparty_id = ?", userID, userID)

	var total int64
	if err := query.Count(&total).Error; err != nil {
		return nil, 0, err
	}

	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	offset := (page - 1) * pageSize

	var orders []model.EscrowOrder
	err := query.Order("created_at DESC").Offset(offset).Limit(pageSize).Find(&orders).Error
	return orders, total, err
}

// UpdateStatus updates the status of an escrow order.
func (r *EscrowRepository) UpdateStatus(id, status string) error {
	return r.db.Model(&model.EscrowOrder{}).Where("id = ?", id).Update("status", status).Error
}

// UpdateDeposit updates deposit paid flags.
func (r *EscrowRepository) UpdateDeposit(id string, initiatorPaid, counterpartyPaid bool) error {
	return r.db.Model(&model.EscrowOrder{}).Where("id = ?", id).Updates(map[string]interface{}{
		"initiator_deposit":    initiatorPaid,
		"counterparty_deposit": counterpartyPaid,
	}).Error
}

// UpdatePendingPhase sets the pending phase number.
func (r *EscrowRepository) UpdatePendingPhase(id string, phase int) error {
	return r.db.Model(&model.EscrowOrder{}).Where("id = ?", id).Update("pending_phase", phase).Error
}

// AddCompletedPhase appends a phase number to the completed phases list.
func (r *EscrowRepository) AddCompletedPhase(id string, phase int) error {
	var order model.EscrowOrder
	if err := r.db.Where("id = ?", id).First(&order).Error; err != nil {
		return err
	}

	var phases []int
	if order.CompletedPhases != "" && order.CompletedPhases != "[]" {
		if err := json.Unmarshal([]byte(order.CompletedPhases), &phases); err != nil {
			phases = []int{}
		}
	}
	phases = append(phases, phase)
	data, _ := json.Marshal(phases)
	return r.db.Model(&model.EscrowOrder{}).Where("id = ?", id).Update("completed_phases", string(data)).Error
}

// SetCounterpartyRejected marks the order as rejected by counterparty.
func (r *EscrowRepository) SetCounterpartyRejected(id string) error {
	return r.db.Model(&model.EscrowOrder{}).Where("id = ?", id).Update("counterparty_rejected", true).Error
}

// UpdateArbitration sets the arbitration verdict.
func (r *EscrowRepository) UpdateArbitration(id, verdict string) error {
	return r.db.Model(&model.EscrowOrder{}).Where("id = ?", id).Updates(map[string]interface{}{
		"arbitration_verdict": verdict,
		"status":              model.EscrowCompleted,
	}).Error
}

// Update performs a full save of the escrow order.
func (r *EscrowRepository) Update(order *model.EscrowOrder) error {
	return r.db.Save(order).Error
}

// AddEvidence inserts a new evidence record.
func (r *EscrowRepository) AddEvidence(evidence *model.EscrowEvidence) error {
	return r.db.Create(evidence).Error
}

// GetEvidence returns all evidence for an escrow order.
func (r *EscrowRepository) GetEvidence(escrowID string) ([]model.EscrowEvidence, error) {
	var evidence []model.EscrowEvidence
	err := r.db.Where("escrow_id = ?", escrowID).Order("created_at DESC").Find(&evidence).Error
	return evidence, err
}

// strconv is used indirectly; keep import for potential future use
var _ = strconv.Itoa
