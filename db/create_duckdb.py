import duckdb

con = duckdb.connect("db/unit-1-5.db")

con.sql(
    """
    CREATE TABLE address AS SELECT * FROM read_csv_auto('db/address.csv', HEADER=TRUE);
    CREATE TABLE car AS SELECT * FROM read_csv_auto('db/car.csv', HEADER=TRUE);
    CREATE TABLE claim AS SELECT * FROM read_csv_auto('db/claim.csv', HEADER=TRUE);
    CREATE TABLE client AS SELECT * FROM read_csv_auto('db/client.csv', HEADER=TRUE);
    """
)
con.sql("SELECT * FROM client LIMIT 5;")
