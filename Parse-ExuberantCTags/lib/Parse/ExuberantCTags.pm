package Parse::ExuberantCTags;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.00';

require XSLoader;
XSLoader::load('Parse::ExuberantCTags', $VERSION);


1;
__END__

=head1 NAME

Parse::ExuberantCTags - Efficiently parse exuberant ctags files

=head1 SYNOPSIS

  use Parse::ExuberantCTags;
  my $parser = Parse::ExuberantCTags->new( 'tags_filename' );
  
  # find a given tag that starts with 'foo' and do not ignore case
  my $tag = $parser->findTag("foo", ignore_case => 0, partial => 1);
  if (defined $tag) {
    print $tag->{name}, "\n";
  }
  $tag = $parser->findNextTag();
  # ...
  
  # iterator interface (use find instead, it's a binary search)
  $tag = $parser->firstTag;
  while (defined($tag = $parser->nextTag)) {
    # use the tag structure
  }

=head1 DESCRIPTION

=head1 SEE ALSO

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This Perl module is a wrapper around the F<readtags> library
that is shipped as part of the exuberant ctags program.
A copy of F<readtags> is included with this module.
F<readtags> was put in the public domain by its author. The full
copyright/license information from the code is:

  Copyright (c) 1996-2003, Darren Hiebert
  This source code is released into the public domain.

The XS wrapper and this document are:

Copyright (C) 2009 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
