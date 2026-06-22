package service

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：担保交易业务逻辑

import (
	"errors"

	"dochatapp/server/internal/model"
	"dochatapp/server/internal/repository"

	"gorm.io/gorm"
)

// EscrowService handles escrow business logic.
type EscrowService struct {
	repo *repository.EscrowRepository
}

// NewEscrowService creates a new EscrowService.
func NewEscrowService(repo *repository.EscrowRepository) *EscrowService {
	return &EscrowService{repo: repo}
}

// CreateEscrowRequest is the payload for creating an escrow order.
type CreateEscrowRequest struct {
	CounterpartyID    string  `json:"counterparty_id" binding:"required"`
	CounterpartyName  string  `json:"counterparty_name"`
	CounterpartyPhone string  `json:"counterparty_phone"`
	Title             string  `json:"title" binding:"required"`
	Amount            float64 `json:"amount" binding:"required"`
	BreachRate        float64 `json:"breach_rate"`
	DepositMode       int     `json:"deposit_mode"`
	DepositPayer      int     `json:"deposit_payer"`
	Installment       bool    `json:"installment"`
	Phase1Percent     int     `json:"phase1_percent"`
	Phase2Percent     int     `json:"phase2_percent"`
	Phase3Percent     int     `json:"phase3_percent"`
	FeePayer          int     `json:"fee_payer"`
	Terms             string  `json:"terms"`
	DeliveryTime      string  `json:"delivery_time"`
	Breach            string  `json:"breach"`
}

// Create creates a new escrow order.
func (s *EscrowService) Create(initiatorID string, req *CreateEscrowRequest) (*model.EscrowOrder, error) {
	if req.Amount <= 0 {
		return nil, errors.New("amount must be greater than 0")
	}
	if req.CounterpartyID == initiatorID {
		return nil, errors.New("cannot create escrow with yourself")
	}

	order := &model.EscrowOrder{
		InitiatorID:        initiatorID,
		CounterpartyID:     req.CounterpartyID,
		CounterpartyName:   req.CounterpartyName,
		CounterpartyPhone:  req.CounterpartyPhone,
		Title:              req.Title,
		Amount:             req.Amount,
		BreachRate:         req.BreachRate,
		DepositMode:        req.DepositMode,
		DepositPayer:       req.DepositPayer,
		Installment:        req.Installment,
		Phase1Percent:      req.Phase1Percent,
		Phase2Percent:      req.Phase2Percent,
		Phase3Percent:      req.Phase3Percent,
		FeePayer:           req.FeePayer,
		Status:             model.EscrowPending,
		Terms:              req.Terms,
		DeliveryTime:       req.DeliveryTime,
		Breach:             req.Breach,
		CompletedPhases:    "[]",
	}
	if err := s.repo.Create(order); err != nil {
		return nil, errors.New("failed to create escrow order")
	}
	return order, nil
}

// List returns paginated escrow orders for a user.
func (s *EscrowService) List(userID string, page, pageSize int) (*model.EscrowListResponse, error) {
	items, total, err := s.repo.ListByUser(userID, page, pageSize)
	if err != nil {
		return nil, errors.New("failed to query escrow orders")
	}
	if page < 1 {
		page = 1
	}
	if pageSize < 1 {
		pageSize = 20
	}
	return &model.EscrowListResponse{
		Items:    items,
		Total:    total,
		Page:     page,
		PageSize: pageSize,
	}, nil
}

// Detail returns an escrow order with evidence.
func (s *EscrowService) Detail(id string) (*model.EscrowOrder, []model.EscrowEvidence, error) {
	order, err := s.repo.FindByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, nil, errors.New("escrow order not found")
		}
		return nil, nil, errors.New("database error")
	}
	evidence, _ := s.repo.GetEvidence(id)
	return order, evidence, nil
}

// Accept confirms the escrow order by the counterparty.
func (s *EscrowService) Accept(counterpartyID, id string) error {
	order, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("escrow order not found")
	}
	if order.CounterpartyID != counterpartyID {
		return errors.New("not authorized")
	}
	if order.Status != model.EscrowPending {
		return errors.New("order is not pending")
	}
	if order.CounterpartyRejected {
		return errors.New("order already rejected")
	}
	return s.repo.UpdateStatus(id, model.EscrowActive)
}

// PayDeposit records deposit payment.
func (s *EscrowService) PayDeposit(userID, id string) (*model.EscrowOrder, error) {
	order, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("escrow order not found")
	}

	var initiatorPaid, counterpartyPaid bool
	if userID == order.InitiatorID {
		initiatorPaid = true
		counterpartyPaid = order.CounterpartyDeposit
	} else if userID == order.CounterpartyID {
		counterpartyPaid = true
		initiatorPaid = order.InitiatorDeposit
	} else {
		return nil, errors.New("not a participant")
	}

	if err := s.repo.UpdateDeposit(id, initiatorPaid, counterpartyPaid); err != nil {
		return nil, errors.New("failed to update deposit")
	}

	// If installment mode, set pending phase 1
	if order.Installment && order.PendingPhase == 0 {
		_ = s.repo.UpdatePendingPhase(id, 1)
		_ = s.repo.UpdateStatus(id, model.EscrowPhaseConfirming)
	}

	order.InitiatorDeposit = initiatorPaid
	order.CounterpartyDeposit = counterpartyPaid
	return order, nil
}

// ConfirmPhase confirms a completed phase.
func (s *EscrowService) ConfirmPhase(initiatorID, id string, phase int) error {
	order, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("escrow order not found")
	}
	if order.InitiatorID != initiatorID {
		return errors.New("not authorized")
	}
	if order.PendingPhase != phase {
		return errors.New("invalid phase to confirm")
	}

	if err := s.repo.AddCompletedPhase(id, phase); err != nil {
		return errors.New("failed to update phase")
	}

	// Determine next phase
	totalPhases := 0
	if order.Phase3Percent > 0 {
		totalPhases = 3
	} else if order.Phase2Percent > 0 {
		totalPhases = 2
	} else {
		totalPhases = 1
	}

	if phase >= totalPhases {
		_ = s.repo.UpdateStatus(id, model.EscrowCompleted)
		_ = s.repo.UpdatePendingPhase(id, 0)
	} else {
		_ = s.repo.UpdatePendingPhase(id, phase+1)
	}

	return nil
}

// RejectPhase rejects a phase (triggers dispute).
func (s *EscrowService) RejectPhase(counterpartyID, id string) error {
	order, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("escrow order not found")
	}
	if order.CounterpartyID != counterpartyID {
		return errors.New("not authorized")
	}

	_ = s.repo.SetCounterpartyRejected(id)
	return s.repo.UpdateStatus(id, model.EscrowDispute)
}

// SubmitDispute submits a dispute for an escrow order.
func (s *EscrowService) SubmitDispute(userID, id, note string) error {
	order, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("escrow order not found")
	}
	if order.InitiatorID != userID && order.CounterpartyID != userID {
		return errors.New("not a participant")
	}

	// Automatically add a note as evidence
	if note != "" {
		_ = s.repo.AddEvidence(&model.EscrowEvidence{
			EscrowID:   id,
			UploaderID: userID,
			FileName:   "dispute_note",
			FileURL:    "",
			Note:       note,
		})
	}

	return s.repo.UpdateStatus(id, model.EscrowDispute)
}

// AddEvidence adds evidence to an escrow order.
func (s *EscrowService) AddEvidence(userID, id, fileName, fileURL, note string) (*model.EscrowEvidence, error) {
	order, err := s.repo.FindByID(id)
	if err != nil {
		return nil, errors.New("escrow order not found")
	}
	if order.InitiatorID != userID && order.CounterpartyID != userID {
		return nil, errors.New("not a participant")
	}

	evidence := &model.EscrowEvidence{
		EscrowID:   id,
		UploaderID: userID,
		FileName:   fileName,
		FileURL:    fileURL,
		Note:       note,
	}
	if err := s.repo.AddEvidence(evidence); err != nil {
		return nil, errors.New("failed to add evidence")
	}
	return evidence, nil
}

// ResolveArbitration sets the arbitration verdict.
func (s *EscrowService) ResolveArbitration(id, verdict string) error {
	order, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("escrow order not found")
	}
	if order.Status != model.EscrowDispute {
		return errors.New("order is not in dispute")
	}
	return s.repo.UpdateArbitration(id, verdict)
}

// Complete marks an escrow order as completed.
func (s *EscrowService) Complete(id string) error {
	order, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("escrow order not found")
	}
	if order.Status != model.EscrowActive {
		return errors.New("order is not active")
	}
	return s.repo.UpdateStatus(id, model.EscrowCompleted)
}

// Cancel cancels an escrow order.
func (s *EscrowService) Cancel(userID, id string) error {
	order, err := s.repo.FindByID(id)
	if err != nil {
		return errors.New("escrow order not found")
	}
	if order.InitiatorID != userID {
		return errors.New("not authorized")
	}
	if order.Status != model.EscrowPending {
		return errors.New("only pending orders can be cancelled")
	}
	return s.repo.UpdateStatus(id, model.EscrowCancelled)
}
