package whatsappsvc

type WhatsAppMessage struct {
	From    string `json:"from"`
	Message string `json:"message"`
}
