package Perl::Dist;

use 5.005;
use strict;
use Carp 'croak';
use base 'Perl::Dist::Inno';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.10';
}

use Object::Tiny qw{
	offline
	download_dir
	image_dir
	remove_image
	user_agent
};





#####################################################################
# Constructor

sub new {
	my $class  = shift;
	my %params = @_;

	# Apply some defaults
	unless ( defined $params{default_dir_name} ) {
		if ( $params{image_dir} ) {
			$params{default_dir_name} = $params{image_dir};
		} else {
			croak("Missing or invalid image_dir param");
		}
	}
	unless ( defined $params{user_agent} ) {
		$params{user_agent} = LWP::UserAgent->new;
	}

	# Hand off to the parent class
	my $self = shift->SUPER::new(%params);

	# Auto-detect online-ness if needed
	unless ( defined $self->{offline} ) {
		$self->{offline} = LWP::Online::offline();
	}

	# Normalize some params
	$self->{offline}      = !! $self->offline;
	$self->{remove_image} = !! $self->remove_image;

	# Check params
	unless ( _STRING($self->download_dir) ) {
		croak("Missing or invalid download_dir param");
	}
	unless ( _STRING($self->image_dir) ) {
		croak("Missing or invalid image_dir param");
	}
	unless ( _INSTANCE($self->user_agent, 'LWP::UserAgent') ) {
		croak("Missing or invalid user_agent param");
	}

	# Clear the previous build
	if ( -d $self->image_dir ) {
		if ( $self->remove_image ) {
			$self->trace("Removing previous $image\n");
			File::Remove::remove( \1, $image );
		} else {
			croak("The image_dir directory already exists");
		}
	} else {
		$self->trace("No previous $image found\n");
	}

	# Initialize the build
	File::Path::mkpath($self->image_dir);
	for my $d ( qw/dmake mingw licenses links perl/ ) {
		File::Path::mkpath(
			File::Spec->catdir( $dir, $d )
		);
	}

	# Create the working directories
	for my $d ( $self->download_dir, $self->image_dir ) {
		next if -d $d;
		File::Path::mkpath($d) or die "Couldn't create $d";
	}

        return $self;
}





#####################################################################
# Main Methods

sub run {

}

sub install_binary {
	my $self = shift;

	
}





#####################################################################
# Support Methods

sub trace {
	print $_[0];
}

sub _mirror {
	my ($self, $url, $dir) = @_;
	my ($file) = $url =~ m{/([^/?]+\.(?:tar\.gz|tgz|zip))}ims;
	my $target = File::Spec->catfile( $dir, $file );
	if ( $self->{offline} and -f $target ) {
		$self->trace(" already downloaded\n");
		return $target;
	}
	File::Path::mkpath($dir);
	$| = 1;

	$self->trace("Downloading $file...");
	my $ua = LWP::UserAgent->new;
	my $r  = $ua->mirror( $url, $target );
	if ( $r->is_error ) {
		$self->trace("    Error getting $url:\n" . $r->as_string . "\n");

	} elsif ( $r->code == HTTP::Status::RC_NOT_MODIFIED ) {
		$self->trace(" already up to date.\n");

	} else {
		$self->trace(" done\n");
	}

	return $target;
}

sub _copy {
	my ($self, $from, $to) = @_;
	my $basedir = File::Basename::dirname( $to );
	File::Path::mkpath($basedir) unless -e $basedir;
	$self->trace("Copying $from to $to\n");
	File::Copy::Recursive::rcopy( $from, $to ) or die $!;
}

sub _make {
	my $self   = shift;
	my @params = @_;
	$self->trace(join(' ', '>', $self->bin_make, @params) . "\n");
	IPC::Run3::run3( [ $self->bin_make, @params ] ) or die "make failed";
	die "make failed (OS error)" if ( $? >> 8 );
	return 1;
}

1;

__END__

=pod

=head1 NAME

Perl::Dist - Perl Distribution Creation Toolkit

=head1 DESCRIPTION

The Perl::Dist namespace encompasses creation of pre-packaged, binary
distributions of Perl, such as executable installers for Win32.  While initial
efforts are targeted at Win32, there is hope that this may become a more
general support tool for Perl application deployment.

Packages in this namespace include both "builders" and "distributions".
Builder packages automate the generation of distributions.  Distribution
packages contain configuration files for a particular builder, extra files
to be bundled with the pre-packaged binary, and documentation.
Distribution namespaces are also recommended to consolidate bug reporting
using http://rt.cpan.org/.

I<Distribution packages should not contain the pre-packaged install files
themselves.>

B<Please note that this module is currently considered experimental, and
not really suitable for general use>.

=head2 BUILDERS

There is currently only the default builder:

=over

=item *

L<Perl::Dist::Builder> -- an alpha version of a distribution builder

=back

=head2 DISTRIBUTIONS

Currently available distributions include:

=over

=item *

L<Perl::Dist::Vanilla> -- an experimental "core Perl" distribution intended
for distribution developers

=item *

L<Perl::Dist::Strawberry> -- a practical Win32 Perl release for
experienced Perl developers to experiment and test the installation of
various CPAN modules under Win32 conditions

=back

=head1 ROADMAP

Everything is currently alpha, at best.  These packages have been released
to enable community support in ongoing development.

Some specific items for development include:

=over

=item *

Bug-squashing Win32 compatibility problems in popular modules

=item *

Refactoring the initial builder for greater modularity and control of the
build process

=item *

Support for Win32 *.msi installation files instead of standalone *.exe
installers

=item *

Better uninstall support and upgradability

=back

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

David A. Golden <dagolden@cpan.org>

=head1 COPYRIGHT

Cyopright 2007 Adam Kennedy

Copyright 2006 David A. Golden

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

=over

=item *

L<Perl::Dist::Builder>

=item *

L<Perl::Dist::Vanilla>

=item *

L<Perl::Dist::Strawberry>

=item *

L<http://win32.perl.org/>

=item *

L<http://vanillaperl.com/>

=item *

L<irc://irc.perl.org/#win32>

=item *

L<http://ali.as/>

=item *

L<http://dagolden.com/>

=back

=cut
