package ADAMK::Role::Changes;

# A role to integrate with Module::Changes::ADAMK

use 5.008;
use strict;
use warnings;
use Module::Changes::ADAMK ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}

sub changes_file {
	$_[0]->file('Changes');
}

sub changes {
	my $self = shift;
	my $file = $self->changes_file;
	unless ( -f $file ) {
		my $name = $self->name;
		die("Changes file '$file' in '$name' does not exist");
	}
	Module::Changes::ADAMK->read($file);
}

1;
