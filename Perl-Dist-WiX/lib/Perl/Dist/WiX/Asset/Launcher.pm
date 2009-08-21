package Perl::Dist::WiX:Asset::Launcher;

use Moose;
use MooseX::Types::Moose qw( Str ); 
use File::Spec::Functions qw( catfile );
use Perl::Dist::WiX::Exceptions;

our $VERSION = '1.100';
$VERSION = eval { return $VERSION };

with 'Perl::Dist::WiX::Role::Asset';

has name => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_name',
	required => 1,
);

has bin => (
	is       => 'ro',
	isa      => Str,
	reader   => '_get_bin',
	required => 1,
);

sub install {
	my $self     = shift;

	my $bin = $self->_get_bin();
	
	# Check the script exists
	my $to =
	  catfile( $self->_get_image_dir(), 'perl', 'bin', $bin . '.bat' );
	unless ( -f $to ) {
		PDWiX->throw(
			qq{The script "$bin" does not exist} );
	}

	my $icon_id = $self->_get_icons()->add_icon(
		catfile( $self->_get_dist_dir(), "$bin.ico" ),
		"$bin.bat" );

	# Add the icon.
	$self->_add_icon(
		name     => $self->get_name(),
		filename => $to,
		fragment => 'Icons',
		icon_id  => $icon_id
	);

	return 1;
} ## end sub install_launcher


1;
