package Perl::Dist::Builder;

$VERSION = "0.000003";
use strict;
use warnings; 

#--------------------------------------------------------------------------#
# Imports
#--------------------------------------------------------------------------#

use Archive::Tar;
use Archive::Zip;
use Carp;
use CPAN ();
use File::Basename qw/basename dirname/;
use File::Copy::Recursive qw/rcopy/;
use File::Find::Rule;
use File::Path qw/mkpath rmtree/;
use File::pushd;
use File::Spec::Functions qw/catdir catfile tmpdir splitpath/;
use File::Spec::Unix; # for canonpath
use HTTP::Status;
use IPC::Run3;
use LWP::UserAgent;
use Tie::File;
use YAML ();

#--------------------------------------------------------------------------#
# Constants
#--------------------------------------------------------------------------#

use constant COMPRESSED => 1;

#--------------------------------------------------------------------------#
# Helper functions
#--------------------------------------------------------------------------#

sub say {
    print @_, "\n";
}

#--------------------------------------------------------------------------#
# API Functions
#--------------------------------------------------------------------------#

sub build_all {
    my $self = shift;
    $self->install_binaries;
    $self->install_perl;
    $self->install_modules;
    $self->install_extras;
    $self->install_from_cpan;
}

sub install_binaries {
    # Load configurations
    my $cfg = shift;
    my $binaries = $cfg->{binary}; # AOH
    my $download_dir = $cfg->{download_dir};
    my $image_dir = $cfg->{image_dir};

    if ( -d $image_dir ) {
        say "Removing existing $image_dir";
        rmtree( $image_dir );
    }

    say "Creating $image_dir";
    _init_dir( $image_dir );

    for my $d ( $download_dir, $image_dir ) {
        -d $d or mkpath( $d ) 
            or die "Couldn't create $d";
    }

    for my $binary ( @$binaries ) {
        my $name = $binary->{name};
        say "Preparing $name";
        
        # downloading
        my $tgz = _mirror_url( $binary->{url}, catdir( $download_dir, $name ) );
        
        # unpacking
        my $install_to = $binary->{install_to} || q{};
        if ( ref $install_to eq 'HASH' ) {
            _extract_filemap( $tgz, $install_to, $image_dir );
        }
        elsif ( ! ref $install_to ) {
            # unpack as a whole
            my $tgt = catdir( $image_dir, $install_to );
            _extract_whole( $tgz => $tgt );
        }
        else {
            die "didn't expect install_to to be a " . ref $install_to;
        }
        
        # finding licenses
        if ( ref $binary->{license} eq 'HASH' )   {
            my $license_dir = catdir( $image_dir, 'licenses' );
            _extract_filemap( $tgz, $binary->{license}, $license_dir, 1 );
        }
        
        # copy in any extras (e.g. CPAN\Config.pm starter)
        if ( my $extras = $binary->{extra} ) {
            for my $f ( keys %$extras ) {
                my $from = $f;
                my $to = catfile( $image_dir, $extras->{$f} );
                my $basedir = dirname( $to );
                mkpath( $basedir );
                say "Copying $from to $to";
                rcopy( $from, $to ) or die $!;
            }
        }
    }
}

sub install_from_cpan {
    # Load configurations
    my $cfg = shift;
    my $image_dir = $cfg->{image_dir};
    my $cpan = $cfg->{cpan} or return; # AOH

    # Check that we have our tools ready
    my $dmake = catfile( $image_dir, qw/dmake bin dmake.exe/ );
    my $perl =  catfile( $image_dir, qw/perl bin perl.exe/ );
    die "Can't execute $dmake" unless -x $dmake;
    die "Can't execute $perl" unless -x $perl;

    # Get various cpan modules to include

#    my @extras;
    
    for my $mod ( @$cpan ) {
        my $name = $mod->{name};
        my $force = $mod->{force} ? 1 : 0;
#        push @extras, $mod->{extra} if defined $mod->{extra};
        my $cpan_str = <<"ENDSTR";
print( "-" x 70, "\n" );
print "Preparing to install $name from CPAN\n";
\$obj = CPAN::Shell->expandany( "$name" ) 
    or die "CPAN.pm couldn't locate $name";
if ( \$obj->uptodate ) {
    print "$name is up to date\n";
    exit
}
if ( $force ) {
    \$obj->force("install");
    \$obj->uptodate or 
        die "Forced installation of $name appears to have failed";
}
else {
    \$obj->install;
    \$obj->uptodate or 
        die "Installation of $name appears to have failed";
}
ENDSTR
        run3 [ $perl, "-MCPAN", "-e", $cpan_str ];
        die "Failure detected installing $name, stopping" if $?;
    
        # copy in any extras (like config files)
        if ( my $extras = $mod->{extra} ) {
            for my $f ( keys %$extras ) {
                my $from = $f;
                my $to = catfile( $image_dir, $extras->{$f} );
                my $basedir = dirname( $to );
                mkpath( $basedir );
                say "Copying $from to $to";
                rcopy( $from, $to ) or die $!;
            }
        }
            
    }

}

sub install_extras {
    # Load configurations
    my $cfg = shift;
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
}

sub install_modules {
    # Load configurations
    my $cfg = shift;
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

    my $url_prefix = "http://mirrors.kernel.org/CPAN/authors/id/";

    for my $mod ( @$modules ) {
        my $mod_type = $mod->{type} || 'Module';
        # figure out the dist for the module
        my $mod_info = CPAN::Shell->expandany( $mod->{name})
            or die "Couldn't expand ", $mod->{name};
        my $cpan_file = 
            ref $mod_info eq 'CPAN::Module' ? $mod_info->cpan_file() :
            ref $mod_info eq 'CPAN::Distribution' ? $mod_info->id() :
            $mod->{name};

        next if $saw_dist{ $cpan_file }++;

        # download
        my $tgz = _mirror_url( $url_prefix . $cpan_file, $module_dir );

        my $dist_name = basename( $cpan_file );
        (my $extract_dir = $dist_name) =~ s{\.tar\.gz\z|\.tgz\z|\.zip\z}{};
        my ($unpack_dir, $target);

        if ( exists $mod->{unpack_to} and ref $mod->{unpack_to} eq 'HASH') {
            # individual subdirs
            say "Extracting individual files from $dist_name";
            $unpack_dir = $target = $build_dir;
            _extract_filemap( $tgz, $mod->{unpack_to}, $unpack_dir );
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
        
            _extract_whole( $tgz, $unpack_dir );
        }
        
        # copy in any extras (like config files)
        if ( my $extras = $mod->{extra} ) {
            for my $f ( keys %$extras ) {
                my $from = catfile( $f );
                my $to = catfile( $target, $extras->{$f} );
                say "Copying $from to $to";
                rcopy( $from, $to ) or die $!;
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
}

sub install_perl {
    # Load configurations
    my $cfg = shift;
    my $sources = $cfg->{source}; # AOH
    my $download_dir = $cfg->{download_dir};
    my $build_dir = $cfg->{build_dir};
    my $image_dir = $cfg->{image_dir};

    # Make sure we have dmake in the right place
    my $dmake = catfile( $image_dir, qw/dmake bin dmake.exe/ );
    die "Can't execute $dmake" unless -x $dmake;

    # Setup directory
    _init_dir( $image_dir );

    # download perl
    say "Building perl:";

    my $perl_cfg = $sources->[0]; # perl is the only one so far

    my $tgz = _mirror_url( 
        $perl_cfg->{url},
        catdir( $download_dir, $perl_cfg->{name} ) 
    );

    my $unpack_to = catdir( $build_dir, ( $perl_cfg->{unpack_to} || q{} ) );

    if ( -d $unpack_to ) {
        say "Removing previous $unpack_to";
        rmtree( $unpack_to );
    }

    _extract_whole( $tgz => $unpack_to );

    # Get the versioned name of the directory
    (my $perlsrc = $tgz) =~ s{\.tar\.gz\z|\.tgz\z}{};
    $perlsrc = basename($perlsrc);

    # Manually patch in the Win32 friendly ExtUtils::Install
    for my $f ( qw/Install.pm Installed.pm Packlist.pm/ ) {
        my $from = catfile( "extra", $f );
        my $to = catfile( $unpack_to, $perlsrc, qw/lib ExtUtils/, $f );
        say "Copying $from to $to";
        rcopy( $from, $to ) or die $!;
    }

    # finding licenses
    if ( ref $perl_cfg->{license} eq 'HASH' )   {
        my $license_dir = catdir( $image_dir, 'licenses' );
        _extract_filemap( $tgz, $perl_cfg->{license}, $license_dir, 1 );
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
            rcopy( $from, $to ) or die $!;
        }
    }

    # Should now have a perl to use
    my $perl = catfile( $image_dir, qw/perl bin perl.exe/ );
    die "Can't execute $perl" unless -x $perl;

    say "Perl build ok!";
}

sub new {
    my ($class, $yaml) = @_;
    my $self = YAML::LoadFile( $yaml );
    bless $self, $class;
}

sub remove_image {
    my $self = shift;
    my $image = $self->{image_dir};
    if ( -d $image ) {
        say "Removing previous $image";
        rmtree( $image );
    }
    else {
        say "No previous $image found";
    }
    return;
}
    
#--------------------------------------------------------------------------#
# Private functions
#--------------------------------------------------------------------------#

sub _extract_filemap {
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

sub _extract_whole {
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

sub _init_dir {
    my ($image_dir) = @_;

    mkpath $image_dir;

    for my $d ( qw/dmake mingw licenses links perl/ ) {
        mkpath catdir( $image_dir, $d );
    }
}

sub _mirror_url {
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

1; # modules must return true

__END__

#--------------------------------------------------------------------------#
# main pod documentation 
#--------------------------------------------------------------------------#

=head1 NAME

Perl::Dist::Builder - Create win32 Perl installers

=head1 SYNOPSIS

 use Perl::Dist::Builder;
 my $pdb = Perl::Dist::Builder->new( 'vanilla.yml' );
 $pdb->remove_image;
 $pdb->build_all;

=head1 DESCRIPTION

I<Perl::Dist::Builder is alpha software.>

Perl::Dist::Builder uses a configuration file to automatically generate a
complete, standalone Perl distribution in a directory suitable for bundling
into an executable installer.  

Perl::Dist::Builder requires Perl and numerous modules.  See 
L<Perl::Dist::Bootstrap> for details on how to bootstrap a Perl 
environment suitable for building new Perl distributions.

=head1 CONFIGURATION FILE

To be documented after Perl::Dist::Builder is refactored.  See the config files
in L<Perl::Dist::Vanilla> and L<Perl::Dist::Strawberry> for current examples.
Some sections currently have no effect.  

=head1 CREATING THE INSTALLER

Perl::Dist::Builder is not yet integrated with tools to create the executable.
Installers for Vanilla Perl, etc. have been created with the free Inno Setup
tool. Inno Setup can be downloaded from jrsoftware.org: 
L<http://www.jrsoftware.org/isinfo.php>

Inno Setup is configured with .iss files included in Perl::Dist::Vanilla
and Perl::Dist::Strawberry.  A future version of Perl::Dist::Builder will
likely auto-generate the .iss file.

=head1 METHODS

=head2 new()

 my $pdb = Perl::Dist::Builder->new( $yaml_config_file );

Create a new builder object, initialized from a YAML configuration file.

=head2 build_all()

 $pdb->build_all;

Runs all build tasks in order:  

=over

=item *

install_binaries

=item *

install_perl

=item *

install_modules

=item *

install_extras

=item *

install_from_cpan

=back 

Does I<not> delete the existing image directory.

=head2 install_binaries()

 $pdb->install_binaries;

Downloads binary packages (e.g. compiler, dmake) from URLs provided in
the config file.  Unpacks them (or portions of them) into the image
directory.

=head2 install_from_cpan()

 $pdb->install_from_cpan;

Uses the copy of perl in the image directory to run CPAN and install
modules defined in the config file.

=head2 install_extras()

 $pdb->install_extras;

Copies local files into the image directory.  E.g. documentation, menu
shortcuts, CPAN starter config file, etc.

=head2 install_modules()

 $pdb->install_modules;

Downloads tarballs for modules defined in the config file, unpacks them and
installs them directly using "Makefile.PL" and "dmake".  Does not invoke CPAN.
(Used primarily to get necessary prerequisite modules to make CPAN work sanely
and safely without binary helpers on Win32.)

=head2 install_perl()

 $pdb->install_perl;

Downloads Perl source tarball, unpacks it, builds it, and installs it into the
image directory.

=head2 remove_image()

 $pdb->remove_image;

Removes the "image_dir" directory specified in the config file, if
it exists, and prints a diagnostic message.

=head1 ROADMAP

Massive refactoring/rewrite is needed.  This initial version is a crudely
modulized form of individual perl scripts used in the early development process
of Vanilla Perl.  The next version is likely to use a plugin-driven approach
for extensibility and customization.  Other than C<build_all>, the API is
almost certain to change.

Additional documentation will be created after refactoring.

=head1 BUGS

Please report any bugs or feature using the CPAN Request Tracker.  
Bugs can be submitted by email to C<bug-Perl-Dist@rt.cpan.org> or 
through the web interface at 
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Perl-Dist>

=head1 AUTHOR

David A. Golden (DAGOLDEN)

dagolden@cpan.org

http://dagolden.com/

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2006 by David A. Golden

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
