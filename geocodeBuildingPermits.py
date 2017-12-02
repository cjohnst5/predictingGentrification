import censusgeocode as cg
import os
import pandas as pd

if not os.path.exists("./address_chunks/results"):
    os.makedirs("./address_chunks/results")

#path = os.path.dirname(__file__) + '/../../dataRAW/texasPractice/'

directory = "./address_chunks/"

for file in os.listdir(directory):
	filename = os.fsdecode(file)
	
	geocodeResults = pd.DataFrame(cg.addressbatch(directory+filename, delim=','))
	geocodeResults.to_csv(directory+'results/R'+filename+'.csv')


	print(filename+" completed!")

