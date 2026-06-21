// import de airports

LOAD CSV WITH HEADERS
FROM 'file:///airports_cleaned.csv'
AS row

MERGE (a:AIRPORT {faa: row.faa})
SET
  a.name  = row.name,
  a.lat   = toFloat(row.lat),
  a.lon   = toFloat(row.lon),
  a.tzone = CASE
              WHEN row.tzone = '' THEN NULL
              ELSE row.tzone
            END;


// import airlines

LOAD CSV WITH HEADERS
FROM 'file:///airlines_cleaned.csv'
AS row

MERGE (l:AIRLINE {carrier: row.carrier})
SET
  l.name = row.name;

// import flights

LOAD CSV WITH HEADERS
FROM 'file:///flights_cleaned.csv'
AS row

CALL {
  WITH row
  MERGE (f:FLIGHT {id: row.id})
  SET
    f.flight   = row.flight,
    f.air_time = toInteger(row.air_time)
}
IN TRANSACTIONS OF 1000 ROWS;

// création de FROM entre flights et airports

LOAD CSV WITH HEADERS
FROM 'file:///flights_cleaned.csv'
AS row

CALL {
  WITH row
  MATCH (f:FLIGHT {id: row.id})
  MATCH (a:AIRPORT {faa: row.origin})

  MERGE (f)-[r:FROM]->(a)
  SET
    r.sched_dep_time_utc = datetime(replace(row.sched_dep_time_utc, ' ', 'T')),
    r.dep_time_utc       = datetime(replace(row.dep_time_utc, ' ', 'T')),
    r.dep_delay          = toInteger(row.dep_delay)
}
IN TRANSACTIONS OF 1000 ROWS;

// création de FROM entre flights et airports

LOAD CSV WITH HEADERS
FROM 'file:///flights_cleaned.csv'
AS row

CALL {
  WITH row
  MATCH (f:FLIGHT {id: row.id})
  MATCH (a:AIRPORT {faa: row.dest})

  MERGE (f)-[r:TO]->(a)
  SET
    r.sched_arr_time_utc = datetime(replace(row.sched_arr_time_utc, ' ', 'T')),
    r.arr_time_utc       = datetime(replace(row.arr_time_utc, ' ', 'T')),
    r.arr_delay          = toInteger(row.arr_delay)
}
IN TRANSACTIONS OF 1000 ROWS;


// création de OPERATED_BY entre flights et airlines

LOAD CSV WITH HEADERS
FROM 'file:///flights_cleaned.csv'
AS row

CALL {
  WITH row
  MATCH (f:FLIGHT {id: row.id})
  MATCH (l:AIRLINE {carrier: row.carrier})
  MERGE (f)-[:OPERATED_BY]->(l)
}
IN TRANSACTIONS OF 1000 ROWS;

// création de AIR_ROUTE entre flights et airlines

LOAD CSV WITH HEADERS
FROM 'file:///flights_cleaned.csv'
AS row

CALL {
  WITH row
  MATCH (a1:AIRPORT {faa: row.origin})
  MATCH (a2:AIRPORT {faa: row.dest})

  MERGE (a1)-[r:AIR_ROUTE]->(a2)
  ON CREATE SET
    r.distance = toInteger(row.distance)
}
IN TRANSACTIONS OF 1000 ROWS;
