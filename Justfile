set dotenv-load := true
export PATH := justfile_directory() + '/.venv/bin:' + env('PATH')
set shell := ["powershell.exe", "-c"]

# Default recipe: list available recipes
default:
    @just --list

# Run dbt commands (e.g. `just dbt debug`, `just dbt run`, `just dbt test`)
dbt *args="debug":
    exec dbt {{args}} --project-dir dbt --profiles-dir dbt

# Run the database schema loader / migration
load:
    .venv/bin/python loader.py


fetch:
    python fetcher.py
