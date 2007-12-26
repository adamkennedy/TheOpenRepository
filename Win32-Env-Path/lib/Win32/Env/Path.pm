package Win32::Env::Path;

=pod

=head1 NAME

Win32::Env::Path - Manipulate environment PATH strings

=head1 SYNOPSIS

use Win32::Env::Path;

my $path = Win32::Env::Path->new(
	name => 'PATH',
);

$path->add('C:\\strawberry');
$path->remove('C:\\strawberry');

=head1 DESCRIPTION

B<Win32::Env::Path> is a simple module for inspecting and
manipulating environment path lists on Win32, with a particular
focus on the B<PATH>, B<LIB> and B<INCLUDE> environment variables.

It was designed to allow for intelligent path behaviours during
the installation and removal of software applications, and was
originally written for use in the the Strawberry Perl installer
and other L<Perl::Dist>-derived Perl distribution installers.

=cut

use 5.008;
use strict;
use warnings;
use Carp               'croak';
use Win32::TieRegistry ( FixSzNulls => 1 );
use Params::Util       '_STRING';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01';
}

my $USER_ENV   = 'HKEY_CURRENT_USER\\Environment';
my $SYSTEM_ENV = 'HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment';





#####################################################################
# Constructor and Accessors

sub new {
	my $class = shift;

	# Create the empty object
	my $self = bless { @_ },  $class;

	# Check params and provide defaults
	$self->{name}   ||= 'PATH';
	$self->{autosave} = defined $self->{autosave} ? !! $self->{autosave} : 1;
	$self->{user}     = !! $self->{user};
	$self->{env}      = $self->user ? $Registry->{$USER_ENV} : $Registry->{$SYSTEM_ENV};
	$self->{string}   = $self->env->{$self->name};
	$self->{array}    = undef;
	$self->{array}    = [ split /;/, $self->string ] if defined($self->string);
	$self->{changed}  = 0;

	return $self;
}

sub name {
	$_[0]->{name};
}

sub autosave {
	$_[0]->{autosave};
}

sub user {
	$_[0]->{user};
}

sub env {
	$_[0]->{env};
}

sub string {
	$_[0]->{string};
}

sub array {
	$_[0]->{array};
}

sub changed {
	$_[0]->{changed};
}

sub elements {
	my $self  = shift;
	my $array = $self->array;
	return defined $array ? 0 : scalar(@$array);
}





#####################################################################
# Main Interface Methods

sub remove {
	my $self = shift;
	my $path = shift;
	unless ( defined _STRING($path) ) {
		croak("Did not provide a path to ->remove");
	}

	# Shortcut if the list is empty
	my $before = $self->elements or return 1;

	# Filter out the path if it is in the array
	my $array = $self->array;
	@$array = grep { lc $path ne lc $_ } @$array;

	# Did we remove anything?
	if ( $self->elements == $before ) {
		# No change
		return 1;
	}

	# Synchronise and save if needed
	$self->sync;
}

# Removes all paths that do not exist
sub clean {
	my $self = shift;

	# Look for duplicates and non-existant paths and remove them.
	my $new   = ();
	my %seen  = ();
	my $array = $self->array;
	foreach my $path ( 0 .. $#$array ) {
		my $full = $self->resolve($array->[$path]);
		next if $seen{$full}++;
		next unless -d $full;
		push @$new, $array->[$path];
	}

	# Did we make any changes?
	return 1 if @$new == @$array;

	# Store and sync
	@$array = @$new;
	$self->sync;
}

sub clean_three {
	my $class = shift;
	foreach my $name ( qw{ PATH LIB INCLUDE } ) {
		Win32::Env::Path->new(
			name => $name,
		)->clean;
	}
	return 1;
}

sub sync {
	my $self = shift;

	# Flag as dirty
	$self->{changed} = 1;

	# Convert the list to the string
	$self->{string} = join(';', @{$self->array});

	# Save to the registry if needed
	$self->save if $self->autosave;

	return 1;
}

sub save {
	my $self = shift;

	# The string is already set correctly, just write it
	$self->env->{$self->name} = $self->string;

	# Remove the changed flag
	$self->{changed} = 0;

	return 1;
}





#####################################################################
# Synchronisation Methods

sub resolve {
	my $self = shift;
	my $path = shift;
	$path =~ s/\%(\w+)\%/$ENV{uc("$1")}/g;
	return lc $path;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Win32-Env-Path>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Win32::Env>, L<Perl::Dist::Inno>

=head1 COPYRIGHT

Copyright 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
