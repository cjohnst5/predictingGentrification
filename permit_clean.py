import pandas as pd
import numpy as np
import matplotlib
import sys 
#%matplotlib inline

df = pd.read_csv("Building_Permits.csv")

df['Status Date'].replace('',np.nan,inplace=True)
df.dropna(subset=['Status Date'],inplace=True)

df['Status_Y'] = df['Status Date'].str[-4:].astype(int)
df['Status_M'] = df['Status Date'].str[:2].astype(int)

df = df[df['Status_Y'] > 2000]


#df.to_csv('2000s.csv')

df_out = df
df_out['address'] = df_out['Street Number'].map(str)+' '+df_out['Street Name']+' '+df_out['Street Suffix']
df_out['city'] = 'San Francisco'
df_out['state'] = 'CA'
df_out = df_out[['Permit Number','address','city','state','Zipcode']]

df_out['address'].replace('',np.nan,inplace=True)
df_out.dropna(subset=['address'],inplace=True)

df_out.to_csv('permit_addresses.csv',index=False)
