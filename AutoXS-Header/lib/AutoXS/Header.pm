package AutoXS::Header;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.02';

sub WriteAutoXSHeader {
  my $filename = shift;
  if (defined $filename and $filename eq 'AutoXS::Header') {
    $filename = shift;
  }
  $filename = 'AutoXS.h' if not defined $filename;
  open my $fh, '>', $filename
    or die "Could not open '$filename' for writing: $!";
  print $fh "/* AutoXS::Header version '$VERSION' */\n";
  print $fh <<'AUTOXSHEADERHEREDOC';
typedef struct {
  U32 hash;
  SV* key;
} autoxs_hashkey;

unsigned int AutoXS_no_hashkeys = 0;
unsigned int AutoXS_free_hashkey_no = 0;
autoxs_hashkey* AutoXS_hashkeys = NULL;

unsigned int AutoXS_no_arrayindices = 0;
unsigned int AutoXS_free_arrayindices_no = 0;
I32* AutoXS_arrayindices = NULL;

unsigned int get_next_hashkey() {
  if (AutoXS_no_hashkeys == AutoXS_free_hashkey_no) {
    unsigned int extend = 1 + AutoXS_no_hashkeys * 2;
    /*printf("extending hashkey storage by %u\n", extend);*/
    unsigned int oldsize = AutoXS_no_hashkeys * sizeof(autoxs_hashkey);
    /*printf("previous data size %u\n", oldsize);*/
    autoxs_hashkey* tmphashkeys =
      (autoxs_hashkey*) malloc( oldsize + extend * sizeof(autoxs_hashkey) );
    memcpy(tmphashkeys, AutoXS_hashkeys, oldsize);
    free(AutoXS_hashkeys);
    AutoXS_hashkeys = tmphashkeys;
    AutoXS_no_hashkeys += extend;
  }
  return AutoXS_free_hashkey_no++;
}

unsigned int get_next_arrayindex() {
  if (AutoXS_no_arrayindices == AutoXS_free_arrayindices_no) {
    unsigned int extend = 1 + AutoXS_no_arrayindices * 2;
    /*printf("extending array index storage by %u\n", extend);*/
    unsigned int oldsize = AutoXS_no_arrayindices * sizeof(I32);
    /*printf("previous data size %u\n", oldsize);*/
    I32* tmparraymap =
      (I32*) malloc( oldsize + extend * sizeof(I32) );
    memcpy(tmparraymap, AutoXS_arrayindices, oldsize);
    free(AutoXS_arrayindices);
    AutoXS_arrayindices = tmparraymap;
    AutoXS_no_arrayindices += extend;
  }
  return AutoXS_free_arrayindices_no++;
}

AUTOXSHEADERHEREDOC
}

1;
__END__

=head1 NAME

AutoXS::Header - Container for the AutoXS header files

=head1 SYNOPSIS

  # potentially in your Makefile.PL
  sub MY::post_initialize{
    # Write header as AutoXS.h in current directory
    return <<'MAKE_FRAG';
  linkext ::
          $(PERL) -MAutoXS::Header -e 'AutoXS::Header::WriteAutoXSHeader()'
  # note the tab character in the previous line!

  MAKE_FRAG
  }

=head1 DESCRIPTION

This module is a simple container for the newest version of the L<AutoXS> header
file C<AutoXS.h>.

=head1 SEE ALSO

L<AutoXS>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
