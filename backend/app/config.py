from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    MONGO_URI: str
    MONGO_DB_NAME: str
    PLASGATE_PRIVATE_KEY: str
    PLASGATE_SECRET: str
    PLASGATE_SENDER: str
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str
    ACCESS_TOKEN_EXPIRE_MINUTES: int
    REFRESH_TOKEN_EXPIRE_DAYS: int
    DEBUG: bool = True
    ENVIRONMENT: str = "development"

    class Config:
        env_file = '.env'

settings = Settings()
