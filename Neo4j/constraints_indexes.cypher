// =======================
// CONTRAINTES D’UNICITÉ
// =======================

// AIRPORT : clé logique
CREATE CONSTRAINT airport_faa_unique
IF NOT EXISTS
FOR (a:AIRPORT)
REQUIRE a.faa IS UNIQUE;

// AIRLINE : clé logique
CREATE CONSTRAINT airline_carrier_unique
IF NOT EXISTS
FOR (l:AIRLINE)
REQUIRE l.carrier IS UNIQUE;

// FLIGHT : clé technique
CREATE CONSTRAINT flight_id_unique
IF NOT EXISTS
FOR (f:FLIGHT)
REQUIRE f.id IS UNIQUE;


// =======================
// INDEX (PERFORMANCE)
// =======================

// Temps de départ
CREATE INDEX from_sched_dep_time_utc_index
IF NOT EXISTS
FOR ()-[r:FROM]-()
ON (r.sched_dep_time_utc);

CREATE INDEX from_dep_time_utc_index
IF NOT EXISTS
FOR ()-[r:FROM]-()
ON (r.dep_time_utc);

CREATE INDEX from_dep_delay_index
IF NOT EXISTS
FOR ()-[r:FROM]-()
ON (r.dep_delay);

// Temps d'arrivée
CREATE INDEX to_sched_arr_time_utc_index
IF NOT EXISTS
FOR ()-[r:TO]-()
ON (r.sched_arr_time_utc);

CREATE INDEX to_arr_time_utc_index
IF NOT EXISTS
FOR ()-[r:TO]-()
ON (r.arr_time_utc);

CREATE INDEX to_arr_delay_index
IF NOT EXISTS
FOR ()-[r:TO]-()
ON (r.arr_delay);


// Sur la distance entre airports
CREATE INDEX air_route_distance_index
IF NOT EXISTS
FOR ()-[r:AIR_ROUTE]-()
ON (r.distance);

