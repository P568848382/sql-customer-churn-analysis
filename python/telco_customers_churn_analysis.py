import pandas as pd
from sqlalchemy import create_engine

DB_CONFIG = {
    'host': 'localhost',
    'port': 5432,
    'database': 'telco_customers_churn_analysis',
    'user': 'postgres',
    'password': '****'
}

def load_csv_to_postgres():
    try:
        connection_url = (
            f"postgresql://{DB_CONFIG['user']}:"
            f"{DB_CONFIG['password']}@"
            f"{DB_CONFIG['host']}:"
            f"{DB_CONFIG['port']}/"
            f"{DB_CONFIG['database']}"
        )

        engine = create_engine(connection_url)

        file_path = r'J:\python\DA_project\SQL Projects\WA_Fn-UseC_-Telco-Customer-Churn.csv'

        print(f"Reading file: {file_path}")

        df = pd.read_csv(file_path)

        table_name = 'telco_churn'

        print(f"Uploading data to table: {table_name}")

        df.to_sql(
            table_name,
            engine,
            if_exists='replace',
            index=False
        )

        print("Success! Data loaded into PostgreSQL.")

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    load_csv_to_postgres()