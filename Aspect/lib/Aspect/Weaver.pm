package Aspect::Weaver;

use 5.006;
use strict;
use warnings;
use Carp                  ();
use Devel::Symdump        ();
use Aspect::Hook::LexWrap ();

our $VERSION = '0.22';

my %UNTOUCHABLES = map { $_ => 1 } qw(
	attributes base fields lib strict warnings Carp Carp::Heavy Config CORE
	CORE::GLOBAL DB DynaLoader Exporter Exporter::Heavy IO IO::Handle UNIVERSAL
);

sub new {
	bless {}, shift;
}

sub get_sub_names {
	local $_;
	# TODO: Need to filter Aspect exportable functions!
	return map {
		Devel::Symdump->new($_)->functions
	} grep {
		! /^Aspect::/
	} grep {
		! $UNTOUCHABLES{$_}
	} ( Devel::Symdump->rnew->packages, 'main' );
}

sub install {
	my ($self, $type, $name, $code) = @_;
	if ( $type eq 'before' ) {
		return Aspect::Hook::LexWrap::wrap( $name, $code, undef );
	} else {
		return Aspect::Hook::LexWrap::wrap( $name, undef, $code );
	}
}

1;

__END__

=pod

=head1 NAME

Aspect::Weaver - aspect weaving functionality

=head1 SYNOPSIS

  $weaver = Aspect::Weaver->new;
  print join(',', $weaver->get_sub_names); # all wrappable subs
  $weaver->install(before => 'Employee::get_name', $wrapper_code);
  $weaver->install(after  => 'Employee::set_name', $wrapper_code);

=head1 DESCRIPTION

Used by L<Aspect::Advice> to get all wrappable subs, and to install a
before/after hook on a sub. Uses L<Aspect::Hook::LexWrap> for the
wrapping itself, and C<Devel::Symdump> for accessing symbol table info.

=head1 SEE ALSO

See the L<Aspect|::Aspect> pod for a guide to the Aspect module.

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
