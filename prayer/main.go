package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"time"
)

type prayer struct {
	Fajar   string `json:"Fajr"`
	Sunrise string `json:"Sunrise"`
	Duhar   string `json:"Dhuhr"`
	Asar    string `json:"Asr"`
	Magrib  string `json:"Maghrib"`
	Isha    string `json:"Isha"`
}

type Timings struct {
	Timings prayer `json:"timings"`
}

type GetPrayertimeInfoResponse struct {
	Data Timings `json:"data"`
}

type GetPrayertimeInfoRequest struct {
	Date    string `json:"date"`
	City    string `json:"city"`
	Country string `json:"country"`
}

type AdhanClient interface {
	GetPrayertimeInfo(context.Context, *GetPrayertimeInfoRequest) (*GetPrayertimeInfoResponse, error)
}

type adhanclient struct{}

type GeoLocation struct {
	City    string `json:"city"`
	Country string `json:"country"`
}

// GetGeoLocation fetches the location data using IP geolocation API
func GetGeoLocation() (*GeoLocation, error) {
	// API URL for IP geolocation
	resp, err := http.Get("http://ip-api.com/json/")
	if err != nil {
		return nil, fmt.Errorf("Error fetching location: %v", err)
	}
	defer resp.Body.Close()

	// Read and parse the response
	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var location GeoLocation
	if err := json.Unmarshal(body, &location); err != nil {
		return nil, fmt.Errorf("Error unmarshalling geolocation data: %v", err)
	}

	return &location, nil
}

// GetPrayertimeInfo makes an HTTP request to the Aladhan API and returns the prayer times
func (*adhanclient) GetPrayertimeInfo(ctx context.Context, r *GetPrayertimeInfoRequest) (*GetPrayertimeInfoResponse, error) {
	encodedCity := url.QueryEscape(r.City)
	encodedCountry := url.QueryEscape(r.Country)
	url := fmt.Sprintf("https://api.aladhan.com/v1/timingsByCity?city=%s&country=%s&date=%s", encodedCity, encodedCountry, r.Date)

	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("API request failed with status: %s", resp.Status)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	var response GetPrayertimeInfoResponse
	if err := json.Unmarshal(body, &response); err != nil {
		return nil, fmt.Errorf("Error unmarshalling JSON: %v", err)
	}

	return &response, nil
}

func main() {
	// Fetch user's location
	location, err := GetGeoLocation()
	if err != nil {
		fmt.Printf("Error fetching location: %v\n", err)
		return
	}

	// Format today's date
	today := time.Now().Format("02-01-2006")

	// Fetch prayer times
	var aa AdhanClient = &adhanclient{}
	resp, err := aa.GetPrayertimeInfo(context.Background(), &GetPrayertimeInfoRequest{
		Date:    today,
		City:    location.City,
		Country: location.Country,
	})
	if err != nil {
		fmt.Printf("Error fetching prayer times: %v\n", err)
		return
	}

	// Print prayer times
	fmt.Printf("Prayer Times for %s, %s on %s:\n", location.City, location.Country, today)
	fmt.Printf("Fajar: %s\n", resp.Data.Timings.Fajar)
	fmt.Printf("Sunrise: %s\n", resp.Data.Timings.Sunrise)
	fmt.Printf("Duhar: %s\n", resp.Data.Timings.Duhar)
	fmt.Printf("Asar: %s\n", resp.Data.Timings.Asar)
	fmt.Printf("Magrib: %s\n", resp.Data.Timings.Magrib)
	fmt.Printf("Isha: %s\n", resp.Data.Timings.Isha)
}
