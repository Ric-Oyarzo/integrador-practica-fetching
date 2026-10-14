#!/usr/bin/env bash
set -e

# Resolve repository root directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f .env ]; then
  echo "Error: .env file not found in $SCRIPT_DIR" >&2
  exit 1
fi

# Load variables from .env and ensure PGPASSWORD is safe for dbt v2's URI parser
eval "$(python3 - << 'EOF'
import os
import re
import urllib.parse
from dotenv import dotenv_values

env_vars = dotenv_values('.env')

# Export all variables from .env
for k, v in env_vars.items():
    if v is None:
        continue
    if k == 'PGPASSWORD':
        # URL-encode password so special characters like '?' don't break libpq URI in dbt v2
        encoded_pwd = urllib.parse.quote(v, safe='')
        print(f"export PGPASSWORD='{encoded_pwd}'")
    else:
        print(f"export {k}='{v}'")

# If DATABASE_URL was provided instead of components, parse it as fallback
if 'PGHOST' not in env_vars and 'DATABASE_URL' in env_vars:
    pattern = r'^(?:(?P<scheme>[^:]+)://)?(?:(?P<user>[^:]+):(?P<password>.*)@)(?P<host>[^:/]+)(?::(?P<port>\d+))?(?:/(?P<dbname>[^?]+))?'
    m = re.match(pattern, env_vars['DATABASE_URL'] or '')
    if m:
        data = m.groupdict()
        print(f"export PGHOST='{data.get('host') or ''}'")
        print(f"export PGPORT='{data.get('port') or '5432'}'")
        print(f"export PGUSER='{data.get('user') or ''}'")
        raw_pwd = data.get('password') or ''
        print(f"export PGPASSWORD='{urllib.parse.quote(raw_pwd, safe='')}'")
        print(f"export PGDATABASE='{data.get('dbname') or 'postgres'}'")
EOF
)"

# dbt v2 experimental flags & dynamic library path for libpq
export DBT_ALLOW_EXPERIMENTAL_ADAPTERS=true
export LD_LIBRARY_PATH="/home/linuxbrew/.linuxbrew/lib:${LD_LIBRARY_PATH:-}"

DEFAULT_CMD="debug"
if [ "$#" -eq 0 ]; then
  set -- "$DEFAULT_CMD"
fi

exec dbt "$@" --project-dir "$SCRIPT_DIR/dbt" --profiles-dir "$SCRIPT_DIR/dbt"
