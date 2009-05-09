#! perl

use warnings;
use strict;
use XML::WiX3::Classes::CreateFolder;

print XML::WiX3::Classes::CreateFolder->new()->as_string();
