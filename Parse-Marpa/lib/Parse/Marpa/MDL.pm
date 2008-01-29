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
    Parse::Marpa::get_symbol(
        $grammar,
        canonical_symbol_name($symbol_name)
    );
}

1;
