#! perl

use warnings;
use strict;
use XML::WiX3::Classes::Fragment;

print XML::WiX3::Classes::Fragment->new(id => 'TestID')->as_string();
