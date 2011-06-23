use strict;
use ORLite::Migrate::Patch;

# Add a station index so we can quickly select jita pricing
do('CREATE INDEX price__station_id ON price ( station_id )');
