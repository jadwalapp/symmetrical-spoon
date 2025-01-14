package util

import "github.com/spf13/viper"

// FalakConfig stores all configuration of the application.
// The values are read by viper from a config file or environment variables.
type FalakConfig struct {
	Port                        string `mapstructure:"PORT"`
	JWTPublicKey                string `mapstructure:"JWT_PUBLIC_KEY"`
	JWTPrivateKey               string `mapstructure:"JWT_PRIVATE_KEY"`
	DBUser                      string `mapstructure:"DB_USER"`
	DBPassword                  string `mapstructure:"DB_PASSWORD"`
	DBHost                      string `mapstructure:"DB_HOST"`
	DBPort                      string `mapstructure:"DB_PORT"`
	DBName                      string `mapstructure:"DB_NAME"`
	DBSSLMode                   string `mapstructure:"DB_SSL_MODE"`
	EmailerName                 string `mapstructure:"EMAILER_NAME"`
	SMTPHost                    string `mapstructure:"SMTP_HOST"`
	SMTPPort                    string `mapstructure:"SMTP_PORT"`
	SMTPUSername                string `mapstructure:"SMTP_USERNAME"`
	SMTPPasword                 string `mapstructure:"SMTP_PASSWORD"`
	Domain                      string `mapstructure:"DOMAIN"`
	ResendApiKey                string `mapstructure:"RESEND_API_KEY"`
	GoogleClientBaseUrl         string `mapstructure:"GOOGLE_CLIENT_BASE_URL"`
	GoogleOAuthClientId         string `mapstructure:"GOOGLE_OAUTH_CLIENT_ID"`
	LokiEndpoint                string `mapstructure:"LOKI_ENDPOINT"`
	LokiPushIntervalSeconds     int    `mapstructure:"LOKI_PUSH_INTERVAL_SECONDS"`
	LokiMaxBatchSize            int    `mapstructure:"LOKI_MAX_BATCH_SIZE"`
	BaikalHost                  string `mapstructure:"BAIKAL_HOST"`
	CalDAVPasswordEncryptionKey string `mapstructure:"CALDAV_PASSWORD_ENCRYPTION_KEY"`
}

// LoadFalakConfig reads configuration from the provided path or environment variables.
func LoadFalakConfig(path string) (config FalakConfig, err error) {
	viper.AddConfigPath(path)
	viper.SetConfigName("falak")
	viper.SetConfigType("env")
	viper.AutomaticEnv()

	err = viper.ReadInConfig()
	if err != nil {
		return
	}

	err = viper.Unmarshal(&config)
	return
}
