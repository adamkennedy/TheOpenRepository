package Perl::Dist::Strawberry::QA;

our $VERSION = 0.100;

1;

__END__

=pod

=begin readme text

Perl::Dist::Strawberry::QA version 0.100

=end readme

=for readme stop

=head1 NAME

Perl::Dist::Strawberry::QA - Quality assurance for Strawberry-based Perl distributions.

=head1 VERSION

This document describes Perl::Dist::Strawberry::QA version 0.100.

=for readme continue

=head1 DESCRIPTION

TODO

=begin readme

=head1 INSTALLATION

To install this module, run the following commands:

	perl Build.PL
	./Build
	./Build test
	./Build install

=end readme

=for readme stop

=head1 SYNOPSIS

	See strawberry_qa.pl for more documentation.
  
=head1 DIAGNOSTICS

This distribution is meant to be used as a test, so all diagnostics are 
returned as failing tests.

=head1 CONFIGURATION AND ENVIRONMENT

Perl::Dist::Strawberry::QA requires no configuration files or environment variables.

=for readme continue

=head1 DEPENDENCIES

Dependencies of this module that are non-core in perl 5.12.0 (which is the 
minimum version of Perl required) include 
L<Moose|Moose> version 0.90, L<Exception::Class|Exception::Class> version 
1.29, and L<Params::Util|Params::Util> version 0.35.

=for readme stop

=head1 INCOMPATIBILITIES

This module is incompatible with any normal 

=head1 BUGS AND LIMITATIONS (SUPPORT)

Bugs and suggestions for improvement should be reported via: 

1) The CPAN bug tracker at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Perl-Dist-Strawberry-QA>
if you have an account there.

2) Email to E<lt>bug-Perl-Dist-Strawberry-QA@rt.cpan.orgE<gt> if you do not.

For other issues, contact the topmost author.

=head1 AUTHOR

Curtis Jewell, C<< <csjewell@cpan.org> >>

=head1 SEE ALSO

L<http://csjewell.comyr.com/perl/>

=for readme continue

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010, Curtis Jewell C<< <csjewell@cpan.org> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself, either version
5.12.0 or any later version. See L<perlartistic> and L<perlgpl>.

The full text of the license can be found in the
LICENSE file included with this module.

=for readme stop

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
