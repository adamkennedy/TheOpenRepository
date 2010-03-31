package PPI::XS::Tokenizer;

use 5.006002;
use strict;
use warnings;

our $VERSION = '0.01';
our @ISA = qw{PPI::Tokenizer};

use Carp ();
use Params::Util    qw{_INSTANCE _SCALAR0 _ARRAY0};

use PPI::XS::Tokenizer::Constants;

require XSLoader;
XSLoader::load('PPI::XS::Tokenizer', $VERSION);

sub new {
  my $class = ref($_[0]) || $_[0];

  my $self = {};

  if ( ! defined $_[1] ) {
    # We weren't given anything
    PPI::Exception->throw("No source provided to Tokenizer");

  } elsif ( ! ref $_[1] ) {
    my $source = PPI::Util::_slurp($_[1]);
    if ( ref $source ) {
      # Content returned by reference
      $self->{source} = $$source;
    } else {
      # Errors returned as a string
      return( $source );
    }

  } elsif ( _SCALAR0($_[1]) ) {
    $self->{source} = ${$_[1]};

  } elsif ( _ARRAY0($_[1]) ) {
    $self->{source} = join '', map { "\n" } @{$_[1]};

  } else {
    # We don't support whatever this is
    PPI::Exception->throw(ref($_[1]) . " is not supported as a source provider");
  }

  $self->{source_bytes} = length $self->{source};
  if ( $self->{source_bytes} ) {
    # Split on local newlines
    $self->{source} =~ s/(?:\015{1,2}\012|\015|\012)/\n/g;
    $self->{source} = [ split /(?<=\n)/, $self->{source} ];

  } else {
    $self->{source} = [ ];
  }

  #my $class = shift;
  #my $source = shift;
  #my $lines;
  #if (!ref($source)) {
  #  $lines = [split /(?<=\n)/, $source]; # FIXME: Copying bad, mkay? Not clear how to fix this
  #}
  #elsif (ref($source) eq 'ARRAY') {
  #  $lines = $source; # FIXME: Copy here, too, for safety?
  #}
  #elsif (ref($source) eq 'SCALAR') {
  #  $lines = [split /(?<=\n)/, $$source]; # FIXME: Copying bad, mkay? Not clear how to fix this
  #}
  #else {
  #  Carp::croak('Need $source, \$source, or \@source');
  #}

  return $class->InternalNew($self->{source});
}


1;

__END__

=head1 NAME

PPI::XS::Tokenizer - Perl extension for blah blah blah

=head1 SYNOPSIS

  use Foo;

=head1 DESCRIPTION

Stub documentation for Foo, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Shmuel Fomberg, E<lt>semuelf@cpan.orgE<gt>

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Shmuel Fomberg

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
