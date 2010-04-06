package Perl::Dist::WiX::Checkpoint;

=pod

=head1 NAME

Perl::Dist::WiX::Checkpoint - Checkpoint support for Perl::Dist::WiX

=head1 VERSION

This document describes Perl::Dist::WiX::Checkpoint version 1.102_103.

=head1 SYNOPSIS

	# This module is not to be used independently.
	# It provides methods to be called on a Perl::Dist::WiX object.

	$dist = Perl::Dist::WiX->new(
		# ...
		checkpoint_before => 5
		checkpoint_after => [8, 9],
		checkpoint_stop => 9,
		# ...
	);

=head1 DESCRIPTION

This module provides the routines that Perl::Dist::WiX uses in order to
support checkpointing.

=head1 INTERFACE

There are 2 portions to the interface to this module - the parameters to 
L<new()|Perl::Dist::WiX/new> (documented in that module), and the 
object methods that Perl::Dist::WiX uses to coordinate checkpointing, as
described below.

These routines are not meant to be called from external classes.  
L<Perl::Dist::WiX|Perl::Dist::WiX> calls these routines as required.

=cut

use 5.008001;
use Moose;
use English qw( -no_match_vars );
use List::Util qw( first );
use File::Spec::Functions qw( catdir catfile );
use File::Remove qw();

our $VERSION = '1.102_103';
$VERSION =~ s/_//ms;

=head2 checkpoint_task

C<checkpoint_task> executes a portion of creating an installer.

The first parameter is the name of the subroutine to be executed.

The second parameter is the task number that goes with that subroutine.

Returns true (technically, the object that called it), or throws an exception.

This routine is called for each task (a task is a method on 
C<Perl::Dist::WiX> or a subclass of it) defined in the 
L<tasklist|Perl::Dist::WiX/tasklist> parameter to C<Perl::Dist::WiX->new()>.

=cut

sub checkpoint_task {
	my $self = shift;
	my $task = shift;
	my $step = shift;

	# Are we loading at this step?
	if ( $self->checkpoint_before() == $step ) {
		$self->checkpoint_load();
	}

	# Skip if we are loading later on
	if ( $self->checkpoint_before() > $step ) {
		$self->trace_line( 0, "Skipping $task (step $step.)\n" );
	} else {
		my $t = time;
		$self->$task();
		$self->trace_line( 0,
			    "Completed $task (step $step) in "
			  . ( time - $t )
			  . " seconds\n" );
	}

	# Are we saving at this step?
	if ( defined first { $step == $_ } @{ $self->checkpoint_after() } ) {
		$self->checkpoint_save();
	}

	# Are we stopping at this step?
	if ( $self->checkpoint_stop() == $step ) {
		return 0;
	}

	return $self;
} ## end sub checkpoint_task

=head2 checkpoint_file

Returns the file that the Perl::Dist::WiX object is stored in when
C<checkpoint_save> is called.

=cut

sub checkpoint_file {
	my $self = shift;
	return catfile( $self->checkpoint_dir(), 'self.dat' );
}

=head2 checkpoint_self

Currently unimplemented, and throws an exception saying so.

=cut

sub checkpoint_self {
	return WiX3::Exception::Unimplemented->throw();
}

=head2 checkpoint_save

Saves a checkpoint within the checkpoint subdirectory of 
L<< Perl::Dist::WiX->temp_dir|Perl::Dist::WiX/temp_dir >>

=cut

sub checkpoint_save {
	my $self = shift;
	unless ( $self->temp_dir ) {
		PDWiX->throw('Checkpoints require a temp_dir to be set');
	}

	# Clear out any existing checkpoint.
	$self->trace_line( 1, "Removing old checkpoint\n" );
	$self->remake_path( $self->checkpoint_dir() );

	# Copy the paths into the checkpoint directory.
	$self->trace_line( 1, "Copying checkpoint directories...\n" );
	foreach my $dir (qw{ build_dir download_dir image_dir output_dir }) {
		my $from = $self->$dir();
		my $to = catdir( $self->checkpoint_dir(), $dir );
		$self->copy_file( $from => $to );
	}

	# Store the main object.
	# Blank the checkpoint values to prevent load/save loops, and remove
	# things we can recreate later.
	my $copy = {
		%{$self},
		checkpoint_before => 0,
		checkpoint_after  => [0],
		checkpoint_stop   => 0,
		patch_template    => undef,
		user_agent        => undef,
		'_guidgen'        => undef,
		'_trace_object'   => undef,
	};

	local $Storable::Deparse = 1;
	Storable::nstore( $copy, $self->checkpoint_file() );

	return 1;
} ## end sub checkpoint_save

=head2 checkpoint_load

Restores a checkpoint saved to the checkpoint subdirectory of 
L<< Perl::Dist::WiX->temp_dir|Perl::Dist::WiX/temp_dir >> with 
L</checkpoint_save>.

=cut

sub checkpoint_load {
	## no critic(ProtectPrivateSubs)
	my $self = shift;

	# Does the checkpoint exist?
	$self->trace_line( 1, "Removing old checkpoint\n" );
	unless ( -d $self->checkpoint_dir() ) {
		PDWiX->throw('Failed to find checkpoint directory');
	}

	# If we want a future checkpoint, save it.
	my $checkpoint_after = $self->checkpoint_after() || 0;
	my $checkpoint_stop  = $self->checkpoint_stop()  || 0;
	
	# Save off the user agent for later restoration.
	my $user_agent = $self->user_agent();

	# Clear the directory tree.
	$self->_clear_directory_tree();
	Perl::Dist::WiX::DirectoryTree2->_clear_instance();
	
	# Load the stored hash over our object
	local $Storable::Eval = 1;
	my $stored = Storable::retrieve( $self->checkpoint_file() );
	%{$self} = %{$stored};

	# Restore any possible future checkpoint.
	$self->_set_checkpoint_after($checkpoint_after);
	$self->_set_checkpoint_stop($checkpoint_stop);

	# Grab the directory tree stuff before we clear it.
	my $directory_tree_root = $self->{_directories}->{_root};
	my $app_name = $self->{_directories}->{app_name};
	my $app_dir = $self->{_directories}->{app_dir};	
	
	# Clear the directory tree instance again, then 
	# recreate it with the saved stuff.
	$self->_clear_directory_tree();
	Perl::Dist::WiX::DirectoryTree2->_clear_instance();
	$self->_set_directories(
		Perl::Dist::WiX::DirectoryTree2->new(
			app_dir  => $app_dir,
			app_name => $app_name,
			_root    => $directory_tree_root,
		)
	);
	
	# Reload the misc object.
	$self->_clear_trace_object();
	WiX3::Trace::Object->_clear_instance();
	WiX3::Traceable->_clear_instance();
	$self->_set_trace_object(
		WiX3::Traceable->new( tracelevel => $self->trace() ) );

	# Reload GUID generator.
	$self->_clear_guidgen();
	WiX3::XML::GeneratesGUID::Object->_clear_instance();
	$self->_set_guidgen(
		WiX3::XML::GeneratesGUID::Object->new(
			_sitename => $self->sitename() ) );
			
	# Reload LWP user agent.
	$self->_clear_user_agent();
	$self->_set_user_agent($user_agent);

	# Clear other objects for reloading.
	$self->_clear_patch_template();

	# Pull all the directories out of the storage.
	$self->trace_line( 0, "Restoring checkpoint directories...\n" );
	foreach my $dir (qw{ build_dir download_dir image_dir output_dir }) {
		my $from = File::Spec->catdir( $self->checkpoint_dir(), $dir );
		my $to = $self->$dir();
		File::Remove::remove($to);
		$self->copy_file( $from => $to );
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

B<WARNING:> The checkpointing facility in this module is NOT stable.  It is 
currently implemented using L<Storable|Storable> with the C<$Storable::Deparse>
variable set to 1 (localized, of course).  This probably WILL change in the 
future, as when checkpoints are reloaded, hash entries are appearing that 
weren't intended to be there.  I am also not sure that references that were 
weakened are weakened when reloaded.

Restored checkpoints currently crash with "Free in wrong pool" errors in global 
destruction - if an exception occurs, they're reported there instead.

Do B<NOT> use this in production.  Debugging a distribution using the facilities 
provided here is fine.

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

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
