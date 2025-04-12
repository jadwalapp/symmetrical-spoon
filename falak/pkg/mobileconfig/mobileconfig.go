package mobileconfig

// CalDAVPayload defines the structure for the CalDAV account payload
// Keys correspond to the com.apple.caldav.account payload type
// See: https://developer.apple.com/documentation/devicemanagement/caldav
type CalDAVPayload struct {
	PayloadVersion           int    `plist:"PayloadVersion"`           // Standard: 1
	PayloadType              string `plist:"PayloadType"`              // Standard: "com.apple.caldav.account"
	PayloadIdentifier        string `plist:"PayloadIdentifier"`        // Unique ID for this payload (e.g., com.yourorg.profile.caldav)
	PayloadUUID              string `plist:"PayloadUUID"`              // Unique UUID for this payload instance
	PayloadDisplayName       string `plist:"PayloadDisplayName"`       // User-visible name (e.g., "Work Calendar")
	CalDAVAccountDescription string `plist:"CalDAVAccountDescription"` // User-visible description
	CalDAVHostName           string `plist:"CalDAVHostName"`           // Server hostname (e.g., cal.example.com)
	CalDAVPort               int    `plist:"CalDAVPort"`               // Server port (e.g., 443)
	CalDAVUseSSL             bool   `plist:"CalDAVUseSSL"`             // Use SSL/TLS (Highly recommended: true)
	CalDAVPrincipalURL       string `plist:"CalDAVPrincipalURL"`       // Principal URL (e.g., /principals/users/youruser/) - VERY IMPORTANT
	CalDAVUsername           string `plist:"CalDAVUsername,omitempty"` // Username (optional, leave empty to prompt user)
	CalDAVPassword           string `plist:"CalDAVPassword,omitempty"` // Password (optional, VERY insecure to include, leave empty)
}

type WebCalPayload struct {
	PayloadVersion         int    `plist:"PayloadVersion"`         // Standard: 1
	PayloadType            string `plist:"PayloadType"`            // Standard: "com.apple.subscribedcalendar.account"
	PayloadIdentifier      string `plist:"PayloadIdentifier"`      // Unique ID for this payload (e.g., com.yourorg.profile.webcal)
	PayloadUUID            string `plist:"PayloadUUID"`            // Unique UUID for this payload instance
	PayloadDisplayName     string `plist:"PayloadDisplayName"`     // User-visible name (e.g., "Work Calendar")
	CalendarURL            string `plist:"CalendarURL"`            // WebCal URL (e.g., webcal://example.com/calendar.ics)
	SubscribeAutomatically bool   `plist:"SubscribeAutomatically"` // Whether to automatically subscribe to the calendar
	RemindersEnabled       bool   `plist:"RemindersEnabled"`       // Password (optional, VERY insecure to include, leave empty)
}

type MobileConfig struct {
	PayloadContent           []interface{} `plist:"PayloadContent"`           // Array of payloads (we'll have one CalDAV payload)
	PayloadDescription       string        `plist:"PayloadDescription"`       // Description of the profile
	PayloadDisplayName       string        `plist:"PayloadDisplayName"`       // Name of the profile
	PayloadIdentifier        string        `plist:"PayloadIdentifier"`        // Unique ID for the whole profile (e.g., com.yourorg.profile)
	PayloadOrganization      string        `plist:"PayloadOrganization"`      // Your organization name
	PayloadRemovalDisallowed bool          `plist:"PayloadRemovalDisallowed"` // Prevent user from removing profile? (default: false)
	PayloadScope             string        `plist:"PayloadScope"`             // "System" or "User" (usually "User")
	PayloadType              string        `plist:"PayloadType"`              // Standard: "Configuration"
	PayloadUUID              string        `plist:"PayloadUUID"`              // Unique UUID for the whole profile instance
	PayloadVersion           int           `plist:"PayloadVersion"`           // Standard: 1
}
