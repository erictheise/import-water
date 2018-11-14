#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

function exec_psql() {
    PGPASSWORD=$POSTGRES_PASSWORD psql --host="$POSTGRES_HOST" --port="$POSTGRES_PORT" --dbname="$POSTGRES_DB" --username="$POSTGRES_USER"
}

function import_shp() {
    local shp_file=$1
    local table_name=$2
    shp2pgsql -s 3857 -I -g geometry "$shp_file" "$table_name" | exec_psql | hide_inserts
}

function hide_inserts() {
    grep -v "INSERT 0 1"
}

function drop_table() {
    local table=$1
    local drop_command="DROP TABLE IF EXISTS $table CASCADE;"
    echo "$drop_command" | exec_psql
}

function generalize_water() {
    local target_table_name="$1"
    local source_table_name="$2"
    local tolerance="$3"
    echo "Generalize $target_table_name with tolerance $tolerance from $source_table_name"
    echo "CREATE TABLE $target_table_name AS SELECT ST_Simplify(geometry, $tolerance) AS geometry FROM $source_table_name" | exec_psql
    echo "CREATE INDEX ON $target_table_name USING gist (geometry)" | exec_psql
    echo "ANALYZE $target_table_name" | exec_psql
}

function import_water() {
  echo "Importing OpenStreetMapData water polygons to PostGIS"
  for shapefile in $IMPORT_DATA_DIR/*.shp; do
    [ -e "$shapefile" ] || continue
    local file_name=${shapefile##*/}
    local table_name=osmd_${file_name%.*}
    echo "shapefile: $shapefile filename: $file_name table: $table_name"
    drop_table "$table_name"
    echo "CREATE TABLE $table_name from $shapefile"
    import_shp "$shapefile" "$table_name"
  done
}

import_water
