#!/usr/bin/python

import sys

GeoIP2Reader = None
from geoip2.database import Reader as GeoIP2Reader

#import geoip2.database

# This creates a Reader object. You should use the same object
# across multiple requests as creation of it is expensive.
#reader = geoip2.database.Reader('GeoLite2-Country.mmdb')
#http://geolite.maxmind.com/download/geoip/database/GeoLite2-City.tar.gz
reader = GeoIP2Reader('/home/pau/bin/GeoLite2-City.mmdb')

# Replace "city" with the method corresponding to the database
# that you are using, e.g., "country".
#response = reader.city('8.8.8.8')
response = reader.city(sys.argv[1])
#print response.country.iso_code
#print "["+response.country.iso_code+"] "+response.country.name+" ("+response.continent.name+")"
print u' '.join(("[",str(response.country.iso_code),"]",str(response.country.name),"(",str(response.continent.name),")")).encode('utf-8').strip()
#print response.registered_country.name
#print response.represented_country.name
#print response.city.name
#print response.city.geoname_id
#print response.maxmind
#print response.traits
#print response.continent.name
#print response.postal.code
#print response.location.latitude
#print response.location.longitude
#print response.subdivisions.most_specific.name  #          <---- Barcelona, tarragona, lleida, girona
#print response.subdivisions.most_specific.iso_code
reader.close()
