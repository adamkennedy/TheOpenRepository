package Perl::Dist::WiX::Fragment::StartMenu;

#####################################################################
# Perl::Dist::WiX::Fragment::StartMenu - A <Fragment> and <DirectoryRef> tag that
# contains <Icon> elements.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See WiX.pm for details.
#
use 5.008001;
use Moose;
use MooseX::Types::Moose qw( Str );
use WiX3::Exceptions;
use Perl::Dist::WiX::IconArray;

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

extends 'WiX3::XML::Fragment';

has icons => (
	is => 'ro',
	isa	=> 'Perl::Dist::WiX::IconArray',
	default => sub { return Perl::Dist::WiX::IconArray->new() },
	reader => 'get_icons',
);

has directory_id => (
	is => 'ro',
	isa	=> Str,
	required => 1,
	reader => 'get_directory_id',
);


sub BUILDARGS {
	my $class = shift;
	my %args;
	
	if ( @_ == 1 && 'HASH' ne ref $_[0] ) {
		$args{'id'} = $_[0];
	} elsif ( 0 == @_ ) {
		$args{'id'} = 'Icons';
	} elsif ( @_ == 1 && 'HASH' eq ref $_[0] ) {
		%args = %{$_[0]};
	} elsif ( 0 == @_ % 2 ) {
		%args = ( @_ );
	} else {
		print "Error situation 1\n";
		# TODO: Throw an error.
	}
	
	if (not exists $args{'id'}) {
		$args{'id'} = 'Icons';
	}

	return \%args;
}

# This type of fragment needs regeneration.
sub regenerate {
	WiX3::Exception::Unimplemented->throw();

	return;
}



1;