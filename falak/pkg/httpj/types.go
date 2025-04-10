package httpj

import "net/http"

type Svc interface {
	HandleRoot(w http.ResponseWriter, r *http.Request)
	HandleMobileConfigCaldav(w http.ResponseWriter, r *http.Request)
	HandleMobileConfigWebcal(w http.ResponseWriter, r *http.Request)
}
