"""Load files into BigQuery.

Understand the different file types accepted by BigQuery,
their limitations and use cases.

Also run a benchmark on how long it takes to load different
file formats.
"""

import pandas as pd
from google.cloud import bigquery
from sklearn import datasets

# set some global parameters - change these for your own project
PROJECT_NAME = "medium-279206"

# load a toy dataset
data = datasets.load_boston()
boston_df = pd.DataFrame(
    data["data"], columns=data["feature_names"]
)

# save as CSV
boston_df.to_csv("boston.csv", index=False)

# upload to BigQuery
client = bigquery.Client(project=PROJECT_NAME)

table_ref = client.dataset("files").table("boston")

job_config = bigquery.LoadJobConfig()
job_config.source_format = bigquery.SourceFormat.CSV
job_config.skip_leading_rows = 1  # ignore the header
job_config.autodetect = True

with open("boston.csv", "rb") as source_file:
    job = client.load_table_from_file(
        source_file, table_ref, job_config=job_config
    )

# job is async operation so we have to wait for it to finish
job.result()


# function to upload a csv
def upload_csv(
    table_name, fname, dataset_name="files", client=client
):
    table_ref = client.dataset(dataset_name).table(
        table_name
    )

    job_config = bigquery.LoadJobConfig()
    job_config.source_format = bigquery.SourceFormat.CSV
    job_config.skip_leading_rows = 1  # ignore the header
    job_config.autodetect = True

    with open(fname, "rb") as source_file:
        job = client.load_table_from_file(
            source_file, table_ref, job_config=job_config
        )

    job.result()


# make the dataset a bit larger
boston_df = pd.concat((boston_df for _ in range(50)))

# column with floats but everything is missing until last 2 rows
boston_df["missing_numbers"] = [None] * (
    boston_df.shape[0] - 2
) + [1.3, 1.5]
boston_df.tail()

boston_df.to_csv("boston_missing.csv", index=False)

upload_csv("boston_missing", "boston_missing.csv")


# dtype of missing column is still float
boston_df.dtypes["missing_numbers"]

# but it's a string in BQ!
client.query(
    """
    SELECT
        table_schema, table_name, column_name, data_type
    FROM
        files.INFORMATION_SCHEMA.COLUMNS
    WHERE
        table_name="boston_missing"
    """
).to_dataframe()


# save a parquet file
boston_df.to_parquet("boston_missing.parquet", index=False)

# notice the lack of header skipping and schema detection parameters
table_ref = client.dataset("files").table("boston_parquet")
job_config = bigquery.LoadJobConfig()
job_config.source_format = bigquery.SourceFormat.PARQUET

with open("boston_missing.parquet", "rb") as source_file:
    job = client.load_table_from_file(
        source_file, table_ref, job_config=job_config
    )


# let's check the types again
client.query(
    """
    SELECT
        table_name, column_name, data_type
    FROM
        files.INFORMATION_SCHEMA.COLUMNS
    WHERE
        table_name in ('boston_parquet', 'boston_missing')
        and column_name = 'missing_numbers'
    """
).to_dataframe()
