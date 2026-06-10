package websocket

// 电波灵动即时通讯系统 V1.0
// 著作权人：江苏栩熙晨梦网络科技有限公司
// 开发完成日期：2026年5月28日
// 文件说明：WebSocket连接管理中心



import (
	"encoding/json"
	"log"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true // allow all origins for development
	},
}

// ---------------------------------------------------------------------------
// Message defines the wire format for WebSocket frames.
// ---------------------------------------------------------------------------

// WsMessage WebSocket消息帧的线格式定义
type WsMessage struct {
	Type     string `json:"type"`               // "message", "ack", "error"
	FromID   string `json:"from_id,omitempty"`
	ToID     string `json:"to_id,omitempty"`
	Content  string `json:"content,omitempty"`
	Time     string `json:"time,omitempty"`
	MsgID    string `json:"msg_id,omitempty"`
	Error    string `json:"error,omitempty"`
}

// ---------------------------------------------------------------------------
// Client
// ---------------------------------------------------------------------------

// Client WebSocket客户端连接
type Client struct {
	Hub    *Hub
	Conn   *websocket.Conn
	Send   chan []byte
	UserID string
}

// readPump 读取WebSocket消息循环，处理ping和信令转发
func (c *Client) readPump() {
	defer func() {
		c.Hub.unregister <- c
		c.Conn.Close()
	}()

	for {
		_, message, err := c.Conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseNormalClosure) {
log.Printf("WebSocket read error: %v", err)
			}
			break
		}

		var msg WsMessage
		if err := json.Unmarshal(message, &msg); err != nil {
// log.Printf("WebSocket invalid message: %v", err)  // FIXED: removed print statement
			continue
		}

		switch msg.Type {
		case "ping":
			pong, _ := json.Marshal(WsMessage{Type: "pong"})
			select {
			case c.Send <- pong:
			default:
			}
		case "offer", "answer", "ice-candidate":
			// WebRTC signaling relay: forward to target user
			if msg.ToID != "" {
				relay := &WsMessage{
					Type:    msg.Type,
					FromID:  c.UserID,
					ToID:    msg.ToID,
					Content: msg.Content,
				}
				_ = c.Hub.SendToUser(msg.ToID, relay)
			}
		default:
// log.Printf("WebSocket received type=%s from=%s", msg.Type, c.UserID)  // FIXED: removed print statement
		}
	}
}

// writePump 写入WebSocket消息循环
func (c *Client) writePump() {
	defer c.Conn.Close()

	for message := range c.Send {
		if err := c.Conn.WriteMessage(websocket.TextMessage, message); err != nil {
log.Printf("WebSocket write error: %v", err)
			break
		}
	}
}

// ---------------------------------------------------------------------------
// Hub
// ---------------------------------------------------------------------------

// Hub WebSocket连接中心，管理所有客户端连接和消息路由
type Hub struct {
	mu         sync.RWMutex
	clients    map[*Client]bool
	userToConn map[string]*Client // userID → client (single conn per user)
	register   chan *Client
	unregister chan *Client
	broadcast  chan []byte
}

// NewHub 创建新的Hub实例
func NewHub() *Hub {
	return &Hub{
		clients:    make(map[*Client]bool),
		userToConn: make(map[string]*Client),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		broadcast:  make(chan []byte, 256),
	}
}

// Run starts the hub's main event loop in the calling goroutine.
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.mu.Lock()
			h.clients[client] = true
			// Replace any existing connection for the same user
			if existing, ok := h.userToConn[client.UserID]; ok {
				close(existing.Send)
				delete(h.clients, existing)
			}
			h.userToConn[client.UserID] = client
			h.mu.Unlock()
// log.Printf("WebSocket connected: %s (total: %d)", client.UserID, len(h.clients))  // FIXED: removed print statement

		case client := <-h.unregister:
			h.mu.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				if h.userToConn[client.UserID] == client {
					delete(h.userToConn, client.UserID)
				}
				close(client.Send)
// log.Printf("WebSocket disconnected: %s (total: %d)", client.UserID, len(h.clients))  // FIXED: removed print statement
			}
			h.mu.Unlock()

		case message := <-h.broadcast:
			h.mu.RLock()
			for client := range h.clients {
				select {
				case client.Send <- message:
				default:
					// Client's send buffer is full; drop it
				}
			}
			h.mu.RUnlock()
		}
	}
}

// SendToUser sends a JSON message to a specific user's WebSocket connection.
func (h *Hub) SendToUser(userID string, msg *WsMessage) error {
	data, err := json.Marshal(msg)
	if err != nil {
		return err
	}

	h.mu.RLock()
	client, ok := h.userToConn[userID]
	h.mu.RUnlock()

	if !ok {
		return nil // user not connected; message still stored in DB
	}

	select {
	case client.Send <- data:
	default:
// log.Printf("Send buffer full for user %s", userID)  // FIXED: removed print statement
	}
	return nil
}

// SendMessage is a convenience method for sending a chat message via WebSocket.
func (h *Hub) SendMessage(fromID, toID, content, time, msgID string) {
	msg := &WsMessage{
		Type:    "message",
		FromID:  fromID,
		ToID:    toID,
		Content: content,
		Time:    time,
		MsgID:   msgID,
	}
	_ = h.SendToUser(toID, msg)
}

// HandleWebSocket upgrades an HTTP request to WebSocket and registers the client.
func (h *Hub) HandleWebSocket(w http.ResponseWriter, r *http.Request, userID string) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
log.Printf("WebSocket upgrade error: %v", err)
		return
	}

	client := &Client{
		Hub:    h,
		Conn:   conn,
		Send:   make(chan []byte, 256),
		UserID: userID,
	}

	h.register <- client

	go client.writePump()
	go client.readPump()
}
