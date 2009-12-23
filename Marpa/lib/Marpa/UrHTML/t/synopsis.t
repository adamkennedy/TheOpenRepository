#!perl

use 5.010;
use strict;
use warnings;
use English qw( -no_match_vars );
use List::Util;
use Test::More tests => 10;
use Marpa::Test;
use Test::More;

BEGIN {
    Test::More::use_ok('Marpa::UrHTML');
}

# This is just a dummy value for the synopsis
my %empty_elements = ();

# Marpa::Display
# name: UrHTML Synopsis

# Delete tables
my $with_table = 'Text<table><tr><td>I am a cell</table> More Text';
my $no_table = Marpa::UrHTML->new(
    {   table => sub { return q{} }
    }
)->parse( \$with_table );

# Delete everything but tables
my %handlers_to_keep_only_tables = (
    table  => sub { return Marpa::UrHTML::original() },
    ':TOP' => sub { return \( join q{}, @{ Marpa::UrHTML::child_values() } ) }
);
my $only_table =
    Marpa::UrHTML->new( \%handlers_to_keep_only_tables )
    ->parse( \$with_table );

# Marpa::UrHTML is smart about defective tables
my $with_bad_table = 'Text<tr>I am a cell</table> More Text';
my $only_bad_table =
    Marpa::UrHTML->new( \%handlers_to_keep_only_tables )
    ->parse( \$with_bad_table );

# Delete all comments
my $with_comment = 'Text <!-- I am a comment --> I am not a comment';
my $no_comment = Marpa::UrHTML->new(
    {   ':COMMENT' => sub { return q{} }
    }
)->parse( \$with_comment );

# Change the title
my $old_title = '<title>Old Title</title>A little html text';
my $new_title = Marpa::UrHTML->new(
    {   'title' => sub { return '<title>New Title</title>' }
    }
)->parse( \$old_title );

# Delete all elements in the class 'delete_me'
my $stuff_to_be_edited = '<p>A<p class="delete_me">B<p>C';
my $edited_stuff = Marpa::UrHTML->new(
    {   '.delete_me' => sub { return q{} }
    }
)->parse( \$stuff_to_be_edited );

# Marpa::UrHTML knows about missing tags and can supply them
sub supply_missing_tags {
    my $tagname = Marpa::UrHTML::tagname();
    return if $empty_elements{$tagname};
    return
          ( Marpa::UrHTML::start_tag() // "<$tagname>\n" )
        . Marpa::UrHTML::contents()
        . ( Marpa::UrHTML::end_tag() // "</$tagname>\n" );
} ## end sub supply_missing_tags
my $html_with_just_a_title = '<title>I am a title and That is IT!';
my $valid_html_with_all_tags =
    Marpa::UrHTML->new( { q{*} => \&supply_missing_tags } )
    ->parse( \$html_with_just_a_title );

# How deeply nested are the elements in this HTML?
sub depth_below_me {
    return List::Util::max( 0, @{ Marpa::UrHTML::child_values() } );
}

my @depths = map {
    Marpa::UrHTML->new(
        {   q{*}   => sub { return 1 + depth_below_me() },
            ':TOP' => sub { return depth_below_me() },
        }
        )->parse( \$_ )
} ( $html_with_just_a_title, ${$valid_html_with_all_tags} );

# Marpa::UrHTML counts elements whether with tags or not,
# both depths should be the same
my $depths_match = $depths[0] == $depths[1];

# Marpa::Display::End

my $expected_valid_html_with_all_tags = <<'END_OF_EXPECTED';
<html>
<head>
<title><title>I am a title and That is IT!</title>
</head>
<body>
</body>
</html>
END_OF_EXPECTED

Marpa::Test::is( ${$no_table}, 'Text More Text', 'delete tables' );
Marpa::Test::is(
    ${$only_table},
    '<table><tr><td>I am a cell</table>',
    'keep only tables'
);
Marpa::Test::is(
    ${$only_bad_table},
    '<tr>I am a cell</table>',
    'keep only tables -- bad table'
);
Marpa::Test::is(
    ${$no_comment},
    'Text  I am not a comment',
    'delete comments'
);
Marpa::Test::is(
    ${$new_title},
    '<title>New Title</title>A little html text',
    'replace title'
);
Marpa::Test::is( ${$edited_stuff}, '<p>A<p>C', 'delete by class name' );
Marpa::Test::is(
    ${$valid_html_with_all_tags},
    $expected_valid_html_with_all_tags,
    'supply tags'
);
Marpa::Test::is( $depths[0], 3,          'compute maximum depth' );
Marpa::Test::is( $depths[0], $depths[1], 'depths match' );
