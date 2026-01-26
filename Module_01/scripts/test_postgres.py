from sqlalchemy import create_engine, text

engine = create_engine(
    "postgresql://root:root@localhost:5432/ny_taxi"
    )

# This script connects to a PostgreSQL database and executes a simple query to test the connection.
with engine.connect() as conn:
    result = conn.execute(text("SELECT 1"))
    print(result.scalar())
