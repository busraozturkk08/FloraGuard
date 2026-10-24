
-- Temizlik (sadece geliştirme aşamasında)
DROP TABLE IF EXISTS risk_alerts, diagnoses, weather_snapshots,
                     watering_logs, plant_identifications, user_plants,
                     species_diseases, diseases, locations, species, users CASCADE;

-- ===== 1. users =====
CREATE TABLE users (
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role          VARCHAR(20)  NOT NULL DEFAULT 'user'
                  CHECK (role IN ('user', 'admin')),
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ===== 2. locations =====
CREATE TABLE locations (
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id       INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name          VARCHAR(100) NOT NULL,
    location_type VARCHAR(10)  NOT NULL
                  CHECK (location_type IN ('indoor', 'outdoor')),
    city          VARCHAR(100) NOT NULL,
    created_at    TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- ===== 3. species =====
CREATE TABLE species (
    id                     INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    common_name            VARCHAR(100) NOT NULL UNIQUE,
    scientific_name        VARCHAR(150) UNIQUE,
    watering_interval_days INT NOT NULL CHECK (watering_interval_days > 0),
    light_need             VARCHAR(10) NOT NULL
                           CHECK (light_need IN ('low', 'medium', 'high')),
    min_temp_c             INT,
    care_notes             TEXT
);

-- ===== 4. user_plants =====
CREATE TABLE user_plants (
    id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    location_id     INT NOT NULL REFERENCES locations(id) ON DELETE RESTRICT,
    species_id      INT NOT NULL REFERENCES species(id) ON DELETE RESTRICT,
    nickname        VARCHAR(100),
    planted_at      DATE,
    last_watered_at TIMESTAMP,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ===== 5. watering_logs =====
CREATE TABLE watering_logs (
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_plant_id INT NOT NULL REFERENCES user_plants(id) ON DELETE CASCADE,
    watered_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    amount_ml     INT CHECK (amount_ml > 0),
    note          VARCHAR(255)
);

-- ===== 6. diseases =====
CREATE TABLE diseases (
    id              INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name            VARCHAR(100) NOT NULL UNIQUE,
    symptoms        TEXT NOT NULL,
    treatment       TEXT NOT NULL,
    risk_min_humidity INT CHECK (risk_min_humidity BETWEEN 0 AND 100),
    risk_min_temp_c   INT,
    risk_max_temp_c   INT,
    CHECK (risk_max_temp_c IS NULL OR risk_min_temp_c IS NULL
           OR risk_max_temp_c >= risk_min_temp_c)
);

-- ===== 7. species_diseases (çoktan çoğa) =====
CREATE TABLE species_diseases (
    species_id INT NOT NULL REFERENCES species(id) ON DELETE CASCADE,
    disease_id INT NOT NULL REFERENCES diseases(id) ON DELETE CASCADE,
    PRIMARY KEY (species_id, disease_id)
);

-- ===== 8. plant_identifications =====
CREATE TABLE plant_identifications (
    id             INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id        INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    species_id     INT REFERENCES species(id) ON DELETE SET NULL,
    image_path     VARCHAR(255) NOT NULL,
    llm_raw_result JSONB,
    confidence     NUMERIC(4,3) CHECK (confidence BETWEEN 0 AND 1),
    status         VARCHAR(15) NOT NULL DEFAULT 'identified'
                   CHECK (status IN ('identified', 'not_recognized')),
    created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ===== 9. diagnoses =====
CREATE TABLE diagnoses (
    id             INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_plant_id  INT NOT NULL REFERENCES user_plants(id) ON DELETE CASCADE,
    disease_id     INT REFERENCES diseases(id) ON DELETE SET NULL,
    image_path     VARCHAR(255) NOT NULL,
    llm_raw_result JSONB,
    confidence     NUMERIC(4,3) CHECK (confidence BETWEEN 0 AND 1),
    status         VARCHAR(15) NOT NULL DEFAULT 'diagnosed'
                   CHECK (status IN ('diagnosed', 'healthy', 'not_recognized')),
    created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ===== 10. weather_snapshots =====
CREATE TABLE weather_snapshots (
    id            INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    city          VARCHAR(100) NOT NULL,
    temperature_c NUMERIC(4,1) NOT NULL,
    humidity      INT NOT NULL CHECK (humidity BETWEEN 0 AND 100),
    rain_mm       NUMERIC(5,1) NOT NULL DEFAULT 0 CHECK (rain_mm >= 0),
    fetched_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ===== 11. risk_alerts =====
CREATE TABLE risk_alerts (
    id                  INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_plant_id       INT NOT NULL REFERENCES user_plants(id) ON DELETE CASCADE,
    disease_id          INT NOT NULL REFERENCES diseases(id) ON DELETE CASCADE,
    weather_snapshot_id INT REFERENCES weather_snapshots(id) ON DELETE SET NULL,
    message             VARCHAR(255) NOT NULL,
    is_read             BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW()
);