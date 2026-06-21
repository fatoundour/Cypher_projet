-- Importaion des données nettoyées dans PostgreSQL

\copy airport (faa,name_airport,lat,lon,tzone) FROM 'data/airports_cleaned.csv' DELIMITER ',' CSV HEADER;

\copy airline (carrier,name_airline) FROM 'data/airlines_cleaned.csv' DELIMITER ',' CSV HEADER;

\copy flight (id,origin,dest,carrier,flight,air_time,dep_delay,arr_delay,sched_dep_time_utc,dep_time_utc,sched_arr_time_utc,arr_time_utc) FROM 'data/flights_sql.csv' DELIMITER ',' CSV HEADER;

\copy airport_route (origin_faa, dest_faa, distance) FROM 'data/airport_route_sql.csv' DELIMITER ',' CSV HEADER;
