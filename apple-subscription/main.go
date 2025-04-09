package main

import (
	"fmt"
	"net/http"

	"github.com/google/uuid"
)

func main() {
	http.HandleFunc("/profile", mobileConfigHandler)

	// Optional: Serve the ICS file too if you're hosting it locally
	http.Handle("/prayer-calendar.ics", http.FileServer(http.Dir(".")))

	fmt.Println("Server started at http://localhost:8080")
	http.ListenAndServe("0.0.0.0:8080", nil)
}

func mobileConfigHandler(w http.ResponseWriter, r *http.Request) {
	// Your provided webcal URL
	domain := "prayerwebcal.dsultan.com" // Domain part of the webcal URL

	// Generate UUIDs for unique payload and profile identifiers
	payloadUUID := uuid.New().String()
	profileUUID := uuid.New().String()

	// Create the mobileconfig XML profile using the provided webcal URL
	profile := fmt.Sprintf(`<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
"http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>PayloadContent</key>
	<array>
		<dict>
			<key>PayloadDescription</key>
			<string>Prayer Calendar Subscription</string>
			<key>PayloadDisplayName</key>
			<string>Prayer Calendar</string>
			<key>PayloadIdentifier</key>
			<string>com.prayercalendar</string>
			<key>PayloadOrganization</key>
			<string>Prayer Times App</string>
			<key>PayloadType</key>
			<string>com.apple.subscribedcalendar.account</string>
			<key>PayloadUUID</key>
			<string>4a5b8c00-12d3-4567-b890-1ac62f8b46ea</string>
			<key>PayloadVersion</key>
			<integer>1</integer>
			<key>SubCalAccountDescription</key>
			<string>Prayer Times for Riyadh</string>
			<key>SubCalAccountHostName</key>
			<string>webcal://prayerwebcal.dsultan.com/ics/Riyadh_Saudi_Arabia/tz=Asia%2FRiyadh:x=24.65:y=46.72</string>
			<key>SubCalAccountUseSSL</key>
			<true/>
			<key>SubCalAccountUsername</key>
			<string></string>
			<key>SubCalAccountPassword</key>
			<string></string>
		</dict>
	</array>
	<key>PayloadDescription</key>
	<string>Install calendar subscription for prayer times.</string>
	<key>PayloadDisplayName</key>
	<string>Prayer Calendar Profile</string>
	<key>PayloadIdentifier</key>
	<string>com.prayercalendar.profile</string>
	<key>PayloadOrganization</key>
	<string>Prayer Times App</string>
	<key>PayloadType</key>
	<string>Configuration</string>
	<key>PayloadUUID</key>
	<string>cfd456a1-5d32-4679-9ac3-bfe1234e7d82</string>
	<key>PayloadVersion</key>
	<integer>1</integer>
</dict>
</plist>
`, payloadUUID, domain, profileUUID)

	// Serve the generated profile as a downloadable file
	w.Header().Set("Content-Type", "application/x-apple-aspen-config")
	w.Header().Set("Content-Disposition", "attachment; filename=prayer-profile.mobileconfig")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(profile))
}
