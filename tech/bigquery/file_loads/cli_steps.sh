export LOCATION=europe-west2
# see this for locations: https://cloud.google.com/bigquery/docs/locations

# create a dataset
bq --location=$LOCATION mk --dataset \
    --default_table_expiration 7200 \
    --description "Tables for different file types" \
    files

# load a simple table
bq load \
--source_format=CSV \
--autodetect \
files.boston \
boston.csv
