package Text::FindIndent;

=pod

=head1 NAME

Text::FindIndent - Heuristically determine the indent style

=head1 SYNOPSIS

  use Text::FindIndent;
  my $indentation_type = Text::FindIndent->parse($text);
  if ($indentation_type =~ /^s(\d+)/) {
    print "Indentation with $1 spaces\n";
  }
  elsif ($indentation_type =~ /^t(\d+)/) {
    print "Indentation with tabs, a tab should indent by $1 characters\n";
  }
  elsif ($indentation_type =~ /^m(\d+)/) {
    print "Indentation with $1 characters in tab/space mixed mode\n";
  }
  else {
    print "Indentation style unknown\n";
  }

=head1 DESCRIPTION

This is an experimental distribution that attempts to intuit the underlying
indent "policy" for a text file (most likely a source code file).

=head1 METHODS

=head2 parse

The class method C<parse> tries to determine the indentation style of the
given piece of text (which must start at a new line and can be passed in either
as a string or as a reference to a scalar containing the string).

Returns a letter followed by a number. If the letter is C<s>, then the
text is most likely indented with spaces. The number indicates the number
of spaces used for indentation. A C<t> indicates tabs. The number after the
C<t> indicates the number characters each level of indentation corresponds to.
A C<u> indicates that the
indenation style could not be determined.
Finally, an C<m> followed by a number means that this many characters are used
for each indentation level, but the indentation is an arbitrary number of
tabs followed by 0-7 spaces. This can happen if your editor is stupid enough
to do smart indentation/whitespace compression. (I.e. replaces all indentations
many tabs as possible but leaves the rest as spaces.)

The function supports parsing of C<vim> I<modelines>. Those settings
override the heuristics. The modeline's options that are recognized
are C<sts>/C<softtabstob>, C<et>/C<noet>/C<expandtabs>/C<noexpandtabs>,
and C<ts>/C<tabstop>.

=cut

use 5.00503;
use strict;

use vars qw{$VERSION};
BEGIN {
  $VERSION = '0.02';
}

sub parse {
  my $class = shift;
  my $text  = shift;
  my $textref = ref($text) ? $text : \$text; # accept references, too

  my %modeline_settings;

  my %indentdiffs;
  my $lines                 = 0;
  my $prev_indent           = undef;
  my $skip                  = 0;

  while ($$textref =~ /\G([ \t]*)([^\r\n]*)[\r\n]+/cgs) {
    my $ws = $1;
    my $rest = $2;
    $lines++;
    
    # Do we have vim smart comments?
    $class->_check_vim_modeline("$ws$rest", \%modeline_settings);
    if (exists $modeline_settings{softtabstop} and exists $modeline_settings{usetabs}) {
      return(
        ($modeline_settings{usetabs} ? "m" : "s")
        . $modeline_settings{softtabstop}
      );
    }
    elsif (exists $modeline_settings{tabstop} and $modeline_settings{usetabs}) {
      return( "t" . $modeline_settings{tabstop} );
    }
    elsif (exists $modeline_settings{tabstop} and exists $modeline_settings{usetabs}) {
      return( "s" . $modeline_settings{tabstop} );
    }


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
      $maxkey = $mixedkey;
    }
  }

  if (exists $modeline_settings{softtabstop}) {
    $maxkey =~ s/\d+/$modeline_settings{softtabstop}/;
  }
  elsif (exists $modeline_settings{tabstop}) {
    $maxkey =~ s/\d+/$modeline_settings{tabstop}/;
  }
  if (exists $modeline_settings{usetabs}) {
    if ($modeline_settings{usetabs}) {
      $maxkey =~ s/^(.)(\d+)$/$1 eq 'u' ? "t8" : ($2 == 8 ? "t8" : "m$2")/e;
    }
    else {
      $maxkey =~ s/^./m/;
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
    $indentdiffs->{"t8"}++; # we can't infer what a tab means. Or rather, we need smarter code to do it
  }
  else { # mixed!
    $diff =~ s/( +)$//;
    my $trailing_spaces = $1;
    $diff =~ s/ +//g; #  assume the spaces are all contained in tabs!
    $indentdiffs->{"m" . (length($diff)*8+length($trailing_spaces))}++;
  }
}

sub _check_vim_modeline {
  my $class = shift;
  my $line = shift;
  my $settings = shift;

# Quoting the vim docs:
# There are two forms of modelines.  The first form:
#	[text]{white}{vi:|vim:|ex:}[white]{options}
#
#[text]		any text or empty
#{white}		at least one blank character (<Space> or <Tab>)
#{vi:|vim:|ex:}	the string "vi:", "vim:" or "ex:"
#[white]		optional white space
#{options}	a list of option settings, separated with white space or ':',
#		where each part between ':' is the argument for a ":set"
#		command (can be empty)
#
#Example:
#   vi:noai:sw=3 ts=6 ~
#   The second form (this is compatible with some versions of Vi):
#
#	[text]{white}{vi:|vim:|ex:}[white]se[t] {options}:[text]
#
#[text]		any text or empty
#{white}		at least one blank character (<Space> or <Tab>)
#{vi:|vim:|ex:}	the string "vi:", "vim:" or "ex:"
#[white]		optional white space
#se[t]		the string "set " or "se " (note the space)
#{options}	a list of options, separated with white space, which is the
#		argument for a ":set" command
#:		a colon
#[text]		any text or empty
#
#Example:
#   /* vim: set ai tw=75: */ ~
#
 
  my $vimtag = qr/(?:vi(?:m(?:[<=>]\d+)?)?|ex):/;
  my $option_arg = qr/[^\s\\]*(?:\\[\s\\][^\s\\]*)*/;
  my $option = qr/
    \w+(?:=)?$option_arg
  /x;
  my $modeline_type_one = qr/
    \s+
    $vimtag
    \s*
    ($option
      (?:
        (?:\s*:\s*|\s+)
        $option
      )*
    )
    \s*$
  /x;
  
  my $modeline_type_two = qr/
    \s+
    $vimtag
    \s*
    set?\s+
    ($option
      (?:\s+$option)*
    )
    \s*
    :
  /x;


  my @options;
  if ($line =~ $modeline_type_one) {
    push @options, split /(?!<\\)[:\s]+/, $1;
  }
  elsif ($line =~ $modeline_type_two) {
    push @options, split /(?!<\\)\s+/, $1;
  }
  else {
    return;
  }

  return if not @options;

  foreach (@options) {
    /s(?:ts|ofttabstop)=(\d+)/i and $settings->{softtabstop} = $1, next;
    /t(?:s|abstop)=(\d+)/i and $settings->{tabstop} = $1, next;
    /((?:no)?)(?:expandtab|et)/i and $settings->{usetabs} = (defined $1 and $1 =~ /no/i ? 1 : 0), next;
  }
  return;
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
