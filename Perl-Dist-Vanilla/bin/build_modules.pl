#!perl
use strict;
use warnings;
use lib '.';

use YAML::Syck;
use Archive::Tar;
use File::Copy qw/copy/;
use File::Path qw/mkpath rmtree/;
use File::Spec::Functions qw/catdir catfile tmpdir/;
use File::pushd;
use File::Basename qw/basename/;
use Perl6::Say;
use Util qw/mirror_url extract_whole extract_filemap/;
use IPC::Run3;
require CPAN;

# Constants
use constant COMPRESSED => 1;

# Load configurations
my $cfg = LoadFile( "vanilla.yml" );
my $download_dir = $cfg->{download_dir};
my $build_dir = $cfg->{build_dir};
my $image_dir = $cfg->{image_dir};
my $modules = $cfg->{modules}; # AOH

# Check that we have our tools ready
my $dmake = catfile( $image_dir, qw/dmake bin dmake.exe/ );
my $perl =  catfile( $image_dir, qw/perl bin perl.exe/ );
die "Can't execute $dmake" unless -x $dmake;
die "Can't execute $perl" unless -x $perl;

# Setup a directory
my $module_dir = catdir( $download_dir, 'modules' );

# Get various cpan modules to include

my @build_queue;
my %saw_dist;

my $url_prefix = "http://search.cpan.org/CPAN/authors/id/";

for my $mod ( @$modules ) {
    my $mod_type = $mod->{type} || 'Module';
    # figure out the dist for the module
    my $mod_info = CPAN::Shell->expand( $mod_type, $mod->{name})
        or die "Couldn't expand ", $mod->{name};
    my $cpan_file = $mod_info->cpan_file();
    next if $saw_dist{ $cpan_file }++;

    # download
    my $tgz = mirror_url( $url_prefix . $cpan_file, $module_dir );

    my $dist_name = basename( $cpan_file );
    (my $extract_dir = $dist_name) =~ s{\.tar\.gz\z|\.tgz\z|\.zip\z}{};
    my ($unpack_dir, $target);

    if ( exists $mod->{unpack_to} and ref $mod->{unpack_to} eq 'HASH') {
        # individual subdirs
        say "Extracting individual files from $dist_name";
        $unpack_dir = $target = $build_dir;
        extract_filemap( $tgz, $mod->{unpack_to}, $unpack_dir );
        push @build_queue, map { [$_, $mod ] } values %{ $mod->{unpack_to} }; 
    }
    else {
        # normal
        # queue the resulting destination
        $unpack_dir = defined $mod->{unpack_to}
                    ? catdir( $build_dir, $mod->{unpack_to} )
                    : $build_dir
                    ;
        my $queue_dir = defined $mod->{unpack_to}
                      ? catdir( $mod->{unpack_to}, $extract_dir )
                      : $extract_dir
                      ; 
        $target = catdir( $unpack_dir, $extract_dir );
        push @build_queue, [$queue_dir, $mod];
        # unpack the tarball
        if ( -d $target ) {
            say "Removing previous $target";
            rmtree $target;
        }
    
        extract_whole( $tgz, $unpack_dir );
    }
    
    # copy in any extras (like config files)
    if ( my $extras = $mod->{extra} ) {
        for my $f ( keys %$extras ) {
            my $from = catfile( $f );
            my $to = catfile( $target, $extras->{$f} );
            say "Copying $from to $to";
            copy( $from, $to ) or die $!;
        }
    }


}

# Build each distribution in order

for my $dist ( @build_queue ) {
    my ($dir, $mod) = @$dist;
    my $wd = pushd catdir( $build_dir, $dir );
    
    warn "Needs better INSTALLDIRS handling!";
    say "Building $dir";
    run3 [ $perl, qw/Makefile.PL INSTALLDIRS=site/ ];
    -r catfile( $wd, 'Makefile' ) 
        or die "Problem running $dir Makefile.PL";
    run3 [ $dmake ];
    die "Problem making $dir" if ( $? >> 8 );
    run3 [ $dmake, qw/test/ ];
    if ( $? >> 8 and ! $mod->{force} ) {
        say "Problem testing $dir.  Continue (y/N)?";
        my $answer = <>;
        exit 1 if $answer !~ /\Ay/i;
    }
    run3 [ $dmake, qw/install UNINST=1/ ];
    die "Problem installing $dir" if ( $? >> 8 );
}

