package main

import (
	"context"
	"fmt"
	"net/http"
	"net/url"
	"strings"

	digestauth "github.com/Snawoot/go-http-digest-auth-client"
	"github.com/emersion/go-ical"
	"github.com/emersion/go-webdav/caldav"
)

func main() {
	baseURL := "https://baikal.jadwal.app/dav.php"
	username := ""
	password := ""

	// Parse and validate the URL
	_, err := url.Parse(baseURL)
	if err != nil {
		fmt.Printf("Invalid URL: %v\n", err)
		return
	}

	// Create HTTP client with digest auth
	httpClient := &http.Client{
		Transport: digestauth.NewDigestTransport(username, password, http.DefaultTransport),
	}

	// Create CalDAV client
	client, err := caldav.NewClient(httpClient, baseURL)
	if err != nil {
		fmt.Printf("Failed to create client: %v\n", err)
		return
	}

	ctx := context.Background()

	// Test connection
	principal, err := client.FindCurrentUserPrincipal(ctx)
	if err != nil {
		fmt.Printf("Auth failed: %v\n", err)
		return
	}

	fmt.Printf("Successfully connected! Principal: %s\n", principal)

	calHomeSet, err := client.FindCalendarHomeSet(ctx, principal)
	if err != nil {
		fmt.Printf("Finding calendar home set failed: %v\n", err)
		return
	}

	cals, err := client.FindCalendars(ctx, calHomeSet)
	if err != nil {
		fmt.Printf("Finding calendars failed: %v\n", err)
		return
	}

	var whatsappCalPath *string
	fmt.Println("\nFound calendars:")
	for i, cal := range cals {
		fmt.Printf("%d. Name: %s\n   Path: %s\n   Description: %s\n\n",
			i+1,
			cal.Name,
			cal.Path,
			cal.Description)

		if strings.HasSuffix(cal.Path, "/whatsapp-by-jadwal/") {
			whatsappCalPath = &cal.Path
		}
	}

	if whatsappCalPath == nil {
		fmt.Printf("No WhatsApp Calendar By Jadwal, We Have To Make One!")

		calObjToCreate := ical.NewCalendar()
		calObjToCreate.Name = "WhatsApp"

		calObject, err := client.PutCalendarObject(ctx, fmt.Sprintf("%s%s", principal, "whatsapp-by-jadwal/"), calObjToCreate)
		if err != nil {
			fmt.Printf("Putting calendar object of whatsapp failed: %v\n", err)
			return
		}

		fmt.Printf("got cal object: %v", calObject)

		whatsappCalPath = &calObject.Path
	}

}
