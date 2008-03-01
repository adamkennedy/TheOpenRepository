package Devel::Leak::Module;

=pod

=head1 NAME

Devel::Leak::Module - Track loaded modules and namespaces

=head1 SYNOPSIS

TO BE COMPLETED

=head1 DESCRIPTION

=head1 METHODS

=cut

use 5.005;
use strict;
no strict 'refs';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.01_04';
}

BEGIN {
	# Force sort::hints to be populated early, to avoid a case where
	# calling all_modules creates a new namespace.
	my @foo = qw{ b c a };
	my @bar = sort @foo;

	# If Scalar::Util and List::Util are around, load them.
	# This prevents a problem when tests are run in the debugger.
	# If they AREN'T available, we don't care
	eval "require Scalar::Util; require List::Util;";
}





#####################################################################
# Main Functions

my %NAMESPACES = ();
my %PACKAGES   = ();
my %MODULES    = ();

sub checkpoint {
	%NAMESPACES = map { $_ => 1 } all_namespaces();
	%PACKAGES   = map { $_ => 1 } all_packages();
	%MODULES    = %INC;
	return 1;
}

sub new_namespaces {
	grep { ! $NAMESPACES{$_} } all_namespaces();
}

sub new_packages {
	grep { ! $PACKAGES{$_} } all_packages();
}

sub new_modules {
	grep { ! $MODULES{$_} } all_modules();
}

# Boolean true/false for if there are any new anything
sub any_new {
	return 1 if new_namespaces();
	return 1 if new_packages();
	return 1 if new_modules();
	return '';
}

# Print a summary of newly created things
sub print_new {
	my %parts = map { $_ => 1 } (@_ ? @_ : qw{ namespace package module });

	if ( $parts{module} ) {
		foreach my $module ( new_modules() ) {
			print "Module:    $module\n";
		}
	}
	if ( $parts{package} ) {
		foreach my $package ( new_packages() ) {
			print "Package:   $package\n";
		}
	}
	if ( $parts{namespace} ) {
		foreach my $namespace ( new_namespaces() ) {
			print "Namespace: $namespace\n";
		}
	}

}





#####################################################################
# Capture Functions

sub all_namespaces {
	my @names = ();
	my @stack = grep { $_ ne 'main' } _names('main');
	while ( @stack ) {
		my $c = shift @stack;
		push @names, $c;
		unshift @stack, _namespaces($c);
	}
	return @names;
}

# Start with all the namespaces,
# limited to the ones that look like classes.
# Then check each namespace actually contains something.
sub all_packages {
	grep { _OCCUPIED($_) } grep { _CLASS($_) } all_namespaces();
}

# Get the list of all modules
sub all_modules {
	sort grep { $_ ne 'dumpvar.pl' } keys %INC;
}





#####################################################################
# Support Functions

sub _names {
	return grep { s/::$// } sort keys %{$_[0] . '::'};
}

sub _namespaces {
	return map { $_[0] . '::' . $_ } _names($_[0]);
}





#####################################################################
# Embedded Functions

# Params::Util::_CLASS
sub _CLASS ($) {
	(defined $_[0] and ! ref $_[0] and $_[0] =~ m/^[^\W\d]\w*(?:::\w+)*$/s) ? $_[0] : undef;
}

# Class::Autouse::_namespace_occupied
sub _OCCUPIED ($) {
	# Handle the most likely case
	my $class = shift or return undef;
	return 1 if defined @{"${class}::ISA"};

	# Get the list of glob names, ignoring namespaces
	foreach ( keys %{"${class}::"} ) {
		next if substr($_, -2) eq '::';

		# Only check for methods, since that's all that's reliable
		return 1 if defined *{"${class}::$_"}{CODE};
	}

	'';
}

1;

=pod

=head1 SUPPORT

Bugs should be always be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Devel-Leak-Module>

For other issues, or commercial enhancement or support, contact the author.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Devel::Leak>, L<Devel::Leak::Object>

=head1 COPYRIGHT

Copyright 2007 - 2008 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
