FROM openmaptiles/postgis:2.9
ENV IMPORT_DATA_DIR=/import

RUN apt-get update && apt-get install -y --no-install-recommends \
      wget \
      unzip \
      sqlite3 \
    && mkdir -p $IMPORT_DATA_DIR \
    && wget --quiet http://data.openstreetmapdata.com/water-polygons-generalized-3857.zip \
    && unzip -oj water-polygons-generalized-3857.zip -d $IMPORT_DATA_DIR \
    && rm water-polygons-generalized-3857.zip \
    && wget --quiet http://data.openstreetmapdata.com/water-polygons-complete-3857.zip \
    && unzip -oj water-polygons-complete-3857.zip -d $IMPORT_DATA_DIR \
    && rm water-polygons-complete-3857.zip \
    && ls -l $IMPORT_DATA_DIR \
    && apt-get -y --auto-remove purge \
      wget \
      unzip \
      sqlite3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/app
COPY . /usr/src/app
CMD ["./import-water.sh"]
