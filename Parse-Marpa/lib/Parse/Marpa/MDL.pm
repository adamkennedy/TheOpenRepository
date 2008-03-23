use 5.010_000;
package Parse::Marpa::MDL;

sub gen_symbol_from_regex {
    my $regex = shift;
    my $data = shift;
    if (scalar @$data == 0) {
        my $number = 0;
        push(@$data, {}, \$number);
    }
    my ($regex_hash, $uniq_number) = @$data;
    given ($regex) {
        when (/^qr/) { $regex = substr($regex, 3, -1); }
        default { $regex = substr($regex, 1, -1); }
    }
    my $symbol = $regex_hash->{$regex};
    return $symbol if defined $symbol;
    $symbol = substr($regex, 0, 20);
    $symbol =~ s/%/%%/g;
    $symbol =~ s/([^[:alnum:]_-])/sprintf("%%%.2x", ord($1))/ge;
    $symbol .= sprintf(":k%x", ($$uniq_number)++);
    $regex_hash->{$regex} = $symbol;
    ($symbol, 1);
}

sub canonical_symbol_name {
    my $symbol = lc shift;
    $symbol =~ s/[-_\s]+/-/g;
    $symbol;
}

sub canonical_version {
    my $version = shift;
    my @version = split(/\./, $version);
    my $result = sprintf("%d.", (shift @version));
    for my $subversion (@version) {
       $result .= sprintf("%03d", $subversion);
    }
    $result;
}

sub get_symbol {
    my $grammar = shift;
    my $symbol_name = shift;
    Parse::Marpa::Grammar::get_symbol(
        $grammar,
        canonical_symbol_name($symbol_name)
    );
}

1;

=head1 NAME

Parse::Marpa::MDL -- Utility Methods for MDL

=head1 OVERVIEW

These routines handle the conversion of MDL names
to plumbing names.

=head1 DESCRIPTION

MDL symbol names behave differently from those in the raw interface.
MDL symbol names are allowed to vary in capitalization and separation,
while in the plumbing,
every slight variation of capitalization or separation produces a new,
unique name.

MDL symbol names have a "canonical form", which MDL uses with
the plumbing.
Users should always use 
the C<Parse::Marpa::MDL::canonical_name> method to convert from the
MDL symbol name to its canonical form.

=head1 METHODS

=head2 canonical_name

    $g->set({
        start => Parse::Marpa::MDL::canonical_symbol_name("Grammar")
    });

Takes as its one argument an MDL symbol
name and returns the canonical MDL name, which is also
the symbol's raw interface name.

Canonical MDL names are all lowercase,
with hyphens for separation.
For example,
the MDL symbol whose acceptable variants include
C<My symbol> and C<MY_SYMBOL> is, in canonical form, C<my-symbol>.

=head2 get_symbol

    my $op = Parse::Marpa::MDL::get_symbol($g, "Op");

Given a Marpa grammar object as the first argument and an MDL symbol name as the second.
the C<get_symbol> static method will return the symbol's "cookie".
Symbol cookies are needed to use the C<Parse::Marpa::Recognizer::earleme> method.

=head1 SUPPORT

See the L<support section|Parse::Marpa/SUPPORT> in the main module.

=head1 AUTHOR

Jeffrey Kegler

=head1 COPYRIGHT

Copyright 2007 - 2008 Jeffrey Kegler

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

# Local Variables:
#   mode: cperl
#   cperl-indent-level: 4
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4:
