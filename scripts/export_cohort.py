import pandas as pd
from sqlalchemy import create_engine

engine = create_engine("postgresql+psycopg2://postgres:4030@localhost:5432/omop_sandbox")


# Define query to pull your final insomnia cohort
query = """
SELECT p.subject_id,
       p.gender,
       p.anchor_age,
       c.ruleA,
       c.ruleB,
       c.ruleC,
       c.insomnia_flag
FROM mimic_omop.patients p
LEFT JOIN mimic_omop.insomnia_cohort c
  ON p.subject_id = c.subject_id;
"""

# Load into pandas DataFrame
df = pd.read_sql(query, engine)

print("Cohort loaded")
print(df.head())

print("Insomnia flag counts:")
print(df['insomnia_flag'].value_counts(dropna=False))

#Export to CSV
df.to_csv("../data/insomnia_cohort.csv", index=False)
print("\n💾 Saved cohort to data/insomnia_cohort.csv")