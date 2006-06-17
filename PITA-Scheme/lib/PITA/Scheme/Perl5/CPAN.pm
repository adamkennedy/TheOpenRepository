package PITA::Scheme::Perl5::CPAN;

=pod

=head1 NAME

PITA::Scheme::Perl5::CPAN - PITA Testing Scheme for Existing CPAN Modules

=head1 DESCRIPTION

The original L<PITA::Scheme::Perl5::Make> and L<PITA::Scheme::Perl5::Build>
testing schemes test a Perl distribution provided via the injector directory.

However, this doesn't integrate in a straight-forward manner with CPAN
clients, and so the testing of these may prove somewhat troublesome.

B<PITA::Scheme::Perl5::CPAN> provides an alternate test scheme that uses the
default L<CPAN> client to install a Perl distribution that already exists on
the CPAN.

This allows the creation of first-generation CPAN testing systems similar to
the original CPAN Testers, that test the distribution only after it has
already been uploaded to the CPAN.

It also lets us shortcut a (at time of writing) currently unsolved problem
relating to the integration of a CPAN client an an arbitrary module.

=head1 METHODS

=cut

use 5.005;
use strict;
use base 'PITA::Scheme';
use Carp        ();
use File::Which ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.29';
}





#####################################################################
# Constructor

sub default_path {
	File::Which::which('perl') || '';
}

sub new {
	my $class = shift;
	my $self  = $class->SUPER::new(@_);

	### Additional checks

	$self;
}

