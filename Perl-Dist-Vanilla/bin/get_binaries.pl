#!perl
use strict;
use warnings;
use lib qw/./;

use File::Copy qw/copy/;
use File::Path qw/mkpath rmtree/;
use File::Basename qw/dirname/;
use File::pushd;
use File::Spec::Functions qw/catdir catfile tmpdir /;
use Perl6::Say;
use Util qw/mirror_url extract_whole extract_filemap init_dir/;
use YAML::Syck;

# Load configurations
my $cfg = LoadFile( "vanilla.yml" );
my $binaries = $cfg->{binary}; # AOH
my $download_dir = $cfg->{download_dir};
my $image_dir = $cfg->{image_dir};

if ( -d $image_dir ) {
    say "Removing existing $image_dir";
    rmtree( $image_dir );
}

say "Creating $image_dir";
init_dir( $image_dir );

for my $d ( $download_dir, $image_dir ) {
    -d $d or mkpath( $d ) 
        or die "Couldn't create $d";
}

for my $binary ( @$binaries ) {
    my $name = $binary->{name};
    say "Preparing $name";
    
    # downloading
    my $tgz = mirror_url( $binary->{url}, catdir( $download_dir, $name ) );
    
    # unpacking
    my $install_to = $binary->{install_to} || q{};
    if ( ref $install_to eq 'HASH' ) {
        extract_filemap( $tgz, $install_to, $image_dir );
    }
    elsif ( ! ref $install_to ) {
        # unpack as a whole
        my $tgt = catdir( $image_dir, $install_to );
        extract_whole( $tgz => $tgt );
    }
    else {
        die "didn't expect install_to to be a " . ref $install_to;
    }
    
    # finding licenses
    if ( ref $binary->{license} eq 'HASH' )   {
        my $license_dir = catdir( $image_dir, 'licenses' );
        extract_filemap( $tgz, $binary->{license}, $license_dir, 1 );
    }
    
    # copy in any extras (e.g. CPAN\Config.pm starter)
    if ( my $extras = $binary->{extra} ) {
        for my $f ( keys %$extras ) {
            my $from = $f;
            my $to = catfile( $image_dir, $extras->{$f} );
            my $basedir = dirname( $to );
            mkpath( $basedir );
            say "Copying $from to $to";
            copy( $from, $to ) or die $!;
        }
    }
}
    




