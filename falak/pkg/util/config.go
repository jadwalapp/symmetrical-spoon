package util

import "github.com/spf13/viper"

// GrpcConfig stores all configuration of the application.
// The values are read by viper from a config file or environment variables.
type GrpcConfig struct {
	Port          string `mapstructure:"PORT"`
	DBUser        string `mapstructure:"DB_USER"`
	DBPassword    string `mapstructure:"DB_PASSWORD"`
	DBHost        string `mapstructure:"DB_HOST"`
	DBPort        string `mapstructure:"DB_PORT"`
	DBName        string `mapstructure:"DB_NAME"`
	DBSSLMode     string `mapstructure:"DB_SSL_MODE"`
	JWTPublicKey  string `mapstructure:"JWT_PUBLIC_KEY"`
	JWTPrivateKey string `mapstructure:"JWT_PRIVATE_KEY"`
}

// LoadGrpcConfig reads configuration from the provided path or environment variables.
func LoadGrpcConfig(path string) (config GrpcConfig, err error) {
	viper.AddConfigPath(path)
	viper.SetConfigName("grpc")
	viper.SetConfigType("env")
	viper.AutomaticEnv()

	err = viper.ReadInConfig()
	if err != nil {
		return
	}

	err = viper.Unmarshal(&config)
	return
}