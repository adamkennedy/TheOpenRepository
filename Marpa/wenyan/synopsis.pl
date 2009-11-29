#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Marpa::UrHTML;
use HTML::Tagset;

my $example = '<?pi><table><?pi><tr><td><table><?pi></table></table><?pi>';

sub format_element {
    my $tagname = Marpa::UrHTML::tagname();
    my $start_tag =
        ${ Marpa::UrHTML::start_tag()
            // \(qq{<!-- Missing start tag for $tagname element -->}) };
    my $end_tag = $HTML::Tagset::emptyElement{$tagname} ? q{}
        : ${ Marpa::UrHTML::end_tag()
            // \qq{<!-- Missing end tag for $tagname element -->} };
    my $contents = ${ Marpa::UrHTML::contents() };
    $contents =~ s/\A\s*\n//xmsg;
    $contents =~ s/\s*\z//xms;
    if ($contents) { $contents =~ s/^/  /xmsg }
    $contents = join q{}, "\n", $start_tag, "\n",
        ( $contents ? "$contents\n" : q{} ),
        ( $end_tag ? "$end_tag\n" : q{} );
    return $contents;
} ## end sub format_element
my $format_args = { handlers => [ [ q{*} => \&format_element ] ] };

my $value = Marpa::UrHTML->new($format_args)->parse(\$example);
say "Quick 'n Dirty Format:\n", ${$value};
