package httpj

import (
	"bytes"
	"context"
	"database/sql"
	"fmt"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/mobileconfig"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/store"
	"github.com/jadwalapp/symmetrical-spoon/falak/pkg/util"
	"github.com/rs/zerolog/log"
	"howett.net/plist"
)

type service struct {
	store                       store.Queries
	calDAVPasswordEncryptionKey string
	caldavHost                  string
	isProd                      bool
}

func (s *service) HandleMobileConfigCaldav(w http.ResponseWriter, r *http.Request) {
	ctx := context.Background()
	if r.Method != "GET" {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	q := r.URL.Query()
	mtHashedFromUser := q.Get("s")
	hashedToken := util.HashStringToBase64SHA256(mtHashedFromUser)

	magicToken, err := s.store.GetUnusedMagicTokenByTokenHash(ctx, store.GetUnusedMagicTokenByTokenHashParams{
		TokenHash: hashedToken,
		TokenType: store.MagicTokenTypeCaldav,
	})
	if err != nil {
		if err == sql.ErrNoRows {
			log.Ctx(ctx).Err(err).Msg("no token hash exists in the database that matches the hash of the token provided by user")
			http.Error(w, "Invalid or expired token", http.StatusBadRequest)
			return
		}

		log.Ctx(ctx).Err(err).Msg("failed running GetUnusedMagicTokenByTokenHash")
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}
	if magicToken.ExpiresAt.Before(time.Now()) {
		log.Ctx(ctx).Error().Msg("expired magic token")
		http.Error(w, "Token expired", http.StatusBadRequest)
		return
	}

	customer, err := s.store.GetCalDavAccountByCustomerId(ctx, store.GetCalDavAccountByCustomerIdParams{
		CustomerID:    magicToken.CustomerID,
		EncryptionKey: s.calDAVPasswordEncryptionKey,
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed getting CalDAV account")
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Header().Add("Content-Type", "application/x-apple-aspen-config")
	filename := fmt.Sprintf("%s-%s.mobileconfig", customer.CustomerID, time.Now())
	w.Header().Set("Content-Disposition", "attachment; filename=\""+filename+"\"")

	profileUUID := uuid.NewString()
	payloadUUID := uuid.NewString()
	profileIdentifier := "app.jadwal.mishkat.profile.caldavconfig"
	payloadIdentifier := profileIdentifier + ".caldavpayload"

	caldavPort := 80
	if s.isProd {
		caldavPort = 443
	}

	caldavPayload := mobileconfig.CalDAVPayload{
		PayloadVersion:           1,
		PayloadType:              "com.apple.caldav.account",
		PayloadIdentifier:        payloadIdentifier,
		PayloadUUID:              payloadUUID,
		PayloadDisplayName:       fmt.Sprintf("Jadwal Calendar - %s", customer.Username),
		CalDAVAccountDescription: fmt.Sprintf("Jadwal Calendar Account for %s", customer.Username),
		CalDAVHostName:           s.caldavHost,
		CalDAVPort:               caldavPort,
		CalDAVUseSSL:             s.isProd,
		CalDAVPrincipalURL:       "/dav.php",
		CalDAVUsername:           customer.Username,
		CalDAVPassword:           customer.DecryptedPassword,
	}

	mobileConfig := mobileconfig.MobileConfig{
		PayloadContent:           []interface{}{caldavPayload},
		PayloadDescription:       "Installs CalDAV account settings",
		PayloadDisplayName:       fmt.Sprintf("Jadwal Calendar Profile - %s", customer.Username),
		PayloadIdentifier:        profileIdentifier,
		PayloadOrganization:      "Jadwal",
		PayloadRemovalDisallowed: false,
		PayloadScope:             "User",
		PayloadType:              "Configuration",
		PayloadUUID:              profileUUID,
		PayloadVersion:           1,
	}

	plistBytes := new(bytes.Buffer)
	encoder := plist.NewEncoder(plistBytes)
	encoder.Indent("  ")
	err = encoder.Encode(mobileConfig)
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed encoding plist")
		http.Error(w, "Failed to generate configuration profile", http.StatusInternalServerError)
		return
	}

	err = s.store.UpdateMagicTokenUsedAtByTokenHash(ctx, store.UpdateMagicTokenUsedAtByTokenHashParams{
		TokenHash: magicToken.TokenHash,
		UsedAt:    sql.NullTime{Time: time.Now(), Valid: true},
	})
	if err != nil {
		log.Ctx(ctx).Err(err).Msg("failed running UpdateMagicTokenUsedAtByTokenHash")
		http.Error(w, "Internal server error", http.StatusInternalServerError)
		return
	}

	w.Write(plistBytes.Bytes())

}

func (s *service) HandleMobileConfigWebcal(w http.ResponseWriter, r *http.Request) {
	// ctx := context.Background()

	// parse values from body

	// return the file template with filled values and correct header value :

}

func (s *service) HandleRoot(w http.ResponseWriter, r *http.Request) {
	w.Header().Add("jadwal-fingerprint", "sg2a")
	w.Write([]byte(`                                                   .                                                
. .                                        .             .                                          
       ......................................................................................       
   .  ...----------------------------------------------------------------------------------..       
    .  ..----------------------------------------------------------------------------------..       
       ..==================================================================================..       
       ..=========================================+========================================..       
       ..==================================++*#%@@@%+======================================:.       
    .  ..==============================*@@@@@@@@@@%*=======================================:.       
       ..==============================#@@@%*+=============================================:.       
       ..==================================================================================:.    .  
       ..==================================================================================:.  ..   
       ..==================================================================================:.       
      ...==================================================================================:.     . 
       ..==================================================================================:..      
       ..==============================+#%@@@@@%#+=========================================:.       
       ..===========================*%@@@@@@@@@@@@@@#+=====================================:.       
 .    ...=========================*%@@@@@@@@@@@@@@@@@@@#+==================================:.       
 .     ..=======================+*@@@@@@@@@@@@@@@@@@@@@@@@%*+==============================:.       
       ..=======================*@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@%%%%%*======================:.       
       ..======================+#@@@@@@@%#*+++**#%@@@@@@@@@@@@@@@@@@#+=====================:.   .   
    .  ..======================+*@@@@@%*=========+*%@@@@@@@@@@@@@@@@#+=====================:.       
  .    ..====================================++#@@@@@@@@@@@@@@@@@@@@#+=====================:.      .
   .   ..++=+++++++++++++++++++++++++++++++*%@@@@@@@@@@@@@@@@@@@@@@@*++++++++++++++++++++++:..      
       ..+++++++++++++++++++++++++++++++*%@@@@@@@@@@@@@@@%#*+++++++++++++++++++++++++++++++:.    . .
       ..+++++++++++++++++++++++++++++*%@@@@@@@@@@@@%#*++++++++++++++++++++++++++++++++++++:.  .    
       ..++++++++++++++++++++++++++++%@@@@@@@@@@%#*++++++++++++++++++++++++++++++++++++++++:.       
.      ..++++++++++++++++++++++++++*@@@@@@@@@@#*+++++++++++++++++++++++++++++++++++++++++++:.       
       ..+++++++++++++++++++++++++*@@@@@@@@@*+++++++++*++++++++++++++++++++++++++++++++++++:.       
       ..++++++++++++++++++++++++*@@@@@@@@#+++++++++%@@@#++++++++++++++++++++++++++++++++++:.       
       ..++++++++++++++++++++++++#@@@@@@@#++++++++#@@@@@@@#++++++++++++++++++++++++++++++++:.       
       ..+++++++++++++++++++++++*@@@@@@@%+++++++++*%@@@@@%*++++++++++++++++++++++++++++++++:.       
       ..+++++++++++++++++++++++#@@@@@@@%+++++++++++*%@%*++++++++++++++++++++++++++++++++++:.       
       ..+++++++++++++++++++++++#@@@@@@@%++++++++++++++++++++++++++++++++++++++++++++++++++:.       
   ..  ..+++++++++++++++++++++++*@@@@@@@@%*++++++++++++++++++++++++++++++++++++++++++++++++:.  .    
       ..++++++++++++++++++++++++#@@@@@@@@@#*++++++++++++++++++++++++++++++++++++++++++++++:.       
       ..++++++++++++++++++++++++*%@@@@@@@@@@@@%%###*************++++++++++++++++++++++++++:.       
     . ..+++++++++++++++++++++++++*%@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#*++++++++++++++++++++++++:.       
    .  .:++++++++++++++++++++++++++*#@@@@@@@@@@@@@@@@@@@@@@@@@@@@%*++++++++++++++++++++++++:.   .  .
       .:++++++++++++++++++++++++++++*%@@@@@@@@@@@@@@@@@@@@@@@@@@%*++++++++++++++++++++++++:.       
       .:++++++++++++++++++++++++++++++*#%@@@@@@@@@@@@@@@@@@@@@@@%*++++++++++++++++++++++++:.       
  .    .:***********************************#%%@@@@@@@@@@@@@@@@@@#*************************:.       
       .:**********************************************************************************:..      
       .:**********************************************************************************:.       
       .:**********************************************************************************:.       
    .  .:**********************************************************************************:.     . 
       .:**********************************************************************************:..      
      ...----------------------------------------------------------------------------------..       
                                                              .                .                    
                                                                                                .   
          .                                    .        .    .                             .        
                                                   .                                                
          .      .                                   .           .                                . `))
}

func NewRouter(store store.Queries, calDAVPasswordEncryptionKey string, caldavHost string, isProd bool) Svc {
	return &service{
		store:                       store,
		calDAVPasswordEncryptionKey: calDAVPasswordEncryptionKey,
		caldavHost:                  caldavHost,
		isProd:                      isProd,
	}
}
