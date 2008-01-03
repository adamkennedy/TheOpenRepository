package Perl::Dist::Asset::Website;

use strict;
use Carp         'croak';
use Params::Util qw{ _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.90_02';
}

use Object::Tiny qw{
	name
	url
};





#####################################################################
# Constructor

sub new {
	my $self = shift->SUPER::new(@_);

	# Check params
	unless ( _STRING($self->name) ) {
		croak("Did not provide a name");
	}
	unless ( _STRING($self->url) ) {
		croak("Did not provide a URL");
	}

	return $self;
}

sub file {
	$_[0]->name . '.url';
}

sub content {
	my $self = shift;
	return "[InternetShortcut]\n"
	     . "URL=" . $self->url . "\n";
}

sub write {
	my $self = shift;
	my $to   = shift;
	open( WEBSITE, ">$to" ) or die "open($to): $!";
	print WEBSITE $self->content;
	close WEBSITE;
	return 1;
}

1;
