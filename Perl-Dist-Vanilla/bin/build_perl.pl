#!perl
use strict;
use warnings;
use lib '.';

#--------------------------------------------------------------------------#

require CPAN;
use DDS;
use File::Basename qw/basename/;
use File::Copy qw/copy/;
use File::Find::Rule;
use File::Path qw/mkpath rmtree/;
use File::Spec::Functions qw/catdir catfile tmpdir splitpath/;
use File::pushd;
use IPC::Run3;
use Perl6::Say;
use Util qw/mirror_url extract_whole extract_filemap init_dir/;
use Tie::File;
use YAML::Syck;

#--------------------------------------------------------------------------#

# Load configurations
my $cfg = LoadFile( "vanilla.yml" );
my $sources = $cfg->{source}; # AOH
my $download_dir = $cfg->{download_dir};
my $build_dir = $cfg->{build_dir};
my $image_dir = $cfg->{image_dir};

# Make sure we have dmake in the right place
my $dmake = catfile( $image_dir, qw/dmake bin dmake.exe/ );
die "Can't execute $dmake" unless -x $dmake;

# Setup directory
init_dir( $image_dir );

# download perl
say "Building perl:";

my $perl_cfg = $sources->[0]; # perl is the only one so far

my $tgz = mirror_url( 
    $perl_cfg->{url},
    catdir( $download_dir, $perl_cfg->{name} ) 
);

my $unpack_to = catdir( $build_dir, ( $perl_cfg->{unpack_to} || q{} ) );

if ( -d $unpack_to ) {
    say "Removing previous $unpack_to";
    rmtree( $unpack_to );
}

extract_whole( $tgz => $unpack_to );

# Get the versioned name of the directory
(my $perlsrc = $tgz) =~ s{\.tar\.gz\z|\.tgz\z}{};
$perlsrc = basename($perlsrc);

# Manually patch in the Win32 friendly ExtUtils::Install
for my $f ( qw/Install.pm Installed.pm Packlist.pm/ ) {
    my $from = catfile( "extra", $f );
    my $to = catfile( $unpack_to, $perlsrc, qw/lib ExtUtils/, $f );
    say "Copying $from to $to";
    copy( $from, $to ) or die $!;
}

# finding licenses
if ( ref $perl_cfg->{license} eq 'HASH' )   {
    my $license_dir = catdir( $image_dir, 'licenses' );
    extract_filemap( $tgz, $perl_cfg->{license}, $license_dir, 1 );
}
    
# Setup fresh install directory
my $perl_install = catdir( $image_dir, $perl_cfg->{install_to} );

if ( -d $perl_install ) {
    say "Removing previous $perl_install";
    rmtree( $perl_install );
}

# Build win32 perl
{
    my $wd = pushd catdir( $unpack_to, $perlsrc , "win32" );

    tie my @makefile, 'Tie::File', 'makefile.mk'
        or die "Couldn't read makefile.mk";

    say "Patching makefile.mk";

    my (undef,$short_install) = splitpath( $perl_install, 1 );

    for (@makefile) {
        if ( m{\AINST_TOP\s+\*=\s+} ) {
            s{\\perl}{$short_install}; # short has the leading \
        }
        elsif ( m{\ACCHOME\s+\*=} ) {
            s{c:\\mingw}{$image_dir\\mingw}i;
        }
        else {
            next;
        }
    }

    untie @makefile;

    say "Building perl with $dmake";
    run3 [ $dmake ] or die "Problem building perl, stopping";

    # XXX Ugh -- tests take too long right now
    #say "Testing perl build";
    #run3 [ $dmake, "test" ] or die "Problem testing perl, stopping";

    say "Installing perl to $build_dir\\perl";
    run3 [ $dmake, "install" ] or die "Problem installing perl, stopping";
}

# copy in any extras (e.g. CPAN\Config.pm starter)
if ( my $extras = $perl_cfg->{after} ) {
    for my $f ( keys %$extras ) {
        my $from = catfile( $f );
        my $to = catfile( $perl_install, $extras->{$f} );
        say "Copying $from to $to";
        copy( $from, $to ) or die $!;
    }
}

# Should now have a perl to use
my $perl = catfile( $image_dir, qw/perl bin perl.exe/ );
die "Can't execute $perl" unless -x $perl;

say "Perl build ok!";

