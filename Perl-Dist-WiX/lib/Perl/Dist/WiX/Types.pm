package Perl::Dist::WiX::Types;

=head1 NAME

Perl::Dist::WiX::Types - Public types used in Perl::Dist::WiX.

=head1 VERSION

This document describes Perl::Dist::WiX::Types version 1.102_103.

=head1 SYNOPSIS

	use Perl::Dist::WiX::Types qw( ExistingDirectory ExistingFile Template );

=head1 DESCRIPTION

This module exists to provide Moose types that Perl::Dist::WiX and subclasses can use.

It may be updated or replaced at any time.

=head1 TYPES PROVIDED

=cut

use 5.008001;
use MooseX::Types -declare =>
  [qw( ExistingDirectory ExistingFile Template )];
use MooseX::Types::Moose qw( Str Object );
use MooseX::Types::Path::Class qw( Dir File );
use Template qw();

our $VERSION = '1.102_103';
$VERSION =~ s/_//ms;

=head2 ExistingDirectory

	has bar => (
		is => 'ro',
		isa => ExistingDirectory,
		#...
	);


=cut

subtype ExistingDirectory,
  as Dir,
  where { -d $_ },
  message {'Directory does not exist'};

=head2 ExistingFile

	has bar => (
		is => 'ro',
		isa => ExistingFile,
		#...
	);


=cut

subtype ExistingFile,
  as File,
  where { -f $_ },
  message {'File does not exist'};

  
=head2 Template

	has bar => (
		is => 'ro',
		isa => Template,
		#...
	);


=cut

subtype 'Template',
  as Object,
  where { $_->isa('Template') },
  message {'Template is not the correct type of object'};

1;

__END__

=pod

=head1 SUPPORT

No support is available for this class.

=head1 AUTHOR

Curtis Jewell E<lt>csjewell@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009 - 2010 Curtis Jewell.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this distribution.

=cut
