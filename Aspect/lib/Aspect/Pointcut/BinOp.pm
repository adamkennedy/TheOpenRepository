package Aspect::Pointcut::BinOp;

use strict;
use warnings;
use Carp;
use Aspect::Pointcut ();

our $VERSION = '0.24';
our @ISA     = 'Aspect::Pointcut';

sub init {
	my $self = shift;
	$self->{left_op}  = shift;
	$self->{right_op} = shift;
}

sub match_define {
	my ($self, $sub_name) = @_;
	return $self->binop(
		$self->{left_op}->match_define($sub_name),
		$self->{right_op}->match_define($sub_name)
	);
}

sub match_run {
	my ($self, $sub_name, $runtime_context) = @_;
	return $self->binop(
		$self->{left_op }->match_run($sub_name, $runtime_context),
		$self->{right_op}->match_run($sub_name, $runtime_context)
	);
}

# template method to be defined in subclasses
sub binop { die "Must be implemented by subclass" }


1;


__END__

=pod

=head1 NAME

Aspect::Pointcut::BinOp - Binary operation pointcut

=head1 SYNOPSIS

    Aspect::Pointcut::BinOp->new;

=head1 DESCRIPTION

None yet.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit <http://www.perl.com/CPAN/> to find a CPAN
site near you. Or see <http://www.perl.com/CPAN/authors/id/M/MA/MARCEL/>.

=head1 AUTHORS

Marcel GrE<uuml>nauer, C<< <marcel@cpan.org> >>

Ran Eilam C<< <eilara@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright 2001 by Marcel GrE<uuml>nauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

