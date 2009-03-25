#!/usr/bin/perl

use strict;
use File::Spec ();
use lib File::Spec->rel2abs(
	File::Spec->catdir(
		File::Spec->updir,
		File::Spec->updir,
		File::Spec->updir,
		File::Spec->updir,
		File::Spec->updir,
	)
);
use Padre::DB::Patch;





#####################################################################
# Patch Content

# Create the META.yml columns
do('alter table dist_weight add column meta1 integer not null default 0');
do('alter table dist_weight add column meta2 integer not null default 0');
do('alter table dist_weight add column meta3 integer not null default 0');

exit(0);
