package Perl::Dist::WiX::Checkpoint;

=pod

=head1 NAME

Perl::Dist::WiX::Checkpoint - Checkpoint support for Perl::Dist::WiX

=head1 VERSION

This document describes Perl::Dist::WiX::Checkpoint version 1.100.

=head1 DESCRIPTION

This module provides the routines that Perl::Dist::WiX uses in order to
support checkpointing.

=head1 SYNOPSIS

	# This module is not to be used independently.

=head1 INTERFACE

=cut

use     5.008001;
use     strict;
use     warnings;
use     Archive::Zip          qw( :ERROR_CODES               );
use     English               qw( -no_match_vars             );
use     List::Util            qw( first                      );
use     List::MoreUtils       qw( any none                   );
use     Params::Util          qw( _HASH _STRING _INSTANCE    );
use     Readonly              qw( Readonly                   );
use     File::Spec::Functions qw(
	catdir catfile catpath tmpdir splitpath rel2abs curdir
);
use     Archive::Tar     1.42 qw();
use     File::Remove          qw();
use     File::pushd           qw();
use     File::ShareDir        qw();
use     File::Copy::Recursive qw();
use     File::PathList        qw();
use     HTTP::Status          qw();
use     IO::String            qw();
use     IO::Handle            qw();
use     LWP::UserAgent        qw();
use     LWP::Online           qw();
use     Module::CoreList 2.17 qw();
use     PAR::Dist             qw();
use     Probe::Perl           qw();
use     SelectSaver           qw();
use     Template              qw();
use     Win32                 qw();
require File::List::Object;

our $VERSION = '1.090';
$VERSION = eval { return $VERSION };

#####################################################################
# Checkpoint Support

# NOTE: "The object that called it" is supposed to be a Perl::Dist::WiX 
# object.

=head2 checkpoint_task

C<checkpoint_task> executes a portion of creating an installer.

The first parameter is the name of the subroutine to be executed.

The second parameter is the step number that goes with that subroutine.

Returns true (technically, the object that called it), or throws an exception.

=cut

sub checkpoint_task {
	my $self = shift;
	my $task = shift;
	my $step = shift;

	# Are we loading at this step?
	if ( $self->checkpoint_before == $step ) {
		$self->checkpoint_load;
	}

	# Skip if we are loading later on
	unless ( $self->checkpoint_before > $step ) {
		my $t = time;
		$self->$task();
		$self->trace_line( 0,
			"Completed $task (step $step) in " . ( time - $t ) . " seconds\n" );
	} else {
		$self->trace_line( 0, "Skipping $task (step $step.)\n" );
	}

	# Are we saving at this step?
	if ( defined first { $step == $_ } @{$self->checkpoint_after} ) {
		$self->checkpoint_save;
	}

	# Are we stopping at this step?
	if ( $self->checkpoint_stop == $step ) {
		return 0;
	}

	return $self;
} ## end sub checkpoint_task

=head2 checkpoint_file

Returns the file that the Perl::Dist::WiX object is stored in.

=cut

sub checkpoint_file {
	return catfile( $_[0]->checkpoint_dir, 'self.dat' );
}

=head2 checkpoint_file

Currently unimplemented, and throws an exception saying so.

=cut

sub checkpoint_self {
	return WiX3::Exception::Unimplemented->throw();
}

=head2 checkpoint_save

Saves a checkpoint within the checkpoint subdirectory of 
L<Perl::Dist::WiX-E<gt>temp_dir|Perl::Dist::WiX/temp_dir>

=cut

sub checkpoint_save {
	my $self = shift;
	unless ( $self->temp_dir ) {
		PDWiX->throw('Checkpoints require a temp_dir to be set');
	}

	# Clear out any existing checkpoint.
	$self->trace_line( 1, "Removing old checkpoint\n" );
	$self->{checkpoint_dir} = catfile( $self->temp_dir, 'checkpoint' );
	$self->remake_path( $self->checkpoint_dir );

	# Copy the paths into the checkpoint directory.
	$self->trace_line( 1, "Copying checkpoint directories...\n" );
	foreach my $dir (qw{ build_dir download_dir image_dir output_dir }) {
		my $from = $self->$dir();
		my $to = catdir( $self->checkpoint_dir, $dir );
		$self->_copy( $from => $to );
	}

	# Store the main object.
	# Blank the checkpoint values to prevent load/save loops, and remove
	# things we can recreate later.
	my $copy = {
		%{$self},
		checkpoint_before => 0,
		checkpoint_after  => 0,
		tt_exists         => ( defined $self->{template_toolkit} ? 1 : 0 ),
		template_toolkit  => undef,
		user_agent        => undef,
		misc              => undef,
	};
	
#	require Data::Dump::Streamer;
#	print "\n\n\n";
#	print Data::Dump::Streamer->new()->IndentKeys(1)->DumpGlob(1)
#	  ->Data($copy)->Out();
#	print "\n\n\n";
	
	local $Storable::Deparse = 1;
	Storable::nstore( $copy, $self->checkpoint_file );

	return 1;
} ## end sub checkpoint_save

=head2 checkpoint_save

Restores a checkpoint saved to the checkpoint subdirectory of 
L<Perl::Dist::WiX-E<gt>temp_dir|Perl::Dist::WiX/temp_dir> with 
L</checkpoint_save>.

=cut

sub checkpoint_load {
	my $self = shift;
	unless ( $self->temp_dir ) {
		PDWiX->throw('Checkpoints require a temp_dir to be set');
	}

	# Does the checkpoint exist?
	$self->trace_line( 1, "Removing old checkpoint\n" );
	$self->{checkpoint_dir} =
	  File::Spec->catfile( $self->temp_dir, 'checkpoint', );
	unless ( -d $self->checkpoint_dir ) {
		PDWiX->throw('Failed to find checkpoint directory');
	}

	# If we want a future checkpoint, save it.
	my $checkpoint_after = $self->{checkpoint_after} || 0;
	
	# Load the stored hash over our object
	local $Storable::Eval = 1;
	my $stored = Storable::retrieve( $self->checkpoint_file );
	%{$self} = %{$stored};

	# Restore any possible future checkpoint.
	$self->{checkpoint_after} = $checkpoint_after;

	# Reload the template object if it existed before.
	if ( $self->{tt_exists} ) {
		$self->patch_template();
		delete $self->{tt_exists};
	}

	# Reload the misc object.
	WiX3::Traceable->_clear_instance();
	$self->{misc} = WiX3::Traceable->new(
		tracelevel => $self->{trace} );

	# Pull all the directories out of the storage.
	$self->trace_line( 0, "Restoring checkpoint directories...\n" );
	foreach my $dir (qw{ build_dir download_dir image_dir output_dir }) {
		my $from = File::Spec->catdir( $self->checkpoint_dir, $dir );
		my $to = $self->$dir();
		File::Remove::remove($to);
		$self->_copy( $from => $to );
	}

	return 1;
} ## end sub checkpoint_load

1;

__END__

=pod

=head1 DIAGNOSTICS

See L<Perl::Dist::WiX::Diagnostics|Perl::Dist::WiX::Diagnostics> for a list of
exceptions that this module can throw.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist|Perl::Dist>, L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
