#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use Marpa::UrHTML;

my $urhtml_args = {
    handlers => [
        [   ':CRUFT' => sub {
                my $literal = Marpa::UrHTML::literal();
                my $length  = length $literal;
                return
                    qq{<!-- The following token ($length characters long) is CRUFT\n}
                    . qq{-->$literal>};
            },
        ],
        [   q{*} => sub {
                my $tagname = Marpa::UrHTML::tagname();

                my $start_tag = Marpa::UrHTML::start_tag()
                    // qq{<!-- Following start tag is replacement for a missing one -->\n}
                    . "<$tagname>";

                my $end_tag = Marpa::UrHTML::end_tag()
                    // "</$tagname>\n"
                    . qq{<!-- Preceding end tag is replacement for a missing one -->};

                my $contents = Marpa::UrHTML::contents();
                while ( $contents =~ s/\A\s*\n//xms ) {;}
                $contents =~ s/\s*\z//xms;
                $contents =~ s/^/  /xmsg;
                return join q{}, $start_tag, "\n", $contents, "\n", $end_tag,;
            },
        ],
    ]
};

my $p1 = Marpa::UrHTML->new($urhtml_args);
my $document = do { local $RS = undef; <STDIN> };
my $value = $p1->parse(\$document);
say ${$value};
