library(leaflet)
library(ggmap)

## GET ADDRESSES
#
# Prerequisite:  You'll need to sign up for an API key from https://opencagedata.com/pricing
# The free level gets you 2,500 requests per day, and 1 request per second
# Then run:
# Sys.setenv(OPENCAGE_KEY="YOUR_API_KEY_GOES_HERE")

# DAN'S API KEY
Sys.setenv(OPENCAGE_KEY="23378af2e6bc4383b03ed022788fdfb1")

library(opencage)
shelter1_location <- opencage_forward(placename = "4713 Wisconsin Ave NW, Washington, DC")

# shelter1_location$results['annotations.DMS.lat']
# shelter1_location$results['annotations.DMS.lng']
# shelter1_location$results['components._type']

shelter1_tibble <- shelter1_location$results

Sys.sleep(1)  # Pause for 1 second, to respect the API's rate limiting