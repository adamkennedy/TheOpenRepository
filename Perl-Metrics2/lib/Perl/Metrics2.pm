package Perl::Metrics2;

use 5.008005;
use strict;
use Carp                   ();
use DBI                    ();
use File::Spec             ();
use File::Find::Rule       ();
use File::Find::Rule::Perl ();
use PPI::Util              ();
use Module::Pluggable;

our $VERSION = '0.01';

use constant ORLITE_FILE => File::Spec->catfile(
	File::HomeDir->my_data,
	($^O eq 'MSWin32' ? 'Perl' : '.perl'),
	'Perl-Metrics2',
	'Perl-Metrics2.sqlite',
);

use constant ORLITE_TIMELINE => File::Spec->catdir(
	File::ShareDir::dist_dir('Perl-Metrics2'),
	'timeline',
);

use ORLite 1.20 ();
use ORLite::Migrate 0.02 {
	file         => ORLITE_FILE,
	create       => 1,
	timeline     => ORLITE_TIMELINE,
	user_version => 1,
};





#####################################################################
# Main Methods

sub process_file {
	my $class = shift;

	# Get and check the filename
	my $path = File::Spec->canonpath(shift);
	unless ( defined $path and ! ref $path and $path ne '' ) {
		Carp::croak("Did not pass a file name to index_file");
	}
	unless ( File::Spec->file_name_is_absolute($path) ) {
		Carp::croak("Cannot index relative path '$path'. Must be absolute");
	}
	Carp::croak("Cannot index '$path'. File does not exist") unless -f $path;
	Carp::croak("Cannot index '$path'. No read permissions") unless -r _;

	# At this point we know we'll need to go to the expense of
	# generating the MD5hex value.
	my $md5hex = PPI::Util::md5hex_file( $path );
	unless ( $md5 ) {
		Carp::croak("Failed to generate md5 for '$path'");
	}

	

	# Create the plugin objects
	foreach my $plugin ( $class->plugins ) {
		$class->_trace("STARTING PLUGIN $plugin...\n");
		eval "require $plugin";
		die $@ if $@;
		$plugin->new->process_document(
			
		);
	}
}





#####################################################################
# Support Methods

sub _trace {
	my $class = shift;
	return 1 unless $TRACE;
	print @_;
}

1;
