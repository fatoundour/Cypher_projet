//REQUETE 1
// Cette requête énumère des chemins AIR_ROUTE de longueur bornée (1 à 6), conserve uniquement ceux dont les 
//distances des relations sont strictement croissantes, et profile l’exécution afin de mesurer le temps et les 
//accès à la base tout en limitant le nombre de résultats retournés en 500.
PROFILE
MATCH p =
  (a:AIRPORT)-[:AIR_ROUTE*1..6]->(b:AIRPORT)
WHERE NOT EXISTS {
  WITH relationships(p) AS rels
  UNWIND range(0, size(rels) - 2) AS i
  WITH rels, i
  WHERE rels[i].distance >= rels[i + 1].distance
}
RETURN p
LIMIT 500;


//REQUETE 2
// Cette requête calcule et profile le plus court chemin non pondéré entre les aéroports YUM et ABE sur le 
//graphe AIR_ROUTE (borné à 6 relations) et retourne le chemin ainsi que sa longueur en nombre de segments.
PROFILE
MATCH p = shortestPath (
  (a:AIRPORT{faa:"YUM"})-[:AIR_ROUTE*1..6]->(b:AIRPORT{faa:"ABE"})
)
RETURN p , length(p) AS long;


//REQUETE 3
// Cette requête énumère des chemins AIR_ROUTE pondérés de longueur bornée (1 à 6) entre YUM et ABE, calcule 
//le coût total de chaque chemin par agrégation des distances, puis profile l’exécution afin d’identifier le 
//chemin de coût minimal.
PROFILE
MATCH p = (a:AIRPORT {faa:"YUM"})-[:AIR_ROUTE*1..6]->(b:AIRPORT {faa:"ABE"})
WITH p,
     reduce(cost = 0, r IN relationships(p) | cost + r.distance) AS totalCost
RETURN p, totalCost
ORDER BY totalCost
LIMIT 1;

//REQUETE 4
// Cette requete trouve  les chemins de vol de longueur variable dont la date départ est croissante

MATCH p = (a:AIRPORT)<-[:FROM]-(f:FLIGHT)-[:TO]->(b:AIRPORT)
          (<-[:FROM]-(:FLIGHT)-[:TO]->(:AIRPORT))*
WHERE NOT EXISTS {
  MATCH (x:AIRPORT)<-[r1:FROM]-(f1:FLIGHT)-[:TO]->(y:AIRPORT)
        (<-[:FROM]-[r2:FROM]-(:FLIGHT)-[:TO]->(:AIRPORT))*
  WHERE r1.dep_time_utc >= r2.dep_time_utc
}
RETURN p
LIMIT 10;


//REQUETE 5
// requête retournant un voyage en 4 vols de New-York (La Guardia) à Los Angeles
// en respectant certaines contraintes 
CYPHER 5 runtime=parallel
MATCH path =
  (origin:AIRPORT {faa:"LGA"})
  (
    (:AIRPORT)
    //nouvelle contrainte sur les heures de départ
    <-[dep:FROM WHERE dep.dep_time_utc IS NOT NULL
                     AND dep.dep_time_utc.hour >= 12
                     AND dep.dep_time_utc.hour < 14]
    -(fts:FLIGHT)
    -[arr:TO WHERE arr.arr_time_utc IS NOT NULL]
    //nouvelle contrainte sur les aéroports à ne pas visiter
    ->(a:AIRPORT WHERE NOT a.faa IN ["ATL", "ORD", "DFW", "IAH", "DTW", "CLT", "BOS", "BWI", "DEN", "JFK", "SEA", "SFO", "IAD", "EWR", "MSP", "MDW", "LAS", "DCA", "SAN", "PHX", "MEM", "CLE", "PDX", "TPA", "DAL", "AUS", "CVG", "HOU", "PHL", "MIA", "SMF", "MCI", "OAK", "FLL", "SLC", "MSY", "RDU", "SJC", "CMH", "SAT", "MKE", "TUS", "ABQ", "ELP", "ONT"])
  ){4}
  (:AIRPORT {faa:"LAX"})

WHERE
  //contrainte physique
  size(a) = size(apoc.coll.toSet(a))
  //contraintes temporelles
  AND ALL(i IN range(0, size(dep)-2) WHERE
       arr[i].arr_time_utc < dep[i+1].dep_time_utc
   AND arr[i].arr_time_utc + duration({days:3}) <= dep[i+1].dep_time_utc
   AND dep[i+1].dep_time_utc <= arr[i].arr_time_utc + duration({days:5})
  )

RETURN
  [origin.name] + [x IN a | x.name] AS airpts,
  fts,
  path
LIMIT 1