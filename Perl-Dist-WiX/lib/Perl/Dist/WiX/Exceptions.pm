package Perl::Dist::WiX::Exceptions;

####################################################################
# Perl::Dist::WiX::Exceptions - Exception classes for Perl::Dist::WiX.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See WiX.pm for details.
#
# NOTE: This is a base class with miscellaneous routines.  It is
# meant to be subclassed, as opposed to creating objects of this
# class directly.

use 5.008001;
use strict;
use warnings;

our $VERSION = '1.101_001';
$VERSION = eval $VERSION; ## no critic (ProhibitStringyEval)


#####################################################################
# Error Handling

use Exception::Class (
	'PDWiX'            => { 'description' => 'Perl::Dist::WiX error', },
	'PDWiX::Parameter' => {
		'description' =>
		  'Perl::Dist::WiX error: Parameter missing or invalid',
		'isa'    => 'PDWiX',
		'fields' => [ 'parameter', 'where' ],
	},
	'PDWiX::Caught' => {
		'description' =>
		  'Error caught by Perl::Dist::WiX from other module',
		'isa'    => 'PDWiX',
		'fields' => [ 'message', 'info' ],
	},
	'PDWiX::Unimplemented' => {
		'description' => 'Perl::Dist::WiX error: Routine unimplemented',
		'isa'         => 'PDWiX',
	},
);

sub PDWiX::full_message {
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->message() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it if tracelevel high enough.
	if ( $tracelevel > 1 ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	return $string;
} ## end sub PDWiX::full_message

sub PDWiX::Parameter::full_message {
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->parameter()
	  . ' in Perl::Dist::WiX'
	  . $self->where() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it. (We automatically dump trace for parameter errors.)
	$string .= "\n" . $self->trace() . "\n";

	return $string;
} ## end sub PDWiX::Parameter::full_message

sub PDWiX::Caught::full_message {
	my $self = shift;

	my $string =
	    $self->description() . ': '
	  . $self->message() . "\n"
	  . $self->info() . "\n"
	  . 'Time error caught: '
	  . localtime() . "\n";
	my $misc       = WiX3::Traceable->new();
	my $tracelevel = $misc->get_tracelevel();

	# Add trace to it if tracelevel high enough.
	if ( $tracelevel > 1 ) {
		$string .= "\n" . $self->trace() . "\n";
	}

	return $string;
} ## end sub PDWiX::Caught::full_message

1;

__END__

=pod

=head1 NAME

Perl::Dist::WiX::Exceptions - Exception classes for Perl::Dist::WiX

=head1 VERSION

This document describes Perl::Dist::WiX::Exceptions version 1.101.

=head1 DESCRIPTION

This module provides the exceptions that Perl::Dist::WiX uses when notifying
the user about errors.

=head1 SYNOPSIS

	# TODO.

=head1 INTERFACE

	# TODO.

=head1 DIAGNOSTICS

This is the module that defines the throwable exceptions.

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-WiX>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-WiX@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHORS

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 SEE ALSO

L<Perl::Dist::WiX|Perl::Dist::WiX>, 
L<http://ali.as/>, L<http://csjewell.comyr.com/perl/>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

Copyright 2008 - 2009 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
