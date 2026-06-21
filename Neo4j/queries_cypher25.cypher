//REQUETE 1
// Cette requête Cypher 25 génère des chemins AIR_ROUTE répétés de longueur bornée (1 à 6), conserve uniquement
//ceux dont les distances des relations sont strictement croissantes grâce à allReduce, et profile l’exécution 
//pour mesurer le coût tout en limitant le nombre de chemins retournés en 500.
CYPHER 25
PROFILE
MATCH REPEATABLE ELEMENTS
p =((x)-[rs:AIR_ROUTE]->(y)){1,6}
WHERE allReduce(
  acc = [true, -1],
  r IN rs |
    CASE
      WHEN acc[0] = false THEN acc
      WHEN r.distance > acc[1]
        THEN [true, r.distance]
      ELSE
        [false, acc[1]]
    END,
  acc[0]
)
RETURN p
LIMIT 500;


//REQUETE 2
// Cette requête Cypher 25 génère des chemins de vols (FROM–FLIGHT–TO) de longueur bornée (2 à 5), conserve 
//uniquement ceux dont les heures d’arrivée UTC sont constantes le long du chemin via allReduce, et profile 
//l’exécution afin d’évaluer le coût tout en limitant le nombre de résultats 500.
CYPHER 25
PROFILE
MATCH REPEATABLE ELEMENTS
p = ((:AIRPORT)<-[:FROM]-(f:FLIGHT)-[t:TO]->(:AIRPORT)){2,5}

WHERE allReduce(
  acc = [true, NULL],
  r IN t |
    CASE
      WHEN acc[1] IS NULL
        THEN [true, r.arr_time_utc]
      WHEN r.arr_time_utc = acc[1]
        THEN acc
      ELSE
        [false, acc[1]]
    END,
  acc[0]
)

RETURN p
LIMIT 500;

//REQUETE 3
// Cette requête Cypher 25 génère des chemins de vols (FROM–FLIGHT–TO) entre deux aéroports avec 1 à 3 segments, 
//calcule la durée totale de vol via allReduce, ne conserve que les chemins dont le temps de vol cumulé dépasse
// 180 minutes, et profile l’exécution tout en limitant le nombre de résultats retournés 500.
CYPHER 25
PROFILE
MATCH REPEATABLE ELEMENTS
p =
  (a:AIRPORT)
  ((:AIRPORT)<-[:FROM]-(f:FLIGHT)-[:TO]->(:AIRPORT)){1,3}
  (b:AIRPORT)

WHERE allReduce(
  total = 0,
  x IN f |
    total + x.air_time,
  total > 180
)

RETURN p
LIMIT 500;


//REQUETE 4
// Cette requête Cypher 25 calcule et profile un des plus courts chemins non pondérés possibles (ANY SHORTEST) 
//entre les aéroports YUM et ABE sur le graphe AIR_ROUTE, avec une longueur bornée entre 1 et 10 relations et 
//retourne le chemin ainsi que sa longueur en nombre de segments.
PROFILE
CYPHER 25 MATCH REPEATABLE ELEMENTS p = ANY SHORTEST 
  (a:AIRPORT{faa:"YUM"})-[:AIR_ROUTE*1..6]->(b:AIRPORT{faa:"ABE"})
RETURN p, length(p) AS long;

//REQUETE 5
// Cette requête Cypher 25 génère des chemins AIR_ROUTE pondérés de longueur bornée (1 à 6) entre YUM et ABE, 
//calcule le coût total de chaque chemin par agrégation des distances, puis profile l’exécution pour retourner 
//le chemin de coût minimal.
CYPHER 25 
PROFILE
MATCH REPEATABLE ELEMENTS p = (a:AIRPORT {faa:"YUM"})-[:AIR_ROUTE*1..6]->(b:AIRPORT {faa:"ABE"})
WITH p,
     reduce(cost = 0, r IN relationships(p) | cost + r.distance) AS totalCost
RETURN p, totalCost
ORDER BY totalCost
LIMIT 1;


//REQUETE 6
// requête retournant un voyage en 4 vols de New-York (La Guardia) à Los Angeles
// en respectant certaines contraintes
CYPHER 25 runtime=parallel
MATCH 
path = (origin:AIRPORT {faa : "LGA"} )
       ((:AIRPORT)<-[:FROM]-(fts:FLIGHT)-[:TO]->(a:AIRPORT)){4}
       (:AIRPORT {faa : "LAX"} )

WHERE allReduce(
  // t[0] = validité cumulative
  // t[1] = dernière arrivée
  // t[2] = dep =  départ du vol courant 
  // t[3] = arr = arrivée du vol courant
  // t[4] = liste des codes faa des aéroports déjà visités 
  // t[5] = code faa de l'aéroport d'arrivée du vol courant (en format liste) 
  t = [true, datetime('1970-01-01T00:00:00'),  datetime('1970-02-01T00:00:00'),  datetime('1970-03-01T00:00:00'),[],[]],

  f IN fts |

    CASE
      // chemin déjà invalide
      WHEN t[0] = false THEN t
      ELSE
        [ t[0],
          t[3],
	  // calculer une seule fois dep et arr à partir des relations
          head([(f)-[r:FROM]->() | r.dep_time_utc]),
          head([(f)-[r:TO]->()   | r.arr_time_utc]),
	  //mise à jour de la liste des aéroports déjà visités
	  t[4]+t[5],
	  //aéroport courant
	  [(f)-[:TO]-(p:AIRPORT) | p.faa]
        ]
    END,

  // prédicat inline pour vérifier la fenêtre et la chronologie 
  t[0] AND
  t[1] IS NOT NULL AND
  t[2] IS NOT NULL AND
  t[3] IS NOT NULL AND
  t[1] < t[2] AND
  ( t[1] = datetime('1970-03-01T00:00:00') OR
    (t[1] + duration({days:3}) <= t[2] AND
     t[2] <= t[1] + duration({days:5}))
  ) AND
  //vérifie que l'aéroport courant jamais visité
  NOT t[5][0] IN t[4]
)

RETURN [origin.name]+[aero in a | aero.name] AS aeroports, path
LIMIT 1

//REQUETE 7
CYPHER 25 runtime=parallel
MATCH 
path = (origin:AIRPORT {faa : "LGA"} )
       ((:AIRPORT)<-[:FROM]-(fts:FLIGHT)-[:TO]->(a:AIRPORT)){4}
       (:AIRPORT {faa : "LAX"} )

WHERE allReduce(
  // t[0] = validité cumulative
  // t[1] = dernière arrivée
  // t[2] = dep =  départ du vol courant 
  // t[3] = arr = arrivée du vol courant
  // t[4] = liste des codes faa des aéroports déjà visités 
  // t[5] = code faa de l'aéroport d'arrivée du vol courant (en format liste) 
  t = [true, datetime('1970-01-01T00:00:00'),  datetime('1970-02-01T00:00:00'),
      	     datetime('1970-03-01T00:00:00'),[],[]],

  f IN fts |

    CASE
      // chemin déjà invalide
      WHEN t[0] = false THEN t
      ELSE
        [ t[0],
          t[3],
	  // les deux lignes suivantes différentes de la 1ère requête Cypher 25
          f.dep_time_utc,
          f.arr_time_utc,
	  //mise à jour de la liste des aéroports déjà visités
	  t[4]+t[5],
	  //ligne suivante différente de la 1ère requête Cypher 25
	  [f.dest_faa]
        ]
    END,

  // prédicat inline pour vérifier la fenêtre et la chronologie 
  t[0] AND
  t[1] IS NOT NULL AND
  t[2] IS NOT NULL AND
  t[3] IS NOT NULL AND
  t[1] < t[2] AND
  ( t[1] = datetime('1970-03-01T00:00:00') OR
    (t[1] + duration({days:3}) <= t[2] AND
     t[2] <= t[1] + duration({days:5}))
  ) AND
  //vérifie que l'aéroport courant jamais visité
  NOT t[5][0] IN t[4]
)

RETURN [origin.name]+[aero in a | aero.name] AS aeroports, path
LIMIT 1


//REQUETE 8
CYPHER 25
MATCH path = SHORTEST 1 (s:AIRPORT {faa: "LAX"})-[:AIR_ROUTE*..4]->(n:AIRPORT WHERE NOT n.faa = "LAX")
WITH n AS airport, length(path) AS depth
ORDER BY depth
RETURN ["LAX"]+collect(airport.faa)