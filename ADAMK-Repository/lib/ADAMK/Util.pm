package ADAMK::Util;

use 5.008;
use strict;
use warnings;
use Carp         ();
use IPC::Run3    ();
use File::Flat   ();
use File::Remove ();
use File::Which  ();

use vars qw{$VERSION @ISA $VERBOSE @EXPORT_OK %EXPORT_TAGS};
BEGIN {
	require Exporter;

	$VERSION     = '0.10';
	@ISA         = ( 'Exporter' );
	$VERBOSE     = 0 unless defined $VERBOSE;
	@EXPORT_OK   = qw{ shell chdir copy move remove which };
	%EXPORT_TAGS = (
		ALL => [ @EXPORT_OK ],
	);
}





#####################################################################
# Exportable Functions

sub which {
	my $program  = shift;
	print "- which '$program'\n" if $VERBOSE;
	my $location = File::Which::which( $program );
	unless ( $location ) {
		Carp::croak( "Can't find the required program '$program'. Please install it" );
	}
	unless ( -r $location and -x $location ) {
		Carp::croak( "The required program '$program' is installed, but I do not have permission to read or execute it" );
	}
	return $location;
}

sub shell {
	my $command = shift;
	print "> $command\n" if $VERBOSE;
	my $rv = ! IPC::Run3::run3( $command, undef, undef );
	if ( $rv or ! @_ ) {
		return $rv;
	}
	Carp::croak( $_[0] || "Failed to run '$command'" );
}

sub chdir {
	my $dir = shift;
	print "- chdir '$dir'\n" if $VERBOSE;
	return 1 if CORE::chdir $dir;
	Carp::croak( "Failed to change to '$dir'" );
}

sub copy {
	my $from = shift;
	my $to   = shift;
	print "- copy '$from' => '$to'\n" if $VERBOSE;
	File::Flat->copy( $from => $to ) and return 1;
	Carp::croak( "Failed to copy '$from' to '$to'" );
}

sub move {
	my $from = shift;
	my $to   = shift;
	print "- move '$from' => '$to'\n" if $VERBOSE;
	File::Flat->copy( $from => $to ) and return 1;
	Carp::croak( "Failed to move '$from' to '$to'" );
}

my $chmod = undef;

sub remove {
	unless ( defined $chmod ) {
		$chmod = which( 'chmod' );
	}
	my $path = shift;
	return 1 unless -e $path;
	shell( "$chmod -R u+w $path" );
	print "- remove '$path'\n" if $VERBOSE;
	File::Remove::remove( \1, $path );
	Carp::croak( "Failed to remove '$path'" ) if -e $path;
	return 1;
}

1;

__END__

=pod

=head1 NAME

ADAMK::Util - Various utils used by ADAMK to write console tools

=head1 DESCRIPTION

Provides a bunch of exportable functions to do various tasks,
but wrapped in a sanity layer.

chdir - Change to a directory

copy - Copy a file or a directory

move - Move a file or a directory

remove - Delete a file or a directory

shell - Execute a command via the local shell

which - Locate a binary application

=head1 SUPPORT

Support is only available from the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2007 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
