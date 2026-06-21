
// Projection GDS du graphe AIRPORT–AIR_ROUTE avec pondération par distance
CALL gds.graph.project(
  'airGraph',
  'AIRPORT',
  {
    AIR_ROUTE: {
      type: 'AIR_ROUTE',
      orientation: 'NATURAL',
      properties: 'distance'
    }
  }
);


//REQUETE 1
// Cette requête lance et profile un parcours BFS ciblé avec GDS depuis l’aéroport YUM vers l’aéroport ABE, 
//s’arrête dès que la destination est atteinte, et retourne l’ordre des nœuds visités ainsi que la longueur du 
//chemin trouvé.
PROFILE
MATCH (a:AIRPORT {faa:"YUM"}), (b:AIRPORT {faa:"ABE"})
WITH a, [b] AS targetNodes
CALL gds.bfs.stream(
  'airGraph',{ 
  sourceNode: a,
  targetNodes : targetNodes
})
YIELD sourceNode, nodeIds, path
RETURN
  gds.util.asNode(sourceNode).faa AS source,
  [id IN nodeIds | gds.util.asNode(id).faa] AS visited,
  length(path) AS pathLength;


//REQUETE 2
// Cette requête lance et profile un parcours DFS ciblé avec GDS depuis l’aéroport YUM vers l’aéroport ABE, 
//explore le graphe en profondeur jusqu’à atteindre la destination, et retourne l’ordre des nœuds visités ainsi
// que la longueur du chemin trouvé.
PROFILE
MATCH (a:AIRPORT {faa:"YUM"}), (b:AIRPORT {faa:"ABE"})
WITH a, [b] AS targetNodes
CALL gds.dfs.stream(
  'airGraph',{ 
  sourceNode: a,
  targetNodes : targetNodes
})
YIELD sourceNode, nodeIds, path
RETURN
  gds.util.asNode(sourceNode).faa AS source,
  [id IN nodeIds | gds.util.asNode(id).faa] AS visited,
  length(path) AS pathLength;


//REQUETE 3
// Cette requête lance et profile l’algorithme de Dijkstra via GDS afin de calculer le plus court chemin 
//pondéré (selon la distance) entre les aéroports YUM et ABE, et retourne le coût total ainsi que le chemin 
//optimal.
PROFILE
MATCH (a:AIRPORT {faa:"YUM"}), (b:AIRPORT {faa:"ABE"})
CALL gds.shortestPath.dijkstra.stream(
  'airGraph',
  {
    sourceNode: a,
    targetNode: b,
    relationshipWeightProperty: 'distance'
  }
)
YIELD totalCost, nodeIds
RETURN
  totalCost,
  [id IN nodeIds | gds.util.asNode(id).faa] AS path;


//REQUETE 4
CYPHER 25

//projection dans un graphe nommé myGraph
CALL gds.graph.project(
  'myGraph',
  'AIRPORT',
  'AIR_ROUTE'
);

//BFS depuis l'aéroport de Los Angeles
MATCH (s:AIRPORT {faa: "LAX"})
CALL gds.bfs.stream('myGraph', {
  sourceNode: s
})
YIELD path
//résultat dans une liste des codes faa de chaque aéroport
RETURN [n IN nodes(path) | n.faa]