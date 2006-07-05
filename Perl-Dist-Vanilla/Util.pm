package Util;
use strict;
use warnings;

use Archive::Tar;
use Archive::Zip;
use File::Spec::Unix; # for canonpath
use File::Spec::Functions qw/catdir catfile/ ;
use File::Path qw/mkpath rmtree/;
use File::pushd;
use HTTP::Status;
use LWP::UserAgent;
use Perl6::Say;

#--------------------------------------------------------------------------#

use constant COMPRESSED => 1;

use Sub::Exporter -setup => {
    exports => [
        qw/mirror_url extract_whole extract_filemap init_dir/
    ],
};

#--------------------------------------------------------------------------#


sub extract_filemap {
    my ( $archive, $filemap, $basedir, $file_only ) = @_;

    if ( $archive =~ m{\.zip\z} ) {
        my $zip = Archive::Zip->new( $archive );
        my $wd = pushd $basedir;
        while ( my ($f, $t) = each %$filemap ) {
            say "Extracting $f to $t";
            my $dest = catfile( $basedir, $t );
            $zip->extractTree( $f, $dest );
        }
    }
    elsif ( $archive =~ m{\.tar\.gz|\.tgz} ) {
        local $Archive::Tar::CHMOD = 0;
        my $tar = Archive::Tar->new( $archive );
        for my $file ( $tar->get_files ) {
            my $f = $file->full_path;
            my $canon_f = File::Spec::Unix->canonpath( $f );
            for my $tgt ( keys %$filemap ) {
                my $canon_tgt = File::Spec::Unix->canonpath( $tgt );
                my $t;
                # say "matching $canon_f vs $canon_tgt";
                if ( $file_only ) {
                    next unless $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E\z}i;
                    ($t = $canon_f)   =~ s{\A([^/]+[/])?\Q$canon_tgt\E\z}
                                             {$filemap->{$tgt}}i;
                }
                else {
                    next unless $canon_f =~ m{\A([^/]+[/])?\Q$canon_tgt\E}i;
                    ($t = $canon_f)   =~ s{\A([^/]+[/])?\Q$canon_tgt\E}
                                             {$filemap->{$tgt}}i;
                }
                my $full_t = catfile( $basedir, $t );
                say "Extracting $f to $full_t";
                $tar->extract_file( $f, $full_t );
            }
        }
    }
    else {
        die "Didn't recognize archive type for $archive";
    }
    return 1;
}

sub extract_whole {
    my ( $from, $to ) = @_;
    mkpath( $to );
    my $wd = pushd $to;

    $|++;
    print "Extracting $from...";
    if ( $from =~ m{\.zip\z} ) {
        my $zip = Archive::Zip->new( $from );
        $zip->extractTree();
        say "done"
    }
    elsif ( $from =~ m{\.tar\.gz|\.tgz} ) {
        local $Archive::Tar::CHMOD = 0;
        Archive::Tar->extract_archive($from, COMPRESSED);
        say "done"
    }
    else {
        die "Didn't recognize archive type for $from";
    }
    return 1;
}

sub init_dir {
    my ($image_dir) = @_;

    mkpath $image_dir;

    for my $d ( qw/dmake mingw licenses links perl/ ) {
        mkpath catdir( $image_dir, $d );
    }
}

sub mirror_url {
    my $ua = LWP::UserAgent->new();
    my ( $url, $dir ) = @_;
    my ($file) = $url =~ m{/([^/?]+\.(?:tar\.gz|tgz|zip))}ims;
    mkpath( $dir );
    my $target = catfile( $dir, $file );
    $|++;
    print "Downloading $file...";
    my $r = $ua->mirror( $url, $target );
    if ( $r->is_error() ) {
        say "    Error getting $url:\n", $r->as_string;
    }
    elsif ( $r->code == RC_NOT_MODIFIED ) {
        say " already up to date.";
    }
    else {
        say " done";
    }
    return $target;
}

1;
    
