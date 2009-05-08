package XML::WiX3::Objects::Role::Tag;

####################################################################
# XML::WiX3::Objects::Base - Miscellaneous routines for Perl::Dist::WiX.
#
# Copyright 2009 Curtis Jewell
#
# License is the same as perl. See Objects.pm for details.

#<<<
use     5.006;
use		Moose::Role;
use     Params::Util  qw( _STRING _NONNEGINT );
use     vars          qw( $VERSION );
use     MooseX::AttributeHelpers;
require XML::WiX3::Objects::Exceptions;

use version; $VERSION = version->new('0.003')->numify;
#>>>



#####################################################################
# Attributes

# A tag can contain other tags.
has tags(
	metaclass => 'Collection::Array',
	is => 'rw',
	isa => 'ArrayRef[XML::WiX3::Objects::Tag]',
	init_arg => undef,
	default => sub { return []; },
	provides => {
	  'elements' => 'get_tags',
	  'push'     => 'add_tag',
	  'get'      => 'get_tag',
	  'empty'    => 'do_i_have_tags',
	}
);

#####################################################################
# Methods

# Tags have to be able to be strings.
requires 'as_string';

########################################
# indent($spaces, $string)
# Parameters:
#   $spaces: Number of spaces to indent $string.
#   $string: String to indent.
# Returns:
#   Indented $string.

sub indent {
	my ( $self, $spaces, $string ) = @_;

	# Check parameters.
	unless ( _STRING($string) ) {
		XWObj::Parameter->throw(
			parameter => 'string',
			where     => '::Tag->indent'
		);
	}
	unless ( defined _NONNEGINT($num) ) {
		XWObj::Parameter->throw(
			parameter => 'num',
			where     => '::Tag->indent'
		);
	}

	# Indent string.
	my $spaces = q{ } x $num;
	my $answer = $spaces . $string;
	chomp $answer;
#<<<
		$answer =~ s{\n}                   # match a newline 
					{\n$spaces}gxms;       # and add spaces after it.
										   # (i.e. the beginning of the line.)
#>>>
	return $answer;
} ## end sub indent

__PACKAGE__->meta->make_immutable;
no Moose::Role;

1;

__END__

=head1 NAME

XML::WiX3::Objects::Role::Tag - Base role for XML tags.

=head1 VERSION

This document describes XML::WiX3::Objects::Role::Tag version 0.003

=head1 SYNOPSIS

    # use XML::WiX3::Objects;

=head1 DESCRIPTION

This is the base class for all objects that represent XML tags.

=head1 INTERFACE 

=head2 indent

	$string = $object->indent(4, $string);

This routine indents the string passed in with the given number of spaces.

=head1 DIAGNOSTICS

See L<XML::WiX3::Objects#DIAGNOSTICS> for the diagnostics this module uses.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-xml-wix3-objects@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Curtis Jewell  C<< <csjewell@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Curtis Jewell C<< <csjewell@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

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

