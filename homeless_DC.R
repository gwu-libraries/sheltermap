#install.packages('leaflet')
#install.packages('ggmap')
#install.packages('opencage')
#install.packages('sf')
#install.packages('tigris')

library(leaflet)
library(ggmap)
library(opencage)
library(sf)
library(tidyverse)
library(tigris)

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

shelters$type <- factor(c('Type1', 'Type2'))

# sheltermap <- leaflet(data=shelters) %>%
#   addTiles() %>%
#   addMarkers(lng=~Long,
#              lat=~Lat, popup=~Name)
# 
# sheltermap


# Got DC census tracts shapefile from  https://opendata.dc.gov/datasets/6969dd63c5cb4d6aa32f15effb8311f3_8/data


race_by_tract <- read.csv('data/race_by_tract.csv', colClasses = c('factor', 'numeric'))
# dctracts <- merge(dctracts, race_by_tract, by='TRACT')



# Get census tract shape data

dctracts <- tracts(state = "DC")

# For now, randomly assign African-American % values
dctracts@data$aapct <- 100*runif(nrow(dctracts))

sheltercolor <- c("red", "orange")[shelters$type]
icons <- awesomeIcons(
   icon = 'ios-close',
   iconColor = 'black',
   library = 'ion',
   markerColor = sheltercolor
)

# Color palette
pal <- colorNumeric(
   palette = "Blues",
   domain = dctracts@data$aapct, 10)

leaflet(data = dctracts) %>%
   addTiles() %>% # Add background map
   addPolygons(popup = ~NAME, weight=2, fillColor = ~pal(aapct), fillOpacity = 0.6) %>%
   addAwesomeMarkers(data=shelters, lng=~Long,
              lat=~Lat, popup=~Name, icon=icons) %>%
   addLegend("topright", pal = pal, values = ~aapct,
             title = "Percent of some Variable",
             opacity = 1) %>%
   addLegend("bottomright", 
             colors= levels(factor(sheltercolor)),
             labels= levels(shelters$type),
             title= "Shelter Type",
             opacity = 1)



