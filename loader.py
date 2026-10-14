from dotenv import load_dotenv
import os
from pathlib import Path
import urllib.parse
import psycopg
from psycopg.rows import dict_row

load_dotenv()


def get_database_url() -> str:
    """Builds the PostgreSQL connection URL from component environment variables,
    falling back to DATABASE_URL if present."""
    if "DATABASE_URL" in os.environ and os.environ["DATABASE_URL"]:
        return os.environ["DATABASE_URL"]

    user = os.environ.get("PGUSER", "")
    password = urllib.parse.quote(os.environ.get("PGPASSWORD", ""), safe="")
    host = os.environ.get("PGHOST", "localhost")
    port = os.environ.get("PGPORT", "5432")
    dbname = os.environ.get("PGDATABASE", "postgres")
    sslmode = os.environ.get("PGSSLMODE", "require")

    auth = f"{user}:{password}@" if user else ""
    return f"postgresql://{auth}{host}:{port}/{dbname}?sslmode={sslmode}"


db_url = get_database_url()



def execute_sql_file(conn: psycopg.Connection, file_path: Path) -> None:
    sql_content = file_path.read_text(encoding="utf-8")
    with conn.cursor() as cur:
        cur.execute(sql_content)

def fetch_query(conn: psycopg.Connection, query: str, params: dict | None = None) -> list[dict]:
    with conn.cursor(row_factory=dict_row) as cur:
        cur.execute(query, params)
        return cur.fetchall()


with psycopg.connect(db_url) as conn:
    execute_sql_file(conn, Path("migrations/01_schema.sql"))