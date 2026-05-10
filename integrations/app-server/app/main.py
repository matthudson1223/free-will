from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from .claude import get_system_prompt
from .db import get_or_create_api_key, init_db
from .routers import chat, conversations, files, goals, habits, health, journal


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_db()
    get_or_create_api_key()
    get_system_prompt()  # pre-load and cache CLAUDE.md
    yield


app = FastAPI(title="free-will", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(chat.router)
app.include_router(conversations.router)
app.include_router(journal.router)
app.include_router(habits.router)
app.include_router(goals.router)
app.include_router(files.router)
