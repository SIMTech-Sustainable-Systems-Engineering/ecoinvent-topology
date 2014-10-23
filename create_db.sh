#!/bin/bash
echo "Creating database and tables"
psql -U ecoinvent -d template1 -c "DROP DATABASE eigeo;" -q -n -o create_db.log
psql -U ecoinvent -d template1 -c "CREATE DATABASE eigeo WITH OWNER = ecoinvent ENCODING = 'UTF8';" -q -n -o create_db.log
psql -U ecoinvent -d template1 -c "ALTER DATABASE eigeo SET search_path = public, topology;" -q -n -o create_db.log
psql -U ecoinvent -d eigeo -c "CREATE EXTENSION postgis;" -q -n -o create_db.log
psql -U ecoinvent -d eigeo -c "CREATE EXTENSION postgis_topology;" -q -n -o create_db.log
psql -U ecoinvent -d eigeo -c "SELECT CreateTopology('ei_topo', 4326);" -q -n -o create_db.log
psql -U ecoinvent -d eigeo -f sql/create-tables.sql -q -n -o create_db.log

echo "Importing raw GIS country/province/state data"
psql -U ecoinvent -d eigeo -f sql/ne_countries.sql -q -n -o create_db.log
psql -U ecoinvent -d eigeo -f sql/ne_states.sql -q -n -o create_db.log
psql -U ecoinvent -d eigeo -f sql/ne_provinces.sql -q -n -o create_db.log

echo "Fix problem with one province self-intersecting ring"
psql -U ecoinvent -d eigeo -c "update ne_provinces set geom = ST_MakeValid(geom) where ST_IsValid(geom) = False;"

echo "Creating province topos"
echo "This will take some time; An error will be raised for Paphos - it can be ignored"
psql -U ecoinvent -d eigeo c "SELECT AddTopoGeometry(name, 'ne_provinces', gid) FROM ne_provinces ORDER BY name;" -q -n -o create_db.log
echo "Creating country topos"
psql -U ecoinvent -d eigeo -c "SELECT AddTopoGeometry(name, 'ne_countries', gid) FROM ne_countries ORDER BY name;" -q -n -o create_db.log
echo "Creating sovereign state topos"
psql -U ecoinvent -d eigeo -c "SELECT AddTopoGeometry(name, 'ne_states', gid) FROM ne_states ORDER BY name;" -q -n -o create_db.log

echo "Getting and processing cutout geometries"
echo "SPP"
ogr2ogr -f PGDump sql/cutouts/spp.sql data/intermediate/spp.gpkg -lco CREATE_TABLE=OFF -lco SRID=4326 -lco GEOMETRY_NAME=geom -lco DIM=2
sed -i '' 's/"public"."spp"/"public"."cutouts"/g' sql/cutouts/spp.sql
ogr2ogr -f PGDump sql/cutouts/spp_texas.sql data/intermediate/spp_texas.gpkg -lco CREATE_TABLE=OFF -lco SRID=4326 -lco GEOMETRY_NAME=geom -lco DIM=2
sed -i '' 's/"public"."spp_texas"/"public"."cutouts"/g' sql/cutouts/spp_texas.sql
sed -i '' 's/Southwest Power Pool/SPP (Texas)/g' sql/cutouts/spp_texas.sql
psql -U ecoinvent -d eigeo -f sql/cutouts/spp.sql -q -n -o create_db.log
psql -U ecoinvent -d eigeo -f sql/cutouts/spp_texas.sql -q -n -o create_db.log

echo "SERC"
ogr2ogr -f PGDump sql/cutouts/serc.sql data/intermediate/serc.gpkg -lco CREATE_TABLE=OFF -lco SRID=4326 -lco GEOMETRY_NAME=geom -lco DIM=2
sed -i '' 's/"public"."serc"/"public"."cutouts"/g' sql/cutouts/serc.sql
psql -U ecoinvent -d eigeo -f sql/cutouts/serc.sql -q -n -o create_db.log

echo "Midwest (MRO)"
ogr2ogr -f PGDump sql/cutouts/mro.sql data/intermediate/mro.gpkg -lco CREATE_TABLE=OFF -lco SRID=4326 -lco GEOMETRY_NAME=geom -lco DIM=2
sed -i '' 's/"public"."mro"/"public"."cutouts"/g' sql/cutouts/mro.sql
psql -U ecoinvent -d eigeo -f sql/cutouts/mro.sql -q -n -o create_db.log

ogr2ogr -f PGDump sql/cutouts/mro_ill.sql data/intermediate/mro_ill.gpkg -lco CREATE_TABLE=OFF -lco SRID=4326 -lco GEOMETRY_NAME=geom -lco DIM=2
sed -i '' 's/"public"."mro_ill"/"public"."cutouts"/g' sql/cutouts/mro_ill.sql
sed -i '' 's/Midwest Reliability Organization/MRO (Illinois)/g' sql/cutouts/mro_ill.sql
psql -U ecoinvent -d eigeo -f sql/cutouts/mro_ill.sql -q -n -o create_db.log

echo "Western"
ogr2ogr -f PGDump sql/cutouts/wecc_texas.sql data/intermediate/wecc_texas.gpkg -lco CREATE_TABLE=OFF -lco SRID=4326 -lco GEOMETRY_NAME=geom -lco DIM=2
sed -i '' 's/"public"."wecc_texas"/"public"."cutouts"/g' sql/cutouts/wecc_texas.sql
sed -i '' 's/Midwest Reliability Organization/MRO (Illinois)/g' sql/cutouts/mro_ill.sql
psql -U ecoinvent -d eigeo -f sql/cutouts/wecc_texas.sql -q -n -o create_db.log

echo "ReliabilityFirst"
ogr2ogr -f PGDump sql/cutouts/rfc.sql data/intermediate/rfc.gpkg -lco CREATE_TABLE=OFF -lco SRID=4326 -lco GEOMETRY_NAME=geom -lco DIM=2
sed -i '' 's/"public"."rfc"/"public"."cutouts"/g' sql/cutouts/rfc.sql
psql -U ecoinvent -d eigeo -f sql/cutouts/rfc.sql -q -n -o create_db.log

echo "Alaska"
ogr2ogr -f PGDump sql/cutouts/ascc.sql data/intermediate/ascc.gpkg -lco CREATE_TABLE=OFF -lco SRID=4326 -lco GEOMETRY_NAME=geom -lco DIM=2
sed -i '' 's/"public"."ascc"/"public"."cutouts"/g' sql/cutouts/ascc.sql
psql -U ecoinvent -d eigeo -f sql/cutouts/ascc.sql -q -n -o create_db.log

echo "Adding cutout topologies"
psql -U ecoinvent -d eigeo -f sql/cutouts/process-cutouts.sql -q -n -o create_db.log

echo "Eliminating duplicate nodes"
python python/eliminate_nodes.py