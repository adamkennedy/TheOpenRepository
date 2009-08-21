package Perl::Dist::Asset::Website;

use Moose;
use MooseX::Types::Moose qw( Str Int Maybe ); 

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

with 'Perl::Dist::WiX::Role::Asset';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_name',
	required => 1,
);

has url => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_force',
	required => 1,
);

has icon_file => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_icon_file',
	default  => undef,
);

has icon_index => (
	is       => 'ro',
	isa      => Maybe[Int],
	reader   => 'get_icon_index',
	lazy     => 1,
	default  => sub { defined shift->get_icon_file() ? 1 : undef;},
);







sub file {
	shift->_get_name() . '.url';
}

sub content {
	my $self    = shift;
	my @content = "[InternetShortcut]\n";
	push @content, "URL=" . $self->get_url();
	if ( defined my $file = $self->get_icon_file() ) {
		push @content, "IconFile=" . $file;
	}
	if ( defined my $index = $self->get_icon_index() ) {
		push @content, "IconIndex=" . $index;
	}
	return join '', map { "$_\n" } @content;
}

sub write {
	my $self = shift;
	my $to   = shift;
	my $website;
	# Use exceptions instead of dieing.
	open $website, q{>}, $to        or die "open($to): $!";
	print $website $self->content() or die "print($to): $!";
	close $website                  or die "close($to): $!";
	return 1;
}

1;
