import datetime
import hashlib
import os
import re
from uuid import uuid4

import matplotlib.pyplot as plt
import pandas as pd
import pandavro
import seaborn as sns
from google.cloud import bigquery, storage
from google.cloud.exceptions import Conflict
from sklearn import datasets

# setup globals
FOLDER = "data"
PROJECT_NAME = "medium-279206"
BUCKET_NAME = f"yetanothertestbucket-{hashlib.sha1(PROJECT_NAME.encode()).hexdigest()}"
LOCATION = "europe-west2"
DATASET_NAME = "loadbench"

# create a random dataset
def make_int(x: int) -> int:
    return int(x * 100_000)


def make_datetime(x: int) -> datetime.datetime:
    return datetime.datetime.fromtimestamp(abs(make_int(x)))


def make_string(x: int) -> str:
    return hashlib.sha1(str(x).encode()).hexdigest()


def make_char(x: int) -> str:
    return chr(97 + (make_int(x) % 26))


def col_name_formatter(x: int) -> str:
    return f"col_{x:04d}"


def make_random_dataset(
    rows: int,
    float_cols: int = 1,
    int_cols: int = 1,
    datetime_cols: int = 1,
    string_cols: int = 1,
    char_cols: int = 1,
) -> pd.DataFrame:

    functions = [
        lambda x: x,
        make_int,
        make_datetime,
        make_string,
        make_char,
    ]

    quantities = [
        float_cols,
        int_cols,
        datetime_cols,
        string_cols,
        char_cols,
    ]

    total_columns = sum(quantities)

    X, _ = datasets.make_regression(
        n_samples=rows, n_features=total_columns
    )

    df = pd.DataFrame(
        X,
        columns=[
            col_name_formatter(i)
            for i in range(total_columns)
        ],
    )

    start_index = 0

    for fn, quantity in zip(functions, quantities):
        if quantity == 0:
            continue

        end_index = start_index + quantity
        df.iloc[:, start_index:end_index] = df.iloc[
            :, start_index:end_index
        ].applymap(fn)
        start_index = end_index

    return df


# make a small and a large dataset
df = make_random_dataset(5000, 50, 50, 50, 50, 50)
large_df = pd.concat((df for _ in range(10)))

# save files to a folder
os.makedirs(FOLDER, exist_ok=True)

save_functions = {
    "csv": lambda df, fname: df.to_csv(
        f"{FOLDER}/CSV_{df.shape[0]}_{fname}.csv",
        index=False,
    ),
    "gzip": lambda df, fname: df.to_csv(
        f"{FOLDER}/GZIP_{df.shape[0]}_{fname}.csv.gzip",
        index=False,
        compression="gzip",
    ),
    "parquet": lambda df, fname: df.to_parquet(
        f"{FOLDER}/PARQUET_{df.shape[0]}_{fname}.parquet",
        index=False,
    ),
    "avro": lambda df, fname: pandavro.to_avro(
        f"{FOLDER}/AVRO_{df.shape[0]}_{fname}.avro", df
    ),
}

for save_function in save_functions.values():
    for fname, data in zip(
        ("small", "large"), (df, large_df)
    ):
        save_function(data, fname)


# compare file sizes
file_pattern = r"CSV|GZIP|PARQUET|AVRO"
row_pattern = r"\d+"
file_names = [
    f"{FOLDER}/{f}"
    for f in os.listdir(FOLDER)
    if re.search(file_pattern, f)
]

file_info = []

file_size_mb = lambda fname: os.path.getsize(fname) / (
    2 ** 20
)

for fname in file_names:
    size = file_size_mb(fname)
    extension = re.search(file_pattern, fname).group()
    rows = int(re.search(row_pattern, fname).group())
    size = file_size_mb(fname)

    file_info.append(
        {
            "fname": fname,
            "extension": extension,
            "rows": rows,
            "size": size,
        }
    )


# plot the sizes
plt.rcParams["figure.figsize"] = (10, 8)
sns.set_style("whitegrid")
ax = sns.barplot(
    x="extension",
    y="size",
    hue="rows",
    data=pd.DataFrame(file_info),
)
ax.set(xlabel="File Type", ylabel="Size in MBs")
plt.title("File sizes for different formats")
plt.savefig(
    "tech/biquery/benchmarks/file_sizes.png", dpi=120
)

# parquet has more overhead but when it comes to
# larger sizes, it provices better compression, especially
# for repeated values


# copy the files to GC
gs_client = storage.Client(project=PROJECT_NAME)
bq_client = bigquery.Client(project=PROJECT_NAME)


try:
    gs_client.create_bucket(
        BUCKET_NAME, location=LOCATION, project=PROJECT_NAME
    )
except Conflict:
    print("Bucket already exists.")

# this is faster and more convenient
os.system(
    f"gsutil -m rsync -R {FOLDER} gs://{BUCKET_NAME}/{FOLDER}/"
)

# create a dataset
bq_client.create_dataset(
    DATASET_NAME,
    exists_ok=True,
    timeout=600,  # expire after 1hr
)


def benchmark(
    blob_name,
    job_config,
    repeat=1,
    duplicate=1,
    bucket_name=BUCKET_NAME,
    dataset_name=DATASET_NAME,
    storage_client=gs_client,
    bigquery_client=bq_client,
):

    bucket = gs_client.get_bucket(bucket_name)
    from_blob = bucket.get_blob(blob_name)

    # copy the files
    new_path = f"{uuid4().hex}_{blob_name}"

    for i in range(duplicate):
        new_name = f"{new_path}/{blob_name}_{i:05d}"
        bucket.copy_blob(
            from_blob,
            bucket,
            new_name=new_name,
            client=gs_client,
        )

    jobs = []

    for i in range(repeat):
        table_name = add_prefix(f"{i:05d}")
        table_ref = bq_client.dataset(dataset_name).table(
            table_name
        )
        job = bq_client.load_table_from_uri(
            f"gs://{BUCKET_NAME}/{new_path}/*",
            table_ref,
            job_config=job_config,
        )
        jobs.append(job)

    load_times = []
    for job in jobs:
        job.result()
        seconds_difference = (
            job.ended - job.started
        ).total_seconds()
        load_times.append(seconds_difference)

    return load_times


# create configs
config_csv = bigquery.LoadJobConfig()
config_csv.source_format = bigquery.SourceFormat.CSV
config_csv.skip_leading_rows = 1
config_csv.autodetect = True

config_gzip = bigquery.LoadJobConfig()
config_gzip.source_format = bigquery.SourceFormat.CSV
config_gzip.skip_leading_rows = 1
config_gzip.autodetect = True
config_gzip.compression = "GZIP"

config_avro = bigquery.LoadJobConfig()
config_avro.source_format = bigquery.SourceFormat.AVRO

config_parquet = bigquery.LoadJobConfig()
config_parquet.source_format = bigquery.SourceFormat.PARQUET

CONFIGS = {
    "CSV": config_csv,
    "GZIP": config_gzip,
    "AVRO": config_avro,
    "PARQUET": config_parquet,
}


# benchmark small files
small_loads = []

for file in file_info:
    # skip the larger files
    if file["rows"] != 5000:
        continue

    config = CONFIGS[file["extension"]]
    load_times = benchmark(file["fname"], config, repeat=10)

    new_info = file.copy()
    new_info["load_times"] = load_times
    small_loads.append(new_info)



df_small_loads = pd.DataFrame(small_loads).explode(
    "load_times"
)
df_small_loads["extension"] = pd.Categorical(
    df_small_loads.extension
)

ax = sns.boxplot(
    x="load_times", y="extension", data=df_small_loads
)
ax.set(xlabel="Load times in seconds", ylabel="File format")
plt.title("Load times for small files (5k rows)")
plt.savefig(
    "tech/biquery/benchmarks/loads_small_files.png", dpi=120
)
plt.show()


# factor out benchmarking settings
def collect_load_times(
    filter_key, filter_value, files=file_info, **kwargs
):
    load_infos = []

    for file in files:
        if file[filter_key] != filter_value:
            continue

        config = CONFIGS[file["extension"]]
        load_times = benchmark(
            file["fname"], config, repeat=10, **kwargs
        )

        new_info = file.copy()
        new_info["load_times"] = load_times
        load_infos.append(new_info)

    return load_infos


large_loads = collect_load_times("rows", 50000)

df_large_loads = pd.DataFrame(large_loads).explode(
    "load_times"
)
df_large_loads["extension"] = pd.Categorical(
    df_large_loads.extension
)

ax = sns.boxplot(
    x="load_times", y="extension", data=df_large_loads
)
ax.set(xlabel="Load times in seconds", ylabel="File format")
plt.title("Load times for large files (50k rows)")
plt.savefig(
    "tech/biquery/benchmarks/loads_large_files.png", dpi=120
)
plt.show()


large_loads_multiple = collect_load_times(
    "rows", 50000, duplicate=10
)

df_large_loads_multiple = pd.DataFrame(
    large_loads_multiple
).explode("load_times")
# to keep colours the same
df_large_loads_multiple["extension"] = pd.Categorical(
    df_large_loads_multiple.extension
)

ax = sns.boxplot(
    x="load_times",
    y="extension",
    data=df_large_loads_multiple,
)
ax.set(xlabel="Load times in seconds", ylabel="File format")
plt.title(
    "Load times for multiple large files (10 * 50k rows)"
)
plt.savefig(
    "tech/biquery/benchmarks/loads_large_multiple_files.png",
    dpi=120,
)
plt.show()

# for the first time this yielded ~140s for parquet files for each 10 repetition???
# not sure what was going on

# one more time with 20 duplicates
largest_loads_multiple = collect_load_times(
    "rows", 50000, duplicate=20
)

df_largest_loads_multiple = pd.DataFrame(
    largest_loads_multiple
).explode("load_times")
# to keep colours the same
df_largest_loads_multiple["extension"] = pd.Categorical(
    df_largest_loads_multiple.extension
)

ax = sns.boxplot(
    x="load_times",
    y="extension",
    data=df_largest_loads_multiple,
)
ax.set(xlabel="Load times in seconds", ylabel="File format")
plt.title("Load times for many large files (20 * 50k rows)")
plt.savefig(
    "tech/biquery/benchmarks/loads_large_many_files.png",
    dpi=120,
)
plt.show()


# delete bucket
bucket = gs_client.get_bucket(BUCKET_NAME)
for blob in bucket.list_blobs():
    blob.delete()
bucket.delete()

# why this is not the same syntax, is beyond me...
bq_client.delete_dataset(
    DATASET_NAME, delete_contents=True, not_found_ok=True
)
