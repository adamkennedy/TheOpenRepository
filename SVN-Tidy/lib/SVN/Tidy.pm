package SVN::Tidy;

use 5.005;
use strict;
use Config;
use Carp                   ();
use Cwd                    ();
use FindBin                ();
use File::Spec::Functions  ':ALL';
use File::Basename         ();
use File::pushd            ();
use File::Which            ();
use File::Find::Rule       ();
use File::Find::Rule::VCS  ();
use File::Find::Rule::Perl ();
use File::Remove           ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Check params
	unless ( defined $self->dir and -d $self->dir ) {
		Carp::croak("Missing or invalid 'dir' param");
	}

	return $self;
}

sub dir {
	$_[0]->{dir};
}

sub trace {
	$_[0]->{trace};
}

sub print {
	my ($self, $msg) = @_;
	if ( $self->trace ) {
		CORE::print $msg;
	}
	return 1;
}




#####################################################################
# Action Methods

sub run
	my $self = shift;

	# Find the Perl files
	
	
}

sub 





#####################################################################
# Support Methods

sub _FFR {
	File::Find::Rule->new->ignore_svn;
}

1;
