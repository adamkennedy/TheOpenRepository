package FBP.pm;

=pod

=head1 NAME

FBP - Parser and Object Model for wxFormBuilder Project Files (.fpb files)

=head1 SYNOPSIS

  my $object = FBP.pm->new(
      foo  => 'bar',
      flag => 1,
  );
  
  $object->dummy;

=head1 DESCRIPTION

The author was too lazy to write a description.

=head1 METHODS

=cut

use 5.008005;
use strict;
use warnings;
use XML::SAX 

our $VERSION = '0.01';

=pod

=head2 new

  my $object = FBP.pm->new(
      foo => 'bar',
  );

The C<new> constructor lets you create a new B<FBP.pm> object.

So no big surprises there...

Returns a new B<FBP.pm> or dies on error.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;
	return $self;
}

=pod

=head2 dummy

This method does something... apparently.

=cut

sub dummy {
	my $self = shift;

	# Do something here

	return 1;
}

1;

=pod

=head1 SUPPORT

No support is available

=head1 AUTHOR

Copyright 2009 Anonymous.

=cut
