package main

import (
	"bufio"
	"context"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"strings"
	"syscall"
	"time"

	digestauth "github.com/Snawoot/go-http-digest-auth-client"
	"github.com/emersion/go-webdav/caldav"
	"github.com/fatih/color"
	caldavclient "github.com/jadwalapp/symmetrical-spoon/falak/pkg/caldav/client"
	"golang.org/x/term"
)

// ASCII art title
const asciiTitle = `
   ____      _ ____    _    __     __
  / ___|__ _| |  _ \  / \   \ \   / /
 | |   / _' | | | | |/ _ \   \ \ / / 
 | |__| (_| | | |_| / ___ \   \ V /  
  \____\__,_|_|____/_/   \_\   \_/   
                                     
`

// ANSI color setup
var (
	titleColor   = color.New(color.FgHiCyan, color.Bold)
	headerColor  = color.New(color.FgHiBlue, color.Bold)
	successColor = color.New(color.FgHiGreen, color.Bold)
	errorColor   = color.New(color.FgHiRed)
	warnColor    = color.New(color.FgHiYellow)
	promptColor  = color.New(color.FgHiMagenta, color.Bold)
	fieldColor   = color.New(color.FgHiWhite)
	infoColor    = color.New(color.FgCyan)
	menuColor    = color.New(color.FgHiGreen, color.Bold)
	numberColor  = color.New(color.FgYellow, color.Bold)
)

type CalendarApp struct {
	username     string
	password     string
	baseURL      string
	client       caldavclient.Client
	rawClient    *caldav.Client
	httpClient   *http.Client
	selectedCal  string
	currentPath  string
	calendarHome string
	calendarList map[string]string // Map of display names to paths
}

func NewCalendarApp() *CalendarApp {
	return &CalendarApp{
		baseURL:      "https://baikal.jadwal.app/dav.php",
		calendarList: make(map[string]string),
	}
}

func (app *CalendarApp) Initialize() error {
	// Get credentials
	err := app.getCredentials()
	if err != nil {
		return err
	}

	// Create HTTP client with digest auth
	app.httpClient = &http.Client{
		Transport: digestauth.NewDigestTransport(app.username, app.password, http.DefaultTransport),
	}

	// Create raw CalDAV client (for calendar discovery)
	rawClient, err := caldav.NewClient(app.httpClient, app.baseURL)
	if err != nil {
		return fmt.Errorf("failed to create raw CalDAV client: %w", err)
	}
	app.rawClient = rawClient

	// Create wrapped client for events
	client, err := caldavclient.NewCalDAVClient(caldavclient.Config{
		BaseURL:  app.baseURL,
		Username: app.username,
		Password: app.password,
	})
	if err != nil {
		return fmt.Errorf("failed to create CalDAV client: %w", err)
	}
	app.client = client

	// Find calendar home
	ctx := context.Background()
	principal, err := app.rawClient.FindCurrentUserPrincipal(ctx)
	if err != nil {
		return fmt.Errorf("authentication failed: %w", err)
	}

	calendarHome, err := app.rawClient.FindCalendarHomeSet(ctx, principal)
	if err != nil {
		return fmt.Errorf("finding calendar home set failed: %w", err)
	}
	app.calendarHome = calendarHome

	// Discover calendars
	err = app.RefreshCalendarList()
	if err != nil {
		infoColor.Printf("Calendar discovery: %v\n", err)
		infoColor.Println("You may need to create a calendar first.")
	}

	return nil
}

func (app *CalendarApp) RefreshCalendarList() error {
	ctx := context.Background()

	// Find all calendars
	calendars, err := app.rawClient.FindCalendars(ctx, app.calendarHome)
	if err != nil {
		return fmt.Errorf("finding calendars failed: %w", err)
	}

	// Reset and repopulate calendar list
	app.calendarList = make(map[string]string)
	for _, cal := range calendars {
		name := cal.Name
		if name == "" {
			// Try to get a name from the path
			parts := strings.Split(cal.Path, "/")
			if len(parts) > 1 {
				name = parts[len(parts)-2] // Second to last part is usually the calendar name
			} else {
				name = cal.Path // Fallback
			}
		}
		app.calendarList[name] = cal.Path
	}

	return nil
}

func (app *CalendarApp) getCredentials() error {
	// Try to get from environment variables first
	app.username = os.Getenv("USER_NAME")
	app.password = os.Getenv("PASSWORD")

	// If either is missing, prompt the user
	reader := bufio.NewReader(os.Stdin)

	if app.username == "" {
		promptColor.Print("Username: ")
		username, err := reader.ReadString('\n')
		if err != nil {
			return fmt.Errorf("error reading username: %w", err)
		}
		app.username = strings.TrimSpace(username)
	} else {
		infoColor.Printf("Using username from environment: %s\n", app.username)
	}

	if app.password == "" {
		promptColor.Print("Password: ")
		bytePassword, err := term.ReadPassword(int(syscall.Stdin))
		if err != nil {
			return fmt.Errorf("error reading password: %w", err)
		}
		fmt.Println() // Add a newline after password input
		app.password = string(bytePassword)
	} else {
		infoColor.Println("Using password from environment")
	}

	// Ask for server URL or use default
	promptColor.Printf("Server URL [%s]: ", app.baseURL)
	serverURL, err := reader.ReadString('\n')
	if err != nil {
		return fmt.Errorf("error reading server URL: %w", err)
	}
	serverURL = strings.TrimSpace(serverURL)
	if serverURL != "" {
		app.baseURL = serverURL
	}

	return nil
}

func (app *CalendarApp) mainMenu() {
	for {
		clearScreen()
		titleColor.Println(asciiTitle)
		headerColor.Printf("🌐 Connected to: %s as %s\n\n", app.baseURL, app.username)

		if app.selectedCal != "" {
			infoColor.Printf("📆 Selected Calendar: %s\n\n", app.selectedCal)
		}

		menuColor.Println("===== MAIN MENU =====")
		fmt.Println("1. 📋 List Calendars")
		fmt.Println("2. 🔍 Select Calendar")
		fmt.Println("3. ➕ Create Calendar")
		fmt.Println("4. 📝 Event Management")
		fmt.Println("0. 🚪 Exit")

		promptColor.Print("\nEnter your choice: ")
		var choice string
		fmt.Scanln(&choice)

		switch choice {
		case "1":
			app.listCalendars()
		case "2":
			app.selectCalendar()
		case "3":
			app.createCalendar()
		case "4":
			if app.selectedCal == "" {
				warnColor.Println("\n⚠️ Please select a calendar first!")
				waitForEnter()
			} else {
				app.eventMenu()
			}
		case "0":
			successColor.Println("\nThank you for using CalDAV Terminal! Goodbye! 👋")
			return
		default:
			errorColor.Println("\n❌ Invalid choice. Please try again.")
			waitForEnter()
		}
	}
}

func (app *CalendarApp) listCalendars() {
	clearScreen()
	headerColor.Println("===== CALENDARS =====")

	// Refresh calendar list to get latest changes
	err := app.RefreshCalendarList()
	if err != nil {
		errorColor.Printf("Error retrieving calendars: %v\n", err)
		waitForEnter()
		return
	}

	if len(app.calendarList) == 0 {
		warnColor.Println("No calendars found. You may need to create one.")
		waitForEnter()
		return
	}

	fmt.Printf("\n📁 Found %d calendars:\n\n", len(app.calendarList))
	i := 1

	// Convert map to sorted array for consistent display
	type CalEntry struct {
		Name string
		Path string
	}

	entries := make([]CalEntry, 0, len(app.calendarList))
	for name, path := range app.calendarList {
		entries = append(entries, CalEntry{Name: name, Path: path})
	}

	// Sort by name
	// (skipping actual sort implementation for brevity, display unsorted)

	for _, entry := range entries {
		nameColor := fieldColor
		if app.selectedCal == entry.Name {
			nameColor = successColor
		}

		numberColor.Printf("%d. ", i)
		nameColor.Printf("%s\n", entry.Name)
		infoColor.Printf("   Path: %s\n", entry.Path)

		// Attempt to count events by selecting the calendar and querying
		calProps := caldavclient.CalendarProperties{
			PathSuffix: strings.TrimPrefix(entry.Path, app.calendarHome),
		}

		// Just use a fresh context for each operation
		ctx := context.Background()
		tempClient, _ := caldavclient.NewCalDAVClient(caldavclient.Config{
			BaseURL:  app.baseURL,
			Username: app.username,
			Password: app.password,
		})

		err := tempClient.InitCalendar(ctx, calProps)
		if err != nil {
			infoColor.Printf("   Events: Unable to count\n")
		} else {
			events, err := tempClient.FindEvents(ctx, caldavclient.EventQuery{})
			if err != nil {
				infoColor.Printf("   Events: Unable to count\n")
			} else {
				infoColor.Printf("   Events: %d\n", len(events))
			}
		}

		fmt.Println()
		i++
	}

	waitForEnter()
}

func (app *CalendarApp) selectCalendar() {
	clearScreen()
	headerColor.Println("===== SELECT CALENDAR =====")

	// Refresh calendar list
	err := app.RefreshCalendarList()
	if err != nil {
		errorColor.Printf("Error retrieving calendars: %v\n", err)
		waitForEnter()
		return
	}

	if len(app.calendarList) == 0 {
		warnColor.Println("No calendars found. You may need to create one.")
		waitForEnter()
		return
	}

	// Convert map to array for numbered selection
	names := make([]string, 0, len(app.calendarList))
	i := 1

	fmt.Println("\nAvailable calendars:")
	for name := range app.calendarList {
		names = append(names, name)
		numberColor.Printf("%d. ", i)
		fieldColor.Printf("%s\n", name)
		i++
	}

	promptColor.Print("\nEnter calendar number (or 0 to cancel): ")
	var choice int
	fmt.Scanln(&choice)

	if choice == 0 {
		return
	}

	if choice < 1 || choice > len(names) {
		errorColor.Println("Invalid selection.")
		waitForEnter()
		return
	}

	selectedName := names[choice-1]
	selectedPath := app.calendarList[selectedName]

	// Initialize the selected calendar
	pathSuffix := strings.TrimPrefix(selectedPath, app.calendarHome)
	calProps := caldavclient.CalendarProperties{
		PathSuffix: pathSuffix,
	}

	ctx := context.Background()
	err = app.client.InitCalendar(ctx, calProps)
	if err != nil {
		errorColor.Printf("Error initializing calendar: %v\n", err)
		waitForEnter()
		return
	}

	app.selectedCal = selectedName
	app.currentPath = selectedPath

	successColor.Printf("\n✅ Selected calendar: %s\n", selectedName)
	waitForEnter()
}

func (app *CalendarApp) createCalendar() {
	clearScreen()
	headerColor.Println("===== CREATE CALENDAR =====")

	reader := bufio.NewReader(os.Stdin)

	// Get calendar path suffix
	promptColor.Print("Calendar Path (e.g. 'work-calendar'): ")
	pathSuffix, _ := reader.ReadString('\n')
	pathSuffix = strings.TrimSpace(pathSuffix)

	if pathSuffix == "" {
		errorColor.Println("Calendar path cannot be empty.")
		waitForEnter()
		return
	}

	// Ensure it ends with a slash
	if !strings.HasSuffix(pathSuffix, "/") {
		pathSuffix += "/"
	}

	// Get display name
	promptColor.Print("Display Name: ")
	displayName, _ := reader.ReadString('\n')
	displayName = strings.TrimSpace(displayName)

	if displayName == "" {
		displayName = pathSuffix[:len(pathSuffix)-1] // Remove trailing slash
	}

	// Get color
	promptColor.Print("Color (hex code like #3498DB): ")
	colorCode, _ := reader.ReadString('\n')
	colorCode = strings.TrimSpace(colorCode)

	if colorCode == "" {
		colorCode = "#3498DB" // Default blue
	}

	// Create the calendar
	calProps := caldavclient.CalendarProperties{
		PathSuffix:  pathSuffix,
		DisplayName: displayName,
		Color:       colorCode,
	}

	ctx := context.Background()
	err := app.client.InitCalendar(ctx, calProps)
	if err != nil {
		errorColor.Printf("Error creating calendar: %v\n", err)
		waitForEnter()
		return
	}

	// Select the newly created calendar
	app.selectedCal = displayName
	app.currentPath = app.client.GetCalendarPath()

	// Refresh calendar list
	app.RefreshCalendarList()

	successColor.Printf("\n✅ Successfully created calendar: %s\n", displayName)
	waitForEnter()
}

func (app *CalendarApp) eventMenu() {
	for {
		clearScreen()
		headerColor.Printf("===== EVENT MANAGEMENT: %s =====\n", app.selectedCal)

		menuColor.Println("\n===== EVENTS MENU =====")
		fmt.Println("1. ➕ Add Event")
		fmt.Println("2. 📋 List Events")
		fmt.Println("3. 🔍 Search Events")
		fmt.Println("0. 🔙 Back to Main Menu")

		promptColor.Print("\nEnter your choice: ")
		var choice string
		fmt.Scanln(&choice)

		switch choice {
		case "1":
			app.addEvent()
		case "2":
			app.listEvents()
		case "3":
			app.searchEvents()
		case "0":
			return
		default:
			errorColor.Println("\n❌ Invalid choice. Please try again.")
			waitForEnter()
		}
	}
}

func (app *CalendarApp) addEvent() {
	clearScreen()
	headerColor.Printf("===== ADD EVENT TO %s =====\n", app.selectedCal)

	reader := bufio.NewReader(os.Stdin)

	// Get event details
	promptColor.Print("Summary/Title: ")
	summary, _ := reader.ReadString('\n')
	summary = strings.TrimSpace(summary)

	promptColor.Print("Description: ")
	description, _ := reader.ReadString('\n')
	description = strings.TrimSpace(description)

	// Parse start time
	startTime := time.Now()
	promptColor.Printf("Start Time [%s] (YYYY-MM-DD HH:MM): ", startTime.Format("2006-01-02 15:04"))
	startTimeStr, _ := reader.ReadString('\n')
	startTimeStr = strings.TrimSpace(startTimeStr)

	if startTimeStr != "" {
		parsedTime, err := time.Parse("2006-01-02 15:04", startTimeStr)
		if err == nil {
			startTime = parsedTime
		} else {
			errorColor.Printf("Invalid time format. Using current time: %s\n", startTime.Format("2006-01-02 15:04"))
		}
	}

	// Get duration in minutes
	var durationMinutes int = 60
	promptColor.Print("Duration in minutes [60]: ")
	durationStr, _ := reader.ReadString('\n')
	durationStr = strings.TrimSpace(durationStr)

	if durationStr != "" {
		duration, err := strconv.Atoi(durationStr)
		if err == nil && duration > 0 {
			durationMinutes = duration
		} else {
			errorColor.Printf("Invalid duration. Using default: %d minutes\n", durationMinutes)
		}
	}

	// Generate UID
	eventUID := fmt.Sprintf("event-%s@jadwal.app", time.Now().Format("20060102150405"))

	// Create the event
	event := caldavclient.EventData{
		Summary:     summary,
		Description: description,
		StartTime:   startTime,
		EndTime:     startTime.Add(time.Duration(durationMinutes) * time.Minute),
		UID:         eventUID,
	}

	// Add the event
	ctx := context.Background()
	err := app.client.AddEvent(ctx, event)
	if err != nil {
		errorColor.Printf("Failed to add event: %v\n", err)
		waitForEnter()
		return
	}

	successColor.Println("\n✅ Event added successfully!")
	infoColor.Println("Event details:")
	infoColor.Printf("- Title: %s\n", summary)
	infoColor.Printf("- Start: %s\n", startTime.Format(time.RFC3339))
	infoColor.Printf("- End: %s\n", startTime.Add(time.Duration(durationMinutes)*time.Minute).Format(time.RFC3339))
	infoColor.Printf("- UID: %s\n", eventUID)

	infoColor.Println("\nTo view this event in your calendar app:")
	infoColor.Printf("1. URL: %s/calendars/%s/%s\n", app.baseURL, app.username, app.currentPath)
	infoColor.Println("2. For Apple Calendar: ⌘+R to refresh")

	waitForEnter()
}

func (app *CalendarApp) listEvents() {
	clearScreen()
	headerColor.Printf("===== EVENTS IN %s =====\n", app.selectedCal)

	// Create a query to find all events
	query := caldavclient.EventQuery{}

	// Find events
	ctx := context.Background()
	events, err := app.client.FindEvents(ctx, query)
	if err != nil {
		errorColor.Printf("Failed to find events: %v\n", err)
		waitForEnter()
		return
	}

	if len(events) == 0 {
		warnColor.Println("📭 No events found in this calendar.")
		waitForEnter()
		return
	}

	fmt.Printf("\n📆 Found %d events:\n\n", len(events))

	for i, event := range events {
		numberColor.Printf("%d. ", i+1)
		fieldColor.Printf("%s\n", event.Summary)
		infoColor.Printf("   Description: %s\n", event.Description)
		infoColor.Printf("   Start: %s\n", event.StartTime.Format(time.RFC3339))
		infoColor.Printf("   End: %s\n", event.EndTime.Format(time.RFC3339))
		infoColor.Printf("   UID: %s\n", event.UID)
		fmt.Println()
	}

	waitForEnter()
}

func (app *CalendarApp) searchEvents() {
	clearScreen()
	headerColor.Printf("===== SEARCH EVENTS IN %s =====\n", app.selectedCal)

	reader := bufio.NewReader(os.Stdin)

	// Get search term (UID pattern)
	promptColor.Print("Search term (will match event UIDs or summaries): ")
	searchTerm, _ := reader.ReadString('\n')
	searchTerm = strings.TrimSpace(searchTerm)

	if searchTerm == "" {
		warnColor.Println("Search term cannot be empty.")
		waitForEnter()
		return
	}

	// Create query
	query := caldavclient.EventQuery{
		UIDPattern: searchTerm,
	}

	// Search events
	ctx := context.Background()
	events, err := app.client.FindEvents(ctx, query)
	if err != nil {
		errorColor.Printf("Failed to search events: %v\n", err)
		waitForEnter()
		return
	}

	// Also search by summary (not directly supported by API, so we do it client-side)
	allEvents, err := app.client.FindEvents(ctx, caldavclient.EventQuery{})
	if err == nil {
		for _, event := range allEvents {
			// If we haven't already found this event by UID and its summary matches
			if strings.Contains(strings.ToLower(event.Summary), strings.ToLower(searchTerm)) {
				found := false
				for _, e := range events {
					if e.UID == event.UID {
						found = true
						break
					}
				}
				if !found {
					events = append(events, event)
				}
			}
		}
	}

	if len(events) == 0 {
		warnColor.Printf("📭 No events found matching '%s'\n", searchTerm)
		waitForEnter()
		return
	}

	fmt.Printf("\n🔍 Found %d matching events:\n\n", len(events))

	for i, event := range events {
		numberColor.Printf("%d. ", i+1)
		fieldColor.Printf("%s\n", event.Summary)
		infoColor.Printf("   Description: %s\n", event.Description)
		infoColor.Printf("   Start: %s\n", event.StartTime.Format(time.RFC3339))
		infoColor.Printf("   End: %s\n", event.EndTime.Format(time.RFC3339))
		infoColor.Printf("   UID: %s\n", event.UID)
		fmt.Println()
	}

	waitForEnter()
}

func clearScreen() {
	fmt.Print("\033[H\033[2J")
}

func waitForEnter() {
	promptColor.Print("\nPress Enter to continue...")
	bufio.NewReader(os.Stdin).ReadBytes('\n')
}

func main() {
	titleColor.Println(asciiTitle)
	headerColor.Println("Starting CalDAV Terminal - The Ultimate Calendar CLI...")
	infoColor.Println("This tool requires the following packages:")
	infoColor.Println("  - github.com/fatih/color")
	infoColor.Println("  - golang.org/x/term")
	infoColor.Println("  - github.com/Snawoot/go-http-digest-auth-client")
	infoColor.Println("  - github.com/emersion/go-webdav")
	fmt.Println()

	app := NewCalendarApp()

	err := app.Initialize()
	if err != nil {
		errorColor.Printf("Initialization error: %v\n", err)
		os.Exit(1)
	}

	app.mainMenu()
}
