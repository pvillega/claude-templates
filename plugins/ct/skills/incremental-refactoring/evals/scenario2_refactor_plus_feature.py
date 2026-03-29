"""User authentication and session management."""
from datetime import datetime, timedelta
from hashlib import sha256
import secrets


class AuthManager:
    def __init__(self, db, config):
        self.db = db
        self.config = config
        self.session_store = {}

    def login(self, username: str, password: str) -> dict:
        user = self.db.find_user(username)
        if not user:
            return {"success": False, "error": "Invalid credentials"}

        hashed = sha256(password.encode()).hexdigest()
        if hashed != user["password_hash"]:
            # Track failed attempts
            attempts = user.get("failed_attempts", 0) + 1
            self.db.update_user(user["id"], {"failed_attempts": attempts})
            if attempts >= 5:
                self.db.update_user(user["id"], {"locked": True, "locked_at": datetime.now().isoformat()})
                return {"success": False, "error": "Account locked"}
            return {"success": False, "error": "Invalid credentials"}

        # Reset failed attempts on successful login
        self.db.update_user(user["id"], {"failed_attempts": 0, "last_login": datetime.now().isoformat()})

        # Create session
        token = secrets.token_hex(32)
        self.session_store[token] = {
            "user_id": user["id"],
            "username": username,
            "created_at": datetime.now(),
            "expires_at": datetime.now() + timedelta(hours=self.config.get("session_hours", 24)),
            "ip": None,
            "user_agent": None
        }

        return {"success": True, "token": token, "user_id": user["id"]}

    def validate_session(self, token: str) -> dict:
        session = self.session_store.get(token)
        if not session:
            return {"valid": False, "error": "Session not found"}
        if datetime.now() > session["expires_at"]:
            del self.session_store[token]
            return {"valid": False, "error": "Session expired"}
        return {"valid": True, "user_id": session["user_id"], "username": session["username"]}

    def logout(self, token: str) -> bool:
        if token in self.session_store:
            del self.session_store[token]
            return True
        return False

    def change_password(self, user_id: str, old_password: str, new_password: str) -> dict:
        user = self.db.find_user_by_id(user_id)
        if not user:
            return {"success": False, "error": "User not found"}

        old_hash = sha256(old_password.encode()).hexdigest()
        if old_hash != user["password_hash"]:
            return {"success": False, "error": "Current password incorrect"}

        if len(new_password) < 8:
            return {"success": False, "error": "Password must be at least 8 characters"}

        new_hash = sha256(new_password.encode()).hexdigest()
        self.db.update_user(user_id, {"password_hash": new_hash})

        # Invalidate all sessions for this user
        tokens_to_remove = [
            t for t, s in self.session_store.items()
            if s["user_id"] == user_id
        ]
        for t in tokens_to_remove:
            del self.session_store[t]

        return {"success": True}
