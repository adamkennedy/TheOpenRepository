package Perl::Dist::WiX::Asset::Website;

use Moose;
use MooseX::Types::Moose qw( Str Int Maybe ); 

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

with 'Perl::Dist::WiX::Role::Asset';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => 'get_name',
	required => 1,
);

has url => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_url',
	required => 1,
);

has icon_file => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_icon_file',
	default  => undef,
);

has icon_index => (
	is       => 'ro',
	isa      => Maybe[Int],
	reader   => '_get_icon_index',
	lazy     => 1,
	default  => sub { defined shift->get_icon_file() ? 1 : undef;},
);

sub install {
	my $self    = shift;

	my $name = $self->get_name();
	my $filename = catfile( $self->_get_image_dir, 'win32', "$name.url" );

	my $website;
	# Use exceptions instead of dieing.
	open $website, q{>}, $filename  or die "open($filename): $!";
	print $website $self->content() or die "print($filename): $!";
	close $website                  or die "close($filename): $!";

	# Add the file.
	$self->add_file(
		source   => $filename,
		fragment => 'Win32Extras'
	);

	my $icon_id = $self->_get_icons()->add_icon( $self->_get_icon_file(), $filename );

	# Add the icon.
	$self->add_icon(
		name     => $name,
		filename => $filename,
		fragment => 'Icons',
		icon_id  => $icon_id,
	);

	return $filename;
} ## end sub install_website

sub _content {
	my $self    = shift;
	
	my @content = "[InternetShortcut]\n";
	push @content, "URL=" . $self->_get_url();
	my $file = $self->_get_icon_file();
	if ( defined $file ) {
		push @content, "IconFile=" . $file;
	}
	my $index = $self->_get_icon_index();
	if ( defined $index ) {
		push @content, "IconIndex=" . $index;
	}
	return join '', map { "$_\n" } @content;
}

1;
