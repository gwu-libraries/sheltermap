install.packages('leaflet')
install.packages('ggmap')
install.packages('opencage')
install.packages('sf')

library(leaflet)
library(ggmap)
library(opencage)
library(sf)

## GET ADDRESSES
#
# Prerequisite:  You'll need to sign up for an API key from https://opencagedata.com/pricing
# The free level gets you 2,500 requests per day, and 1 request per second
# Then run:
# Sys.setenv(OPENCAGE_KEY="YOUR_API_KEY_GOES_HERE")

# Put your API key in a file called apikey.txt
apikey <- as.character(read.table('apikey.txt', stringsAsFactors = FALSE))
Sys.setenv(OPENCAGE_KEY=apikey)

shelters <- read.csv('data/shelters.csv', stringsAsFactors = FALSE)

for (i in 1:nrow(shelters)) {
   shelter_location <- opencage_forward(placename = shelters$Address[i])

   # TODO: Use this value to choose the right result type, instead of just row 1
   #            shelter1_location$results['components._type']
   shelter_location <- shelter_location$results[1, ]  # For now, take the first result

   # Enhance the shelters data.frame   
   shelters$Lat[i] <- as.numeric(shelter_location['bounds.northeast.lat'])
   shelters$Long[i] <- as.numeric(shelter_location['bounds.northeast.lng'])
   
   Sys.sleep(1)  # Pause for 1 second, to respect the API's rate limiting
}

sheltermap <- leaflet(data=shelters) %>%
  addTiles() %>%
  addMarkers(lng=~Long,
             lat=~Lat, popup=~Name)

sheltermap

# Got DC census tracts shapefile from  https://opendata.dc.gov/datasets/6969dd63c5cb4d6aa32f15effb8311f3_8/data

dctracts <- st_read('data/Census_Tracts_data/Census_Tracts_in_2010.shx')

# Take a look at the shapefile
ggplot() + geom_sf(data = dctracts) + coord_sf()

  