#install.packages('leaflet')
#install.packages('ggmap')
#install.packages('opencage')
#install.packages('sf')
#install.packages('tigris')
#install.packaages('readxl')


library(leaflet)
library(ggmap)
library(opencage)
library(sf)
library(tidyverse)
library(tigris)
library(readxl)


## GET ADDRESSES
#
# Prerequisite:  You'll need to sign up for an API key from https://opencagedata.com/pricing
# The free level gets you 2,500 requests per day, and 1 request per second
# Then run:
# Sys.setenv(OPENCAGE_KEY="YOUR_API_KEY_GOES_HERE")

# Put your API key in a file called apikey.txt
apikey <- as.character(read.table('apikey.txt', stringsAsFactors = FALSE))
Sys.setenv(OPENCAGE_KEY=apikey)

shelters <- read_xlsx('data/GIS_NIMBY.xlsx')
colnames(shelters) <- c("name", "streetnumber", "street", "city", "state", "zip", "numbeds", "numhouseholds", "type", "pop", "dv", "vet", "aidshiv")

# make a new variable called full_address
shelters$full_address <- paste(shelters$streetnumber, shelters$street,
                               shelters$city, shelters$state, shelters$zip)

# make type a factor variable
shelters$type <- factor(shelters$type)

# To fix row 12, change this to 12:12
#for (i in 1:1) {
for (i in 1:nrow(shelters)) {
   
   # To get these right at the console, do it like this:
   # opencage_forward(placename = "45150 60th Street West, Lancaster, CA 93536")
   
   shelter_location <- opencage_forward(placename = shelters$full_address[i])

   # TODO: Use this value to choose the right result type, instead of just row 1
   #            shelter1_location$results['components._type']
   shelter_location <- shelter_location$results[1, ]  # For now, take the first result

   # Enhance the shelters data.frame   
   shelters$Lat[i] <- as.numeric(shelter_location['bounds.northeast.lat'])
   shelters$Long[i] <- as.numeric(shelter_location['bounds.northeast.lng'])
   
   Sys.sleep(1)  # Pause for 1 second, to respect the API's rate limiting
}

write_excel_csv(shelters, 'data/lashelters.csv')


###
### NOW GO FIX THE MISSING LAT/LONG BY HAND!!!
###

shelters <- read.csv('data/lashelters.csv')

# race_by_tract <- read.csv('data/race_by_tract.csv', colClasses = c('factor', 'numeric'))
# dctracts <- merge(dctracts, race_by_tract, by='TRACT')



# Get census tract shape data

latracts <- tracts(state = "CA", county="037")

# For now, randomly assign African-American % values
latracts@data$aapct <- 100*runif(nrow(latracts))

sheltercolor <- c("yellow", "green", "blue", "purple", "red", "orange")[shelters$type]
icons <- awesomeIcons(
   icon = 'ios-close',
   iconColor = 'black',
   library = 'ion',
   markerColor = sheltercolor
)

# Color palette
pal <- colorNumeric(
   palette = "Blues",
   domain = latracts@data$aapct, 10)

leaflet(data = latracts) %>%
   addTiles() %>% # Add background map
   addPolygons(popup = ~NAME, weight=2, fillColor = ~pal(aapct), fillOpacity = 0.6) %>%
   addAwesomeMarkers(data=shelters, lng=~Long,
              lat=~Lat, popup=~name, icon=icons) %>%
   addLegend("topright", pal = pal, values = ~aapct,
             title = "Percent AA",
             opacity = 1) %>%
   addLegend("bottomright", 
             colors= levels(factor(sheltercolor)),
             labels= levels(shelters$type),
             title= "Shelter Type",
             opacity = 1)


