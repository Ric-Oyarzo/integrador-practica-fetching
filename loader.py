from dotenv import load_dotenv
import os
from pathlib import Path
import psycopg
from psycopg.rows import dict_row

load_dotenv()

db_url = os.environ["DATABASE_URL"]


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