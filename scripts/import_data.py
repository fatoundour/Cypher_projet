from nycflights13 import flights, airports, airlines
import pandas as pd

#traitement airports

a_df = airports.loc[:,["faa","name","lat","lon","tzone"]] # les colonnes conservées de airports
##une Series "tzone" avec pour index "faa" (but: utilisation dans la partie #traitement flights)
a_tzone = airports[["faa", "tzone"]].set_index("faa")["tzone"]

print(f"Nombre d'aéroports: {len(a_df)}")

#traitement flights

f_df = flights.loc[flights["month"] == 6,:].copy() #données du mois de juin 2013
f_df["flight"] = f_df["flight"].astype(str) #numéro de vol converti en str
f_df["dep_time"] = f_df["dep_time"].astype("Int64") #int sous forme (H)HMM
f_df["dep_delay"] = f_df["dep_delay"].astype("Int64") ## nombre de minutes
f_df["arr_time"] = f_df["arr_time"].astype("Int64") #int sous forme (H)HMM
f_df["arr_delay"] = f_df["arr_delay"].astype("Int64") ## nombre de minutes
f_df["air_time"] = f_df["air_time"].astype("Int64") ## nombre de minutes
f_df["distance"] = f_df["distance"].astype("Int64") ## distance (en miles)


## Ajout des vols venant de BTS (vols en 2013 sur le mois de juin)
### Provenance des données: https://www.transtats.bts.gov/DL_SelectFields.aspx?gnoyr_VQ=FGJ&QO_fu146_anzr=b0-gvzr

df = pd.read_csv("data/T_ONTIME_REPORTING.csv")
new_names = {
    "YEAR": "year",           
    "MONTH": "month",
    "DAY_OF_MONTH": "day",
    "OP_UNIQUE_CARRIER": "carrier",
    "OP_CARRIER_FL_NUM": "flight",
    "ORIGIN": "origin",
    "DEST": "dest",
    "CRS_DEP_TIME": "sched_dep_time",
    "DEP_TIME": "dep_time",
    "DEP_DELAY": "dep_delay",
    "CRS_ARR_TIME": "sched_arr_time",
    "ARR_TIME": "arr_time",
    "ARR_DELAY": "arr_delay",
    "AIR_TIME": "air_time",
    "DISTANCE":  "distance" #en miles
}

df = df.rename(columns=new_names)

df["flight"] = df["flight"].astype(str) #numéro de vol converti en str
df["dep_time"] = df["dep_time"].astype("Int64") #int sous forme (H)HMM
df["dep_delay"] = df["dep_delay"].astype("Int64") ## nombre de minutes
df["arr_time"] = df["arr_time"].astype("Int64") #int sous forme (H)HMM
df["arr_delay"] = df["arr_delay"].astype("Int64") ## nombre de minutes
df["air_time"] = df["air_time"].astype("Int64") ## nombre de minutes
df["distance"] = df["distance"].astype("Int64") ## distance (en miles)

## Sélectionne les attributs-colonne de df bien présentes dans f_df
df_same_columns = df[f_df.columns.intersection(df.columns)]

## Ajoute les lignes de  df_same_columns à f_df
f_df = pd.concat([f_df, df_same_columns], ignore_index=True)


## fonction utilitaire qui change l'int HHMM en couple d'ints (HH,MM)
def hhmm_to_hour_min(x):
    if pd.isna(x):
        return None, None
    h = x // 100
    m = x % 100
    if h == 24 :
        h = 0
    return h, m

##pour construire le temps utc de l'heure de départ prévue pour chaque ligne
def build_dep_time_utc(row):
    hour, minute = hhmm_to_hour_min(row["dep_time"])
    if hour is None:
        return pd.NaT

    tzone = a_tzone.get(row["origin"])
    if pd.isna(tzone):
        return pd.NaT

    local_dt = pd.Timestamp(
        year=row["year"],
        month=row["month"],
        day=row["day"],
        hour=hour,
        minute=minute,
        tz=tzone
    )
    return local_dt.tz_convert("UTC")


##pour construire le temps utc de l'heure de d'arrivée pour chaque ligne
def build_arr_time_utc(row):
    hour, minute = hhmm_to_hour_min(row["arr_time"])
    if hour is None or pd.isna(row["air_time"]):
        return pd.NaT

    tzone = a_tzone.get(row["dest"]) #retourne (si existe) la valeur tzone à l'index row["dest"]
    if pd.isna(tzone):
        return pd.NaT

    # On vérifie que départ UTC existe 
    if pd.isna(row["dep_time_utc"]):
        return pd.NaT

    # heure d'arrivée en UTC en rajoutant à l'heure de départ le temps de vol
    return row["dep_time_utc"] + pd.to_timedelta(row["air_time"], unit="m")

### Remarque : on ne connait pas les année, mois et jour d'arrivée du vol mais
### seulement ceux de départ, ce qui nécessite d'approximer l'heure d'arrivée
### en ajoutant à l'heure de départ le temps approximatif du vol, mais ce calcul
### peut possiblement, si on convertit cette heure en heure locale de l'aéroport
### d'arrivée, donner un temps différent de l'heure dans la colonne "arr_time"


## conversion des heures en UTC 
f_df["dep_time_utc"] = f_df.apply(build_dep_time_utc, axis=1)
f_df["sched_dep_time_utc"] = f_df["dep_time_utc"] - pd.to_timedelta(f_df["dep_delay"], unit="m")
f_df["arr_time_utc"] = f_df.apply(build_arr_time_utc, axis=1)
f_df["sched_arr_time_utc"] = f_df["arr_time_utc"] - pd.to_timedelta(f_df["arr_delay"], unit="m")

## suppression des colonnes inutiles
del f_df['dep_time']
del f_df['sched_dep_time']
del f_df['arr_time']
del f_df['sched_arr_time']

##création de l'identifiant des vols
f_df["id"] = (
    f_df["year"].astype(str).str.zfill(2) + "_" +
    f_df["month"].astype(str).str.zfill(2) + "_" +
    f_df["day"].astype(str).str.zfill(2) + "_" +
    f_df["carrier"].astype(str) + "_" +
    f_df["flight"].astype(str) + "_" +
    f_df["origin"].astype(str) + "_" +
    f_df["dest"].astype(str) 
)


## Sélection finale des colonnes (ordre propre)
f_df = f_df[
    [
        "id",
        "origin",
        "dest",
        "carrier",
        "flight",
        "distance",
        "air_time",
        "dep_delay",
        "arr_delay",
        "sched_dep_time_utc",
        "dep_time_utc",
        "sched_arr_time_utc",
        "arr_time_utc",
        "year",
        "month",    
        "day"
    ]
]


## Dernières modifications
f_df = f_df.dropna() # on ne garde pas les lignes avec au moins une valeur NA
f_df = f_df.drop_duplicates(subset="id") #on ne garde qu'une ligne par valeur de la colonne "id"

print(f"Nombre de vols gardés: {len(f_df)}")


#traitement airlines

c_df = airlines.copy() # c_df conserve toutes les colonnes de airlines ("carrier" et "name")

print(f"Nombre de compagnies aériennes: {len(c_df)}")


# Export CSV pour Neo4j

# Vols (relations FLIGHT)
f_df.to_csv("data/flights_cleaned.csv", index=False)

# Aéroports (nœuds Airport)
a_df.to_csv("data/airports_cleaned.csv", index=False)

# Compagnies aériennes (nœuds Airline)
c_df.to_csv("data/airlines_cleaned.csv", index=False) 

# CSV pour flight (SQL)
flights_sql = f_df[
    [
        "id",
        "origin",
        "dest",
        "carrier",
        "flight",
        "air_time",
        "dep_delay",
        "arr_delay",
        "sched_dep_time_utc",
        "dep_time_utc",
        "sched_arr_time_utc",
        "arr_time_utc"
    ]
]

flights_sql.to_csv("data/flights_sql.csv", index=False)

# CSV pour table sql airport_route

airport_route_sql = f_df[
    [
        "origin",
        "dest",
        "distance"
    ]
]

#  Suppression des doublons
airport_route_sql = airport_route_sql.drop_duplicates(
    subset=["origin", "dest"]
)

airport_route_sql.to_csv("data/airport_route_sql.csv", index=False)

