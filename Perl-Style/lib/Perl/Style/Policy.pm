package Perl::Style::Policy;

=pod

=head1 NAME

Perl::Style::Policy - A complete configured multi-element style policy

=head2 DESCRIPTION

B<Perl::Style::Policy> implements a full and prepared style policy, consisting
of multiple different style elements, with various different configuration
options.

It is implemented as a subclass of L<PPI::Transform> which contains within
it a collection of other transform objects.

=head1 METHODS

=cut

use 5.008;
use strict;
use warnings;
use Params::Util   ();
use PPI::Transform ();

our $VERSION = '0.01';
our @ISA     = 'PPI::Transform';





######################################################################
# Constructor

sub new {
	my $class = shift;
	my $self  = bless {
		config    => [ ],
		transform => [ ],
	}, $class;

	# TODO Initialise the config here, later

	return $self;
}





######################################################################
# Policy Methods

sub add_transform {
	my $self   = shift;
	my $policy = Params::Util::_INSTANCE(shift, 'PPI::Transform');
	unless ( $policy ) {
		die "Missing or invalid transform object";
	}

	# Add to the transform list
	push @{$self->{transform}}, $policy;

	return 1;
}

sub add_config {
	my $self = shift;
	my $config = Params::Util::_INSTANCE(shift, 'Perl::Style::Config');
	unless ( $config ) {
		die "Missing or invalid config object";
	}

	# Add the configuration to the list
	push @{$self->{config}}, $config;

	# 
}





######################################################################
# PPI::Transform Methods

sub document {
	my $self     = shift;
	my $document = shift;
	my $changes  = 0;

	# Apply each of the child transforms
	foreach my $transform ( @{$self->{children}} ) {
		my $result = $transform->document( $document );
		if ( defined $result ) {
			$changes += $result;
		} else {
			# Error the entire thing?
			return undef;
		}
	}

	return $changes;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Style>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Tidy>, L<Perl::Style>

=head1 COPYRIGHT

Copyright 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
