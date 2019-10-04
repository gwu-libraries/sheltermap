library(tigris)
library(leaflet)
library(ggmap)
library(opencage)
library(sf)
library(tidyverse)
library(readxl)
library(sp)

lookup_latlong <- function(shelters) {

  ## GET ADDRESSES
  #
  # Prerequisite:  You'll need to sign up for an API key from https://opencagedata.com/pricing
  # The free level gets you 2,500 requests per day, and 1 request per second
  # Then run:
  # Sys.setenv(OPENCAGE_KEY="YOUR_API_KEY_GOES_HERE")
  
  # Put your API key in a file called apikey.txt
  apikey <- as.character(read.table('apikey.txt', stringsAsFactors = FALSE))
  Sys.setenv(OPENCAGE_KEY=apikey)
  
  colnames(shelters) <- c("name", "streetnumber", "street", "city", "state", "zip", "type", "population")
  
  # make a new variable called full_address
  shelters$full_address <- paste(shelters$streetnumber, shelters$street,
                                 shelters$city, shelters$state, shelters$zip)
  
  # make type a factor variable
  shelters$type <- factor(shelters$type)
  shelters$population <- factor(shelters$population)
  
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
    
    # get the string lat/long
    lat_dms_char <- shelter_location['annotations.DMS.lat']
    long_dms_char <- shelter_location['annotations.DMS.lng']
    
    # convert to "DMS" objects
    lat_dms <- char2dms(from=lat_dms_char, chd='°', chm="'", chs="''")
    long_dms <- char2dms(from=long_dms_char, chd='°', chm="'", chs="''")
    
    # convert to numbers
    lat_dms_num <- as.numeric(lat_dms)
    long_dms_num <- as.numeric(long_dms)
    
    shelters$Lat[i] <- lat_dms_num
    shelters$Long[i] <- long_dms_num
    
    Sys.sleep(1)  # Pause for 1 second, to respect the API's rate limiting
  }
  
  return(shelters)
}


create_map <- function(shelters_csv, tracts, census_data) {
  
  shelters <- read.csv(shelters_csv)
  
  # race_by_tract <- read.csv('data/race_by_tract.csv', colClasses = c('factor', 'numeric'))
  # dctracts <- merge(dctracts, race_by_tract, by='TRACT')
  
  ## combine crisis housing to one type 
  
  shelters[shelters$type=="Crisis Housing, Transition Housing", ]$type <- "Crisis Housing"
  shelters[shelters$type=="Crisis Housing, Transition Housing, Permt. Supportive Housing", ]$type <- "Crisis Housing"
  
  ## get rid of extra levels that are no longer needed 
  
  shelters$type <- as.character(shelters$type)
  shelters$type <- as.factor(shelters$type)
  
  # Get census tract shape data
  
  #latracts <- tracts(state = "CA", county="037")
  

  
  colnames(census_data) <- c("geography", "pct_poverty", "error") 
  
  census_data$pvt_cat <- cut(census_data$pct_poverty, c(0,10, 20, 30, 40, 100)) 
  
  
  
  for (i in 1:nrow(census_data)) {
    census_data$tract_id[i]<- substr(census_data$geography[i], 14, nchar(census_data$geography[i]))
    census_data$tract_id[i]<- strsplit(census_data$tract_id[i], ",")[[1]][[1]]
  }
  
  # For now, randomly assign African-American % values
  
  tracts@data <- merge(x=tracts@data, y=census_data, by.x = "NAME", by.y = "tract_id")
  
  
  ######## 
  # colors should match list at
  # https://www.rdocumentation.org/packages/leaflet/versions/2.0.2/topics/awesomeIcons
  sheltercolor <- c("purple", "green", "darkblue", "orange")[shelters$type]
  icons <- awesomeIcons(
    icon = 'ios-close',
    iconColor = 'black',
    library = 'ion',
    markerColor = sheltercolor
  )
  
  # Color palette
  pal_pvt <- colorFactor(
    palette = "Reds",
    domain = levels(tracts@data$pvt_cat))
  
  sheltermap <- leaflet(data=tracts) %>%
    addTiles() %>% # Add background map
    addPolygons(popup = ~NAME, weight=1, fillColor = ~pal_pvt(pvt_cat), fillOpacity = 0.6) %>%
    addAwesomeMarkers(data=shelters, lng=~Long,
                      lat=~Lat, popup=~name, icon=icons) %>%
    addLegend("topright", pal = pal_pvt, values = ~pvt_cat,
              title = "Percent Poverty",
              opacity = 1) %>%
    addLegend("bottomright",
              colors= levels(factor(sheltercolor)),
              labels= levels(shelters$type),
              title= "Shelter Type", 
              opacity = 1)
   
   return(sheltermap)
}


lashelters <- read_xlsx('data/shelter_addresses.xlsx', sheet = "LA")
lashelters_with_addresses <- lookup_latlong(lashelters)
write.csv(lashelters_with_addresses, 'data/la_shelters.csv')
###
### NOW GO FIX THE MISSING LAT/LONG BY HAND!!!
###
latracts <- tracts(state = "CA", county="037")
census_data_la <- read_xlsx('data/Census Tract Data.xlsx', sheet = "LA", na = c("-")) 
la_map <- create_map('data/la_shelters.csv', latracts, census_data_la)


lashelters <- read_xlsx('data/shelter_addresses.xlsx', sheet = "LA")
lashelters_with_addresses <- lookup_latlong(lashelters)
write.csv(lashelters_with_addresses, 'data/la_shelters.csv')
###
### NOW GO FIX THE MISSING LAT/LONG BY HAND!!!
###
latracts <- tracts(state = "CA", county="037")
census_data_la <- read_xlsx('data/Census Tract Data.xlsx', sheet = "LA", na = c("-")) 
la_map <- create_map('data/la_shelters.csv', latracts, census_data_la)


# dctracts <- tracts(state = "DC")
#sftracts
#nytracts
