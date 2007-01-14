package Mirror::YAML::URI;

use strict;
use URI          ();
use Params::Util qw{ _STRING _INSTANCE };
use LWP::Simple  ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}





#####################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	unless ( _INSTANCE($self->uri, 'URI') ) {
		return undef;
	}
	return $self;
}

sub uri {
	$_[0]->{uri};
}

sub yaml {
	$_[0]->{yaml};
}

sub lag {
	$_[0]->{lag};
}

sub age {
	$_[0]->{age} = shift if @_;
	$_[0]->{age};
}





#####################################################################
# Main Methods

sub get {
	my $self      = shift;
	my $uri       = URI->new('mirror.yaml')->abs( $self->uri );
	my $before    = Time::HiRes::time();
	$self->{yaml} = LWP::Simple::get($uri)) or return undef;
	$self->{lag}  = Time::HiRes::time() - $before;
	return 1;
}

1;
