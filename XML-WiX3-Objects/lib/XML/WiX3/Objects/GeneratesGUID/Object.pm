package XML::WiX3::Objects::GeneratesGUID::Object;

#<<<
use     5.006;
use		MooseX::Singleton;
use     vars                      qw( $VERSION      );
use     Data::UUID                qw( NameSpace_DNS );
use     XML::WiX3::Objects::Types qw( Host          );
require XML::WiX3::Objects::Exceptions;

use version; $VERSION = version->new('0.003')->numify;
#>>>


#####################################################################
# Attributes

with 'XML::WiX3::Objects::Traceable';

has sitename (
    is      => 'ro',
	isa     => Host,
	reader  => '_get_sitename',
	default => q{www.perl.invalid},
);

has guidgen (
	is       => 'ro',
	isa      => 'Data::UUID',
	reader   => '_get_guidgen',
	init_arg => undef,
	default  => sub {
		return Data::UUID->new();
	},
);

has sitename_guid (
    is       => 'ro',
	isa      => 'Str',
	reader   => '_get_sitename_guid',
	lazy     => 1,
	init_arg => undef,
	default  => sub {
		my $self = shift;

		my $guidgen = $self->_get_guidgen();

		my $guid = $guidgen->create_from_name( 
			Data::UUID::NameSpace_DNS,
			$self->_get_sitename()
		);

		$self->trace_line( 5,
				'Generated site GUID: '
			  . $guidgen->to_string($guid)
			  . "\n"
		);

		return $guid;
	}	
);

#####################################################################
# Accessors

#####################################################################
# Main Methods

########################################
# generate_guid($id)
# Parameters:
#   $id: ID to create a GUID for.
# Returns:
#   The GUID generated.

sub generate_guid {
	my ( $self, $id ) = @_;
	
	#... then use it to create a GUID out of the filename.
	return uc $self->_get_guidgen()->create_from_name_str( 
		$self->_get_sitename_guid(), $id
	);

} ## end sub generate_guid

__PACKAGE__->meta->make_immutable;
no MooseX::Singleton;

1;

__END__

=head1 NAME

XML::WiX3::Objects - Objects useful for generating Windows Installer XML files.


=head1 VERSION

This document describes XML::WiX3::Objects version 0.003


=head1 SYNOPSIS

    # use XML::WiX3::Objects;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.
  
  
=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE 

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.
  
XML::WiX3::Objects requires no configuration files or environment variables.


=head1 DEPENDENCIES

L<Any::Moose> (which will default to requiring L<Mouse> version 0.20 or 
later, but will use L<Moose> if it is already available), L<Alien::WiX>


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

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

