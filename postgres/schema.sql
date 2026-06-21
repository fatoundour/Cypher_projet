DROP TABLE IF EXISTS flight;
DROP TABLE IF EXISTS airport_route;
DROP TABLE IF EXISTS airline;
DROP TABLE IF EXISTS airport;



CREATE TABLE IF NOT EXISTS airport (
    faa   VARCHAR(10) PRIMARY KEY,
    name_airport  TEXT NOT NULL,
    lat   DOUBLE PRECISION NOT NULL,
    lon   DOUBLE PRECISION NOT NULL,
    tzone TEXT
);

CREATE TABLE IF NOT EXISTS airline (
    carrier VARCHAR(10) PRIMARY KEY,
    name_airline    TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS flight (
    id TEXT PRIMARY KEY,

    origin VARCHAR(10) NOT NULL,
    dest   VARCHAR(10) NOT NULL,

    carrier VARCHAR(10) NOT NULL,

    flight VARCHAR( 10) NOT NULL,
    
    air_time INTEGER NOT NULL,

    dep_delay INTEGER NOT NULL,
    arr_delay INTEGER NOT NULL,

    sched_dep_time_utc TIMESTAMP NOT NULL,
    dep_time_utc       TIMESTAMP NOT NULL,
    sched_arr_time_utc TIMESTAMP NOT NULL,
    arr_time_utc       TIMESTAMP NOT NULL,
    
    CONSTRAINT fk_origin
        FOREIGN KEY (origin)
        REFERENCES airport(faa),

    CONSTRAINT fk_dest
        FOREIGN KEY (dest)
        REFERENCES airport(faa),

    CONSTRAINT fk_carrier
        FOREIGN KEY (carrier)
        REFERENCES airline(carrier)
);

CREATE TABLE IF NOT EXISTS airport_route (
    origin_faa VARCHAR(10) NOT NULL,
    dest_faa   VARCHAR(10) NOT NULL,

    distance INTEGER NOT NULL,

    CONSTRAINT pk_airport_route
        PRIMARY KEY (origin_faa, dest_faa),

    CONSTRAINT fk_route_origin
        FOREIGN KEY (origin_faa)
        REFERENCES airport(faa)
        ON DELETE CASCADE,

    CONSTRAINT fk_route_dest
        FOREIGN KEY (dest_faa)
        REFERENCES airport(faa)
        ON DELETE CASCADE
);


-- Heures prévues (si déjà créées, on garde)
CREATE INDEX IF NOT EXISTS idx_flight_sched_dep_time_utc
ON flight (sched_dep_time_utc);

CREATE INDEX IF NOT EXISTS idx_flight_sched_arr_time_utc
ON flight (sched_arr_time_utc);

-- Heures réelles (ce que tu demandais)
CREATE INDEX IF NOT EXISTS idx_flight_dep_time_utc
ON flight (dep_time_utc);

CREATE INDEX IF NOT EXISTS idx_flight_arr_time_utc
ON flight (arr_time_utc);

-- Retards
CREATE INDEX IF NOT EXISTS idx_flight_dep_delay
ON flight (dep_delay);

CREATE INDEX IF NOT EXISTS idx_flight_arr_delay
ON flight (arr_delay);

-- Distance
CREATE INDEX IF NOT EXISTS idx_airport_route_distance
ON airport_route (distance);
