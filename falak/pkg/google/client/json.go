package client

import "encoding/json"

func (t *TokenInfoResponse) UnmarshalJSON(data []byte) error {
	type Alias TokenInfoResponse
	aux := &struct {
		EmailVerified string `json:"email_verified"`
		*Alias
	}{
		Alias: (*Alias)(t),
	}

	if err := json.Unmarshal(data, &aux); err != nil {
		return err
	}

	t.EmailVerified = aux.EmailVerified == "true"
	return nil
}
