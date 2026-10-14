set dotenv-load := true
set shell := ["bash", "-c"]

export DBT_ALLOW_EXPERIMENTAL_ADAPTERS := "true"
export LD_LIBRARY_PATH := "/home/linuxbrew/.linuxbrew/lib:" + env_var_or_default("LD_LIBRARY_PATH", "")

# Default recipe: list available recipes
default:
    @just --list

# Run dbt commands (e.g. `just dbt debug`, `just dbt run`, `just dbt test`)
dbt *args="debug":
    #!/usr/bin/env bash
    # Encode '?' in password to avoid breaking dbt v2's internal URI parser
    export PGPASSWORD="${PGPASSWORD//\?/%3F}"
    exec dbt {{args}} --project-dir dbt --profiles-dir dbt

# Run the database schema loader / migration
load:
    .venv/bin/python loader.py
