package Perl::Dist::WiX::PrivateTypes;

=pod

=head1 NAME

Perl::Dist::WiX::PrivateTypes - Types private to Perl::Dist::WiX.

=head1 SYNOPSIS

	use Perl::Dist::WiX::PrivateTypes;

=head1 DESCRIPTION

This module contains types and portions of types private to Perl::Dist::WiX.

=cut

use 5.008001;
use MooseX::Types -declare => [
	qw( _NoDoubleSlashes _NoSpaces _NoForwardSlashes _NoSlashAtEnd _NotRootDir )
];
use MooseX::Types::Moose qw( Str );

# use Perl::Dist::WiX::Types;

our $VERSION = '1.102_103';
$VERSION =~ s/_//ms;

subtype _NoDoubleSlashes,
  as Str,
  where { $_ !~ m{\\\\}ms },
  message {'cannot contain two consecutive slashes'};

subtype _NoSpaces,
  as Str,
  where { $_ !~ m{\s}ms },
  message {'Spaces are not allowed'};

subtype _NoForwardSlashes,
  as Str,
  where { $_ !~ m{/}ms },
  message {'Forward slashes are not allowed'};

subtype _NoSlashAtEnd,
  as Str,
  where { $_ !~ m{\\\z}ms },
  message {'Cannot have a slash at the end'};

subtype _NotRootDir,
  as Str,
  where { $_ !~ m{:\z}ms },
  message {'Cannot be a root directory'};

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
