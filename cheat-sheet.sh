# --- MANUAL OPERATIONS CHEAT SHEET ---

# 1. Reset Database (Wipe all data)
# Note: Container name is 'invariant_db' in your docker-compose.yml
docker exec -it invariant_db psql -U admin -d invariant -c "TRUNCATE identities CASCADE;"

# 2. Run Database Migrations (if using refinery locally)
# cargo install refinery_cli --version "0.10.0"
# refinery migrate -c postgres://admin:password@localhost:5432/invariant -p ./migrations

# 3. Start Server
cargo run -p invariant_server

# 4. Start Admin TUI
cargo run -p invariant_admin

# 5. Run Tests
cargo test -p invariant_engine
cargo test -p invariant_server