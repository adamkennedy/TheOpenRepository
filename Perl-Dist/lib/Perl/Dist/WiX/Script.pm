package Perl::Dist::WiX::Script;

# The top level script for the WiX file for Perl::Dist

use 5.006;
use strict;
use warnings;
use Carp         qw{ croak };
use File::Spec   ();
use Params::Util qw{ _STRING _IDENTIFIER };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.05';
}

use Object::Tiny qw{
	product_id
	product_line
	product_manufacturer
	product_upgrade_code
	output_dir
	source_dir
	bin_candle
	bin_light
};

sub new {
	my $self = shift->SUPER::new(@_);

	# Apply defaults
	unless ( defined $self->output_dir ) {
		$self->{output_dir} = File::Spec->rel2abs(
			File::Spec->curdir,
		);
	}
	unless ( defined $self->default_group_name ) {
		$self->{default_group_name} = $self->product_line;
	}

	# Check and default params
	unless ( _IDENTIFIER($self->product_id) ) {
		croak("Missing or invalid product_id param");
	}
	unless ( _STRING($self->product_line) ) {
		croak("Missing or invalid product_line param");
	}
	unless ( _STRING($self->product_name) ) {
		croak("Missing or invalid product_name param");
	}
	unless ( _STRING($self->product_manufacturer) ) {
		croak("Missing or invalid product_manufacturer param");
	}
	unless ( _STRING($self->product_upgrade_code) ) {
		croak("Missing or invalid product_upgrade_code param");
	}
	unless ( _STRING($self->output_dir) ) {
		croak("Missing or invalid output_dir param");
	}
	unless ( -d $self->output_dir ) {
		croak("The output_dir " . $self->output_dir . "directory does not exist");
	}
	unless ( -w $self->output_dir ) {
		croak("The output_dir directory is not writable");
	}
	unless ( _STRING($self->output_base_filename) ) {
		croak("Missing or invalid output_base_filename");
	}
	unless ( _STRING($self->source_dir) ) {
		croak("Missing or invalid source_dir param");
	}
	unless ( -d $self->source_dir ) {
		croak("The source_dir directory does not exist");
	}

	# Set WiX component collections
	$self->{files} = [];

	# Find the WiX programs
	unless ( $ENV{PROGRAMFILES} and -d $ENV{PROGRAMFILES} ) {
		die("Failed to find the Program Files directory\n");
	}
	my $wix_dir = File::Spec->catdir( $ENV{PROGRAMFILES}, "Windows Installer XML 3" );
	unless ( -d $wix_dir ) {
		croak("Failed to find the Windows Install XML 3 directory");
	}
	unless ( defined $self->bin_candle ) {
		$self->{bin_candle} = File::Spec->catfile( $wix_dir, 'candle.exe' );
	}
	unless ( -f $self->bin_candle ) {
		croak("Missing or invalid bin_candle param");
	}
	unless ( defined $self->bin_light ) {
		$self->{bin_light} = File::Spec->catfile( $wix_dir, 'light.exe' );
	}
	unless ( -f $self->bin_light ) {
		croak("Missing or invalid bin_light param");
	}

	return $self;
}

# Default the versioned name to an unversioned name
sub product_name {
	$_[0]->{product_name} or
	$_[0]->product_line;
}

# Default the output filename to the id plus the current date
sub output_base_filename {
	my $self = shift;
	if ( $self->{output_base_filename} ) {
		return $self->{output_base_filename};
	}

	# Automated version starts with ProductLine...
	my $filename = $self->product_line;
	$filename =~ s/\s//g;

	# ... then the version ...
	$filename .= '-' . $self->product_version;

	# ... then just (for now) the date
	$filename .= '-' . $self->output_date_string;

	return $self;
}

# Convenience method
sub output_date_string {
	my @t = localtime;
	return sprintf( "%04d%02d%02d", $t[5] + 1900, $t[4] + 1, $t[3] );
}

sub files {
	return @{ $_[0]->{files} };
}

1;
