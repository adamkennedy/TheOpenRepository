package Perl::Dist::Inno::File;

use strict;
use Carp         qw{ croak               };
use Params::Util qw{ _IDENTIFIER _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.29_01';
}

use Object::Tiny qw{
	source
	dest_dir
	ignore_version
	recurse_subdirs
	create_all_subdirs
	is_readme
};





#####################################################################
# Constructors

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults
	unless ( defined $self->ignore_version ) {
		$self->{ignore_version} = 1;
	}

	# Normalize params
	$self->{ignore_version}     = !! $self->ignore_version;
	$self->{recurse_subdirs}    = !! $self->recurse_subdirs;
	$self->{create_all_subdirs} = !! $self->create_all_subdirs;
	$self->{is_readme}          = !! $self->is_readme;

	# Check params
	unless ( _STRING($self->source) ) {
		croak("Missing or invalid source param");
	}
	unless ( _STRING($self->dest_dir) ) {
		croak("Missing or invalid dest_dir param");
	}

	return $self;
}





#####################################################################
# Main Methods

sub as_string {
	my $self  = shift;
	my @flags = ();
	push @flags, 'ignoreversion'    if $self->ignore_version;
	push @flags, 'recursesubdirs'   if $self->recurse_subdirs;
	push @flags, 'createallsubdirs' if $self->create_all_subdirs;
	push @flags, 'isreadme'         if $self->is_readme;
	return join( '; ',
		"Source: "  . $self->source,
		"DestDir: " . $self->dest_dir,
		(scalar @flags)
			? ("Flags: " . join(' ', @flags))
			: (),
	);
}

1;
