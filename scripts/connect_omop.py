import os
import pandas as pd
from sqlalchemy import create_engine

#Connect to databse
engine = create_engine("postgresql+psycopg2://postgres:4030@localhost:5432/omop_sandbox")


folder_path = r"C:\mimic_data"
schema_name = "mimic_omop"

#Loop through CSV files
for file in os.listdir(folder_path):
    if file.endswith(".csv"):
        table_name = os.path.splitext(file)[0].lower()  
        file_path = os.path.join(folder_path, file)
        print(f"Importing {file_path} → table {schema_name}.{table_name}")

        # Read CSV 
        df = pd.read_csv(file_path)

        # Load into PostgreSQL
        df.to_sql(table_name, engine, schema=schema_name, if_exists="replace", index=False)
        print(f"Imported {len(df):,} rows into {schema_name}.{table_name}\n")

print("All files imported successfully!")
