--Requête 1:
-- Trouver des chemins de longueur variable(1 à 6) entre deux aéroports tels que la distance portée par chaque arête 
EXPLAIN ANALYZE
WITH RECURSIVE paths AS (
    SELECT
        ar.origin_faa AS start_airport,
        ar.dest_faa   AS current_airport,
        ar.distance   AS last_distance,
        ARRAY[ar.origin_faa, ar.dest_faa]::VARCHAR[] AS path,
        1 AS length
    FROM airport_route ar

    UNION ALL

    SELECT
        p.start_airport,
        ar.dest_faa,
        ar.distance,
        p.path || ar.dest_faa,
        p.length + 1
    FROM paths p
    JOIN airport_route ar
      ON ar.origin_faa = p.current_airport
     AND ar.distance > p.last_distance
     AND p.length < 6
     AND NOT ar.dest_faa = ANY(p.path)
)
SELECT *
FROM paths
LIMIT 500;

--Requête 2:
EXPLAIN ANALYZE
-- Trouver des chemins de vols entre deux aéroports avec une correspondance exacte des heures d'arrivée.
WITH RECURSIVE flight_paths AS (
    -- Cas de base : un vol (chemin de longueur 1)
    SELECT
        f.origin,
        f.dest,
        f.arr_time_utc,
        ARRAY[f.origin, f.dest]::VARCHAR[] AS path,
        1 AS length
    FROM flight f

    UNION ALL

    -- Extension du chemin
    SELECT
        p.origin,
        f.dest,
        p.arr_time_utc,
        p.path || f.dest,
        p.length + 1
    FROM flight_paths p
    JOIN flight f
      ON p.dest = f.origin
     AND p.arr_time_utc = f.arr_time_utc
     AND p.length < 5 
)
SELECT *
FROM flight_paths
LIMIT 500;

--Requête 3:
-- Trouver des chemins de vols entre deux aéroports tels que le temps total de vol soit supérieur à 180 minutes.
EXPLAIN ANALYZE
WITH RECURSIVE flight_paths AS (
    -- Cas de base : un seul vol (chemin de longueur 1)
    SELECT
        f.origin,
        f.dest,
        f.air_time AS total_air_time,
        ARRAY[f.origin, f.dest]::VARCHAR[] AS path,
        1 AS length
    FROM flight f

    UNION ALL

    -- Extension du chemin
    SELECT
        p.origin,
        f.dest,
        p.total_air_time + f.air_time AS total_air_time,
        p.path || f.dest,
        p.length + 1
    FROM flight_paths p
    JOIN flight f
      ON p.dest = f.origin
     AND p.length < 3   
)
SELECT
    origin,
    dest,
    total_air_time,
    path,
    length
FROM flight_paths
WHERE total_air_time > 180
LIMIT 500;

--Requête 4:
-- Trouver le chemin le moins coûteux entre deux aéroports.
EXPLAIN ANALYZE
WITH RECURSIVE paths AS (
    SELECT
        CAST('YUM' AS VARCHAR) AS airport,
        0.0 AS total_cost,
        ARRAY['YUM'] AS path
    UNION ALL
    SELECT
        ar.dest_faa,
        paths.total_cost + ar.distance,
        paths.path || ar.dest_faa
    FROM paths
    JOIN airport_route ar
      ON ar.origin_faa = paths.airport
    WHERE
        NOT ar.dest_faa = ANY(paths.path)
        AND array_length(paths.path, 1) < 6
)
SELECT *
FROM paths
WHERE airport = 'ABE'
ORDER BY total_cost
LIMIT 1;

--Requête 5:
-- Trouver le plus court chemin (en nombre d'arêtes) entre deux aéroports.
EXPLAIN ANALYZE
WITH RECURSIVE bfs AS (
    -- niveau 0 : source
    SELECT
        CAST('YUM' AS VARCHAR) AS airport,
        0 AS depth,
        ARRAY['YUM'] AS path
    UNION ALL
    -- expansion
    SELECT
        ar.dest_faa AS airport,
        bfs.depth + 1 AS depth,
        bfs.path || ar.dest_faa
    FROM bfs
    JOIN airport_route ar
      ON ar.origin_faa = bfs.airport
    WHERE NOT ar.dest_faa = ANY(bfs.path)
        AND bfs.depth < 6
)
SELECT *
FROM bfs
WHERE airport = 'ABE'
ORDER BY depth
LIMIT 1;

--Requête 6:
WITH RECURSIVE trip AS (
     -- origin et dest : origine et destination du dernier vol
     -- depth : nombre de vols global
     -- f_nodes : liste de l'id des vols faits
     -- a_nodes : liste des aéroports visités lors des vols
     -- arr_time : timestamp du dernier vol effectué

     SELECT origin, dest, 1 AS depth, array[id] AS f_nodes,
     	    array[origin,dest]::varchar[] AS a_nodes, arr_time_utc 
     FROM flight f
     WHERE origin = 'LGA' -- vol depuis New-York (La Guardia)
       AND f.dep_time_utc IS NOT NULL
       AND f.arr_time_utc IS NOT NULL
       --AND EXTRACT(HOUR FROM f.dep_time_utc) >= 12
       --AND EXTRACT(HOUR FROM f.arr_time_utc) < 14
       AND NOT f.dest=any(array['ATL', 'ORD', 'DFW', 'IAH', 'DTW', 'CLT', 'BOS', 'BWI', 'DEN', 'JFK', 'SEA', 'SFO', 'IAD', 'EWR', 'MSP', 'MDW', 'LAS', 'DCA', 'SAN', 'PHX', 'MEM', 'CLE', 'PDX', 'TPA', 'DAL', 'AUS', 'CVG', 'HOU', 'PHL', 'MIA', 'SMF', 'MCI', 'OAK', 'FLL', 'SLC', 'MSY', 'RDU', 'SJC', 'CMH', 'SAT', 'MKE', 'TUS', 'ABQ', 'ELP', 'ONT'])

     UNION ALL
     SELECT f.origin, f.dest, t.depth+1, t.f_nodes||f.id,
     	    t.a_nodes||f.dest, f.arr_time_utc
     FROM flight f JOIN trip t ON f.origin = t.dest
     WHERE
	--vol qui évite d'arriver dans certains aéroports
	NOT f.dest=any(array['ATL', 'ORD', 'DFW', 'IAH', 'DTW', 'CLT', 'BOS', 'BWI', 'DEN', 'JFK', 'SEA', 'SFO', 'IAD', 'EWR', 'MSP', 'MDW', 'LAS', 'DCA', 'SAN', 'PHX', 'MEM', 'CLE', 'PDX', 'TPA', 'DAL', 'AUS', 'CVG', 'HOU', 'PHL', 'MIA', 'SMF', 'MCI', 'OAK', 'FLL', 'SLC', 'MSY', 'RDU', 'SJC', 'CMH', 'SAT', 'MKE', 'TUS', 'ABQ', 'ELP', 'ONT'])
        -- on ne considère que des vols qui ont eu lieu et entre 12h et 14H
       AND f.dep_time_utc IS NOT NULL
       AND f.arr_time_utc IS NOT NULL
       AND EXTRACT(HOUR FROM f.dep_time_utc) >= 12
       AND EXTRACT(HOUR FROM f.arr_time_utc) < 14
       -- on ne repasse pas deux fois par le même aéroport
       AND NOT f.dest=any(t.a_nodes)
       -- on ne fait que 4 vols
       AND t.depth < 4
       -- contraintes temporelles
       AND t.arr_time_utc < f.dep_time_utc
       AND f.dep_time_utc >= t.arr_time_utc + INTERVAL '3 days'
       AND f.dep_time_utc <= t.arr_time_utc + INTERVAL '5 days'
)
SELECT f_nodes, a_nodes
FROM trip t
WHERE t.depth = 4
  AND t.dest = 'LAX'
LIMIT 1 ;