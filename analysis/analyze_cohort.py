import pandas as pd
import matplotlib.pyplot as plt
from matplotlib_venn import venn3

df = pd.read_csv("../data/insomnia_cohort.csv")
print("Cohort loaded:", df.shape)
print(df.head())

print("Number of insomnia_flag")
print(df['insomnia_flag'].value_counts(dropna=False))

print("\nAverage age by insomnia status:")
print(df.groupby('insomnia_flag')['anchor_age'].mean())

print("\nGender breakdown:")
print(df.groupby(['insomnia_flag', 'gender']).size().unstack(fill_value=0))

# Simple demographics plots
plt.figure(figsize=(6,4))
df['gender'].value_counts().plot(kind='bar', color=['steelblue','salmon'])
plt.title("Gender Distribution")
plt.show()

plt.figure(figsize=(6,4))
df[df['insomnia_flag']==1]['anchor_age'].plot(kind='hist', bins=30, alpha=0.6, color='salmon', label='Insomnia')
df[df['insomnia_flag']==0]['anchor_age'].plot(kind='hist', bins=30, alpha=0.6, color='steelblue', label='No Insomnia')
plt.title("Age Distribution: Insomnia vs Non-Insomnia")
plt.legend()
plt.xlabel("Age")
plt.show()


# Rule overlap visualization (A, B, C)
ruleA = set(df[df['ruleA'] == 1]['subject_id'])
ruleB = set(df[df['ruleB'] == 1]['subject_id'])
ruleC = set(df[df['ruleC'] == 1]['subject_id'])

plt.figure(figsize=(6,6))
venn3(
    subsets=(ruleA, ruleB, ruleC),
    set_labels=('Rule A (ICD)', 'Rule B (Primary drugs)', 'Rule C (Secondary drugs)')
)
plt.title("Overlap of Insomnia Rules")
plt.show()