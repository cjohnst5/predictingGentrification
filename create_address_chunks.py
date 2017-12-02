import pandas as pd
import numpy as np
import matplotlib
import sys 
import os
import math

df = pd.read_csv("permit_addresses.csv")

rows = df.shape[0]
iters = math.floor(rows/1000)

if not os.path.exists("./address_chunks"):
    os.makedirs("./address_chunks")

for i in range(iters):
	df_chunk = df.loc[i*1000:(i + 1)*1000 - 1]
	df_chunk.to_csv("./address_chunks/addresses{}.csv".format(i), index=False, header=False)

extra = rows % 1000
df_chunk = df.loc[-extra:]
df_chunk.to_csv("./address_chunks/addresses{}.csv".format(i+1), index=False, header=False)
