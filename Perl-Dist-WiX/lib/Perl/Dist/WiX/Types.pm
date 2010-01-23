package Perl::Dist::WiX::Types;

=head1 NAME

Perl::Dist::WiX::Types - Public types used in Perl::Dist::WiX.

=head1 SYNOPSIS

	use Perl::Dist::WiX::Types qw( Directory ExistingDirectory );

=head1 DESCRIPTION

This module exists to provide Moose types that Perl::Dist::WiX and subclasses can use.

=head1 TYPES PROVIDED

=cut

use 5.008001;
use MooseX::Types -declare =>
  [qw( Directory ExistingDirectory ExistingFile MaybeExistingDirectory )];
use MooseX::Types::Moose qw( Str );

our $VERSION = '1.101_002';
$VERSION =~ s/_//ms;

=head2 Directory

	has foo => (
		is => 'ro',
		isa => Directory,
		#...
	);

This type specifies that this is a directory that can be created (i.e.
its drive exists.)

=cut

subtype Directory,
  as Str,
  where { ( $_ =~ m{\\}ms ) or ( $_ =~ m{\w*}ms ) },
  message {'Not a valid directory'};

=head2 ExistingDirectory

	has bar => (
		is => 'ro',
		isa => ExistingDirectory,
		#...
	);


=cut

subtype ExistingDirectory,
  as Directory,
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
  as Str,
  where { -f $_ },
  message {'File does not exist'};

1;

=pod

=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2009 - 2010 Curtis Jewell.

=cut
