package CGI::Capture;

=pod

=head1 NAME

CGI::Capture - Meticulously thorough capture and replaying of CGI calls

=head1 SYNOPSIS

  # Capture the current CGI to a file, and replay it once created
  use CGI::Capture 'fileupload.dat';
  
  # Create an object and capture the state
  my $Capture = CGI::Capture->new->capture;
  
  # Store it in a file and load it back in
  $Capture->store('somefile.dat');
  my $second = CGI::Capture->apply('somefile.dat');
  
  # Apply the CGI call to the current environment
  $second->apply;

=head1 DESCRIPTION

L<CGI> does a terribly bad job of saving CGI calls. C<CGI::Capture> tries
to resolve this and save a CGI call in as much painstaking detail as it
possibly can.

Because of this, C<CGI::Capture> should work with server logins, cookies,
file uploads, strange execution environments, special environment
variables, the works.

It does this by capturing a large amount of the perl environment
BEFORE F<CGI.pm> itself gets a chance to look at it, and then restores
it in the same way.

So in essence, it grabs all of C<STDIN>, C<%ENV>, C<@INC>, and anything
else it can think of. The things it can't replicate, it records anyway
so that later in the debugger it can ensure that the execution
environment is as close as possible to what it captured (and bitch at
you about anything you are doing wrong).

This is a huge help when resolving problems such as when a bug won't
appear because you aren't debugging the script as the web user and in
the same directory.

=head2 Using CGI::Capture

The brain-dead way is to use it as a pragma.

Add the following to your web application BEFORE you load in CGI itself.

  use CGI::Capture 'cookiebug.dat';

If the file C<cookiebug.dat> does not exist, CGI::Capture will take a
snapshot of all the bits of the environment that matter to a CGI call, and
freeze it to the file.

If the file DOES exist however, CGI::Capture will load in the file and
replace the current CGI call with the stored one.

=head2 Security

The actual captured CGI files are Storable CGI::Capture objects. If you
want to use CGI::Capture in an environment where you have CODE refereneces
in your @INC path (such as with PAR files), you will need to disable
security for Storable by setting $CGI::Capture::DEPARSE to true, which will
enable B::Deparse and Eval support for stored objects.

=head1 METHODS

In most cases, the above is all you probably need. However, if you want to
get more fine-grained control, you can create and manipulate CGI::Capture
object directly.

=cut
  
use 5.006;
use strict;
use Storable   ();
use IO::Scalar ();

our $VERSION = '1.05';
our $DEPARSE;





#####################################################################
# Constructor and Accessors

=pod

=head2 new

The C<new> only creates a new, empty, capture object.

Because capturing is destructive to some values (STDIN for example) the
capture method will capture and then immediately reapply the object, so that
the current call can continue.

Returns a CGI::Capture object. Never dies or returns an error, and so
can be safely method-chained.

=cut

sub new {
	my $class = ref $_[0] ? ref shift : shift;

	# Create the empty object
	bless {}, $class;
}

# The import expects a file name and does the following.
# 1. If the file does not exist, captures to it and continues.
# 2. If the file exists, restores from it and continues.
# 4. Does nothing if passed nothing.
sub import {
	my $class = ref $_[0] ? ref shift : shift;
	return 1 unless defined $_[0];
	return (-f $_[0])
		? $class->apply(shift)
		: $class->store(shift);
}





#####################################################################
# Implement the Storable API

=pod

=head2 store $filename

This method behaves slightly differently in object and static context.

In object context ( $object->store($filename) ) it stores the captured data
to a file via Storable.

In static context ( CGI::Capture->store($filename) ) automatically creates a
new capture object, captures the CGI call, and then stores it, all in one hit.

Returns as for Storable::store or dies if there is a problem storing the file.
Also dies if it finds a CODE reference in @INC and you have not enabled
C<$CGI::Capture::Deparse>.

=cut

sub store {
	my $self = ref $_[0] ? shift : shift->capture;

	# Make sure we are allowed to use B::Deparse to serialise
	# CODE refs in INC if needed.
	my $any_CODE_refs = scalar grep { ref $_ eq 'CODE' } @{$self->{INC}};
	if ( $any_CODE_refs and ! $DEPARSE ) {
		die "Found a CODE reference in \@INC, but \$CGI::Capture::DEPARSE is not true";
	}
	local $Storable::Deparse = $any_CODE_refs;

	Storable::lock_nstore($self, shift);
}

=pod

=head1 retrieve

The C<retrieve> method is used identically to the Storable method of the
same name, and wraps it.

Loads in a stored CGI::Capture object from a file.

If the stored object had a CODE ref in it's @INC, you will also need to
enable $CGI::Capture::DEPARSE when loading the file.

Returns a new CGI::Capture object, or dies on failure.

=cut

sub retrieve {
	my $class = ref $_[0] ? ref shift : shift;
	local $Storable::Eval = $DEPARSE;
	my $self = Storable::lock_retrieve(shift);
	return $self if UNIVERSAL::isa(ref $self, $class);
	die "Storable did not contains a $class object";
}





#####################################################################
# Main Methods

=pod

=head2 capture

Again, C<capture> can be used either as an object or static methods

When called as an object method ( $object->capture ) it captures the
current CGI call environment into the object, replacing the existing
one if needed.

When called as a static method ( CGI::Capture->capture ) it acts as a
constructor, creating an object and capturing the CGI call into it
before returning it.

In both cases, returns the CGI::Capture object. This method will not
die or return an error and can be safely method-chained.

=cut

sub capture {
	my $self = ref $_[0] ? shift : shift->new;

	# Reset the object
	%$self = ( CAPTURE_TIME => time );

	# Capture the environment
	$self->{ENV} = { %ENV };

	# Grab ARGV just to be on the safe side
	$self->{ARGV} = [ @ARGV ];

	# Grab the contents of STDIN
	$self->{STDIN} = do { local $/; my $tmp = <STDIN>; \$tmp };

	# Having captured it, restore it
	$self->_stdin( $self->{STDIN} );

	# Grab the include path
	$self->{INC} = [ @INC ];

	# Grab various environment-like state variables.
	# Especially ones they might have changed.
	$self->{OUTPUT_AUTOFLUSH}   = $|;
	$self->{REAL_USER_ID}       = $<;
	$self->{EFFECTIVE_USER_ID}  = $>;
	$self->{REAL_GROUP_ID}      = $(;
	$self->{EFFECTIVE_GROUP_ID} = $);
	$self->{PROGRAM_NAME}       = $0;
	$self->{OSNAME}             = $^O;
	$self->{TAINT}              = ${^TAINT};
	$self->{PERL_VERSION}       = $];

	$self;
}

=pod

=head2 apply [ $filename ]

Again, C<apply> works different when called as an object of static method.

If called as an object method ( $object->apply ) it will take the CGI
call the object contains, and apply it to the current environment.
Because this works at the environment level, it needs to be done BEFORE
CGI.pm attempts to create the CGI object.

The C<apply> method will also check certain values against the current
environment. In short, if it can't alter the environment, it won't run unless
YOU alter the environment and try again.

These include the real and effective user and group, the OS name, the perl
version, and whether Tainting is on or off.

The effect is to really make sure you are replaying the call in your console
debugger exactly as it was from the browser, and you arn't accidentally using
a different user, a different perl, or are making some other overlooked and
hard to debug mistake.

In the future, by request, I may add some options to selectively disable some
of the tests. But unless someone asks, I'm leaving all of them on.

In the static context, ( CGI::Capture->apply($file) ) it takes a filename
argument, immediately retrieves the CGI call from the object and immediately
applies it to the current environment.

In both context, returns true on success or dies on error, or it your testing
environment does not match.

=cut

sub apply {
	my $self = ref $_[0] ? shift : shift->retrieve(shift);
	$self->{CAPTURE_TIME} or die "Cannot apply empty capture object";

	# Update the environment
	%ENV = %{$self->{ENV}};

	# Set @ARGV
	@ARGV = @{$self->{ARGV}};

	# Set STDIN
	$self->_stdin( $self->{STDIN} );

	# Replace INC
	@INC = @{$self->{INC}};

	# Replace the internal variables we are allowed to
	$| = $self->{OUTPUT_AUTOFLUSH};
	$0 = $self->{PROGRAM_NAME};

	# Check that the critical variables match
	$self->_check( OSNAME             => $^O       );
	$self->_check( REAL_USER_ID       => $<        );
	$self->_check( EFFECTIVE_USER_ID  => $>        );
	$self->_check( REAL_GROUP_ID      => $(        );
	$self->_check( EFFECTIVE_GROUP_ID => $)        );
	$self->_check( TAINT              => ${^TAINT} );
	$self->_check( PERL_VERSION       => $]        );

	1;
}

# Checks a stored value against its current value
sub _check {
	my $self  = shift;
	my $name  = defined $_[0] ? shift : die "Var name not passed to ->_check";
	exists $self->{$name} or die "Bad name passed to ->_check";
	my $value = shift;
	unless ( defined $self->{$name} or defined $value ) {
		return 1;
	}
	if ( defined $self->{$name} and defined $value ) {
		return 1 if $self->{$name} eq $value;
	}

	# Didn't match
	die "Current $name does not match the captured CGI call";
}

# Takes a scalar reference and sets STDIN to read from it
sub _stdin {
	my $self = shift;
	my $scalar_ref = ref $_[0] eq 'SCALAR' ? shift
		: die "SCALAR reference not passed to ->_stdin";
	tie *MYSTDIN, 'IO::Scalar', $self->{STDIN};
	*STDIN = *MYSTDIN;
}

1;

=pod

=head1 SUPPORT

All bugs should be filed via the bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CGI%3A%3ACapture>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>cpan@ali.asE<gt>, L<http://ali.as/>

Thank you to Phase N (L<http://phase-n.com/>) for permitting
the open sourcing and release of this distribution.

=head1 COPYRIGHT

Copyright (c) 2004-200 Adam Kennedy. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
