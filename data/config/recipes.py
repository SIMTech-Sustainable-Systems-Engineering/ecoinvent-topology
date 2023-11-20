# This script converts the JSON file to a CSV file
##Import the necessary libraries
import pandas as pd
import json
import pathlib
import os
import timeit
import sys

##Setting working directory
path = pathlib.Path(__file__).parent.resolve()
os.chdir(path)
print("Working directory:", path)

##Construct the file path
file_path = os.path.join(path, "recipes.json")
"""Read the JSON file"""
with open(file_path) as file:
    data = json.load(file)

##Convert JSON data to DataFrame
headers = ["country/area", "recipe type", "json"]
df = pd.DataFrame(data, columns=headers)

##Normalize the 'json_column'
normalized_df = pd.concat(
    [df.drop(["json"], axis=1), pd.json_normalize(df["json"])], axis=1
)

##Save DataFrame as CSV
normalized_df.to_csv("recipes.csv", index=False)
