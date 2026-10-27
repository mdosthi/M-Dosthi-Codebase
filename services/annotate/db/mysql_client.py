import os
from typing import Any, Optional, Sequence

import pymysql
import pymysql.cursors

MYSQL_HOST     = os.getenv("MYSQL_HOST",     "localhost")
MYSQL_PORT     = int(os.getenv("MYSQL_PORT", "3306"))
MYSQL_USER     = os.getenv("MYSQL_USER",     "root")
MYSQL_PASSWORD = os.getenv("MYSQL_PASSWORD", "")
MYSQL_DATABASE = os.getenv("MYSQL_DATABASE", "annotate")


class MySQLClient:
    """Thin wrapper around a single pymysql connection with lazy connect + auto-reconnect."""

    def __init__(self) -> None:
        self._conn: Optional[pymysql.Connection] = None

    def _connect(self) -> None:
        self._conn = pymysql.connect(
            host=MYSQL_HOST,
            port=MYSQL_PORT,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            database=MYSQL_DATABASE,
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=True,
        )

    def _ensure(self) -> None:
        if self._conn is None or not self._conn.open:
            self._connect()

    def execute(self, sql: str, args: Sequence[Any] = ()) -> None:
        self._ensure()
        with self._conn.cursor() as cur:  # type: ignore[union-attr]
            cur.execute(sql, args)

    def close(self) -> None:
        if self._conn and self._conn.open:
            self._conn.close()
