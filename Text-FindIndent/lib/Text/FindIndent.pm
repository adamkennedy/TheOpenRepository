package Text::FindIndent;

=pod

=head1 NAME

Text::FindIndent - Heuristically determine the indent style

=head1 DESCRIPTION

This is an experimental distribution that attempts to intuit the underlying
indent "policy" for a text file (most likely a source code file).

=cut

use 5.00503;
use strict;

use vars qw{$VERSION};
BEGIN {
  $VERSION = '0.01';
}

sub parse {
  my $class = shift;
  my $text  = shift;
  my $textref = ref($text) ? $text : \$text; # accept references, too

  my %indentdiffs;
  my $lines                 = 0;
  my $prev_indent           = undef;
  my $skip                  = 0;
  while ($$textref =~ /\G([ \t]*)([^\r\n]*)[\r\n]+/cgs) {
    my $ws = $1;
    my $rest = $2;
    $lines++;

    if ($skip) {
      $skip--;
      next;
    }

    next if $rest eq '';

    if ($ws eq '') {
      $prev_indent = $ws;
      next;
    }

    # skip next line if the last char is a backslash.
    # Doesn't matter for Perl, but let's be generous!
    $skip = 1 if $rest =~ /\\$/;
    
    # skip single-line comments
    next if $rest =~ /^(?:#|\/\/|\/\*)/; # TODO: parse /* ... */!

    # prefix-matching higher indentation level
    if ($ws =~ /^\Q$prev_indent\E(.+)$/) {
      my $diff = $1;
      _grok_indent_diff($diff, \%indentdiffs);
      $prev_indent = $ws;
      next;
    }

    # prefix-matching lower indentation level
    if ($prev_indent =~ /^\Q$ws\E(.+)$/) {
      my $diff = $1;
      _grok_indent_diff($diff, \%indentdiffs);
      $prev_indent = $ws;
      next;
    }

    # at this point, we're desperate!
    my $prev_spaces = $prev_indent;
    $prev_spaces =~ s/[ ]{0,7}\t/        /g;
    my $spaces = $ws;
    $spaces =~ s/[ ]{0,7}\t/        /g;
    my $len_diff = length($spaces) - length($prev_spaces);
    if ($len_diff) {
      $len_diff = abs($len_diff);
      $indentdiffs{"m$len_diff"}++;
    }
    $prev_indent = $ws;
        
  } # end while lines

  # nothing found
  return 'u' if not keys %indentdiffs;

  my $max = 0;
  my $maxkey = undef;
  while (my ($key, $value) = each %indentdiffs) {
    $maxkey = $key, $max = $value if $value > $max;
  }

  if ($maxkey =~ /^s(\d+)$/) {
    my $mixedkey = "m" . $1;
    my $mixed = $indentdiffs{$mixedkey};
    if (defined($mixed) and $mixed >= $max * 0.2) {
      return $mixedkey;
    }
  }

  return $maxkey;
}

sub _grok_indent_diff {
  my $diff = shift;
  my $indentdiffs = shift;

  if ($diff =~ /^ +$/) {
    $indentdiffs->{"s" . length($diff)}++;
  }
  elsif ($diff =~ /^\t+$/) {
    $indentdiffs->{"t" . length($diff)}++;
  }
  else { # mixed!
    $diff =~ s/( +)$//;
    my $trailing_spaces = $1;
    $diff =~ s/ +//g; #  assume the spaces are all contained in tabs!
    $indentdiffs->{"m" . (length($diff)*8+length($trailing_spaces))}++;
  }
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-FindIndent>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, Steffen Mueller E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2008 Adam Kennedy,

Copyright 2008 Steffen Mueller.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
