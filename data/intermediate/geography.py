import geopandas as gpd
import fiona
import matplotlib.pyplot as plt
import plotly.express as px
import pathlib
import os
import timeit
import sys

##Setting working directory
path = pathlib.Path(__file__).parent.resolve()
os.chdir(path)
print("Working directory:", path)

#* Replace 'your_file.gpkg' with the path to your GeoPackage file
geography_path = 'ecoinvent_geographies.gpkg'
nerc_path = 'nerc_regions.gpkg'

#* Read the GeoPackage file
geo = gpd.read_file(geography_path)
nerc = gpd.read_file(nerc_path)

#* Display the GeoDataFrame
print(geo)
print(nerc)
world = geo
#* Create a Plotly figure
fig = px.choropleth_mapbox(
    world,
    geojson=world.geometry,
    locations=world.index,
    color=world.index,
    hover_name='name',  #* Column in GeoDataFrame for hover text
    mapbox_style="carto-positron",
    center={"lat": 0, "lon": 0},
    opacity=0.5,
    zoom=1
)
#* Show the figure
fig.show()

#* Open the GeoPackage file
with fiona.open(geography_path) as src:
    #* Iterate over features in the GeoPackage
    for feature in src:
        #* Access geometry and properties
        geometry = feature['geometry']
        properties = feature['properties']

        #* Process your data as needed
        #* Note: geometry contains Z values for MultiPolygonZ

        #* Example: Print the properties and geometry type
        # print(properties)
        # print(geometry['type'])