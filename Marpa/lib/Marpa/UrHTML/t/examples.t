#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use List::Util;
use Test::More;
use Marpa::Test;

# Non-synopsis example in UrHTML.pod

BEGIN {
    if ( eval { require HTML::PullParser } ) {
        Test::More::plan tests => 11;
    }
    else {
        Test::More::plan skip_all => 'HTML::PullParser not available';
    }
    Test::More::use_ok('Marpa');
    Test::More::use_ok('Marpa::UrHTML');
} ## end BEGIN

# Marpa::Display
# name: 'UrHTML Pod: Handler Precedence'

my $html = <<'END_OF_HTML';
<span class="high">High Span</span>
<span class="low">Low Span</span>
<div class="high">High Div</div>
<div class="low">Low Div</div>
END_OF_HTML

my $result = Marpa::UrHTML::urhtml( \$html,
    {   q{*} => sub {
            return
            "wildcard handler, tagname: "
            . Marpa::UrHTML::tagname() . '; contents="'
            . Marpa::UrHTML::contents() . qq{"\n};
        },
        'head' => sub { return Marpa::UrHTML::literal() },
        'html' => sub { return Marpa::UrHTML::literal() },
        'body' => sub { return Marpa::UrHTML::literal() },
        'div' => sub {
            return '"div" handler: contents="' . Marpa::UrHTML::contents() . qq{"\n};
        },
        '.high' => sub {
            return '".high" handler, tagname: '
            . Marpa::UrHTML::tagname() . '; contents= "'
            . Marpa::UrHTML::contents() . qq{"\n};
        },
        'div.high' => sub {
            return '"div.high" handler, contents="'
                . Marpa::UrHTML::contents() . qq{"\n};
        },
    }
);

# Marpa::Display::End

# Marpa::Display
# name: 'UrHTML Pod: Handler Precedence Result'
# start-after-line: EXPECTED_RESULT
# end-before-line: '^EXPECTED_RESULT$'

my $expected_result = <<'EXPECTED_RESULT';
EXPECTED_RESULT

# Marpa::Display::End

Marpa::Test::is(
    ${$result}, $expected_result,
    'handler precedence example'
);
