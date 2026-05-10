import sqlite3
import threading
import uuid
from pathlib import Path

DB_PATH = Path("/home/developer/free-will/data/app.db")

_local = threading.local()


def get_conn() -> sqlite3.Connection:
    if not hasattr(_local, "conn"):
        DB_PATH.parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(str(DB_PATH), check_same_thread=False)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA foreign_keys=ON")
        _local.conn = conn
    return _local.conn


def init_db() -> None:
    conn = get_conn()
    conn.executescript("""
        CREATE TABLE IF NOT EXISTS conversations (
            id          TEXT PRIMARY KEY,
            title       TEXT NOT NULL,
            created_at  TEXT NOT NULL,
            updated_at  TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS messages (
            id                  TEXT PRIMARY KEY,
            conversation_id     TEXT NOT NULL,
            role                TEXT NOT NULL,
            content             TEXT NOT NULL,
            created_at          TEXT NOT NULL,
            FOREIGN KEY (conversation_id) REFERENCES conversations(id)
        );

        CREATE TABLE IF NOT EXISTS habit_log (
            date        TEXT NOT NULL,
            habit       TEXT NOT NULL,
            completed   INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY (date, habit)
        );

        CREATE TABLE IF NOT EXISTS settings (
            key     TEXT PRIMARY KEY,
            value   TEXT NOT NULL
        );
    """)
    conn.commit()


def get_or_create_api_key() -> str:
    conn = get_conn()
    row = conn.execute("SELECT value FROM settings WHERE key='api_key'").fetchone()
    if row:
        return row["value"]

    key = str(uuid.uuid4())
    conn.execute("INSERT INTO settings (key, value) VALUES ('api_key', ?)", (key,))
    conn.commit()
    print(f"\n{'='*50}")
    print(f"  iOS API KEY: {key}")
    print(f"  Paste this into the iOS app Settings screen.")
    print(f"{'='*50}\n")
    return key
