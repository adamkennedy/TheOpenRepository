#!perl
use strict;
use warnings;
use lib qw/./;

use File::Copy::Recursive qw/rcopy/;
use File::Path qw/mkpath rmtree/;
use File::Basename qw/dirname/;
use File::Spec::Functions qw/catdir catfile tmpdir /;
use IPC::Run3;
use Perl6::Say;
use YAML::Syck;

# Load configurations
my $cfg = LoadFile( "vanilla.yml" );
my $extras = $cfg->{extra}; # Hash
my $image_dir = $cfg->{image_dir};

# recursively copy in any extras (e.g. CPAN\Config.pm starter)
if ( ref $extras eq 'HASH' ) {
    for my $f ( keys %$extras ) {
        my $from = $f;
        my $to = catfile( $image_dir, $extras->{$f} );
        my $basedir = dirname( $to );
        mkpath( $basedir );
        say "Copying $from to $to";
        rcopy( $from, $to ) or die $!;
    }
}

