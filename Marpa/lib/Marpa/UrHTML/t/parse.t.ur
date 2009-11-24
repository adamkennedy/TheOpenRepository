#!perl

use strict;
use warnings;

# These tests are based closely on those in the HTML-Tree module,
# the authors of which I grately acknowledge.

use Test::More;
my $DEBUG = 2;
BEGIN { plan tests => 40 }

use Marpa::UrHTML;

my $urhtml_args = {
    trace_handlers => 1,
    handlers => [
        [   q{*} => sub {
                my $tagname = Marpa::UrHTML::tagname();
                say STDERR "In handler for $tagname element";
                Carp::croak('Not in an element') if not $tagname;
                my ( $start_tag, $contents, $end_tag ) =
                    Marpa::UrHTML::element_parts();
                $start_tag //= "<$tagname>";
                $end_tag   //= "</$tagname>";
                $contents =~ s/\A [\x{20}\t\f\x{200B}]+ //xms;
                $contents =~ s/ [\x{20}\t\f\x{200B}]+ \z//xms;
                return join q{}, $start_tag, $contents, $end_tag;
                }
        ]
    ]
};

Test::More::ok 1;

{
  my $parse = Marpa::UrHTML->new($urhtml_args);
  my $value = $parse->parse(\'<title>foo</title><p>I like pie');
  Test::More::ok($value,
   "<html><head><title>foo</title></head><body>"
   ."<p>I like pie</p></body></html>\n"
  );
}

Test::More::ok !same('x' => 'y', 1);
Test::More::ok !same('<p>' => 'y', 1);

Test::More::ok same('' => '');
Test::More::ok same('' => ' ');
Test::More::ok same('' => '  ');

Test::More::ok same('' => '<!-- tra la la -->');
Test::More::ok same('' => '<!-- tra la la --><!-- foo -->');

Test::More::ok same('' => \'<head></head><body></body>');

Test::More::ok same('<head>' => '');

Test::More::ok same('<head></head><body>' => \'<head></head><body></body>');

Test::More::ok same( '<img alt="456" src="123">'  => '<img src="123" alt="456">' );
Test::More::ok same( '<img alt="456" src="123">'  => '<img src="123"    alt="456">' );
Test::More::ok same( '<img alt="456" src="123">'  => '<img src="123"    alt="456"   >' );

Test::More::ok !same( '<img alt="456" >'  => '<img src="123"    alt="456"   >', 1 );

Test::More::ok same( 'abc&#32;xyz'   => 'abc xyz' );
Test::More::ok same( 'abc&#x20;xyz'  => 'abc xyz' );

Test::More::ok same( 'abc&#43;xyz'   => 'abc+xyz' );
Test::More::ok same( 'abc&#x2b;xyz'  => 'abc+xyz' );

Test::More::ok same( '&#97;bc+xyz'   => 'abc+xyz' );
Test::More::ok same( '&#x61;bc+xyz'  => 'abc+xyz' );

print "#\n# Now some list tests.\n#\n";

Test::More::ok same('<ul><li>x</ul>after'      => '<ul><li>x</li></ul>after');
Test::More::ok same('<ul><li>x<li>y</ul>after' => '<ul><li>x</li><li>y</li></ul>after');

Test::More::ok same('<ul> <li>x</li> <li>y</li> </ul>after' => '<ul><li>x</li><li>y</li></ul>after');

Test::More::ok same('<ul><li>x<li>y</ul>after' => 
 \'<head></head><body><ul><li>x</li><li>y</li></ul>after</body>');

print "#\n# Now some table tests.\n#\n";

Test::More::ok same('<table>x<td>y<td>z'
        => '<table><tr><td>x</td><td>y</td><td>z</td></table>');

Test::More::ok same('<table>x<td>y<tr>z'
        => '<table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>');


Test::More::ok same(    '<table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>'
        =>  '<table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>');
Test::More::ok same(    '<table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>'
        =>  \'<head></head><body><table><tr><td>x</td><td>y</td></tr><tr><td>z</td></tr></table>');

Test::More::ok same('<table>x'      => '<td>x');
Test::More::ok same('<table>x'      => '<table><td>x');
Test::More::ok same('<table>x'      => '<tr>x');
Test::More::ok same('<table>x'      => '<tr><td>x');
Test::More::ok same('<table>x'      => '<table><tr>x');
Test::More::ok same('<table>x'      => '<table><tr><td>x');

print "#\n# Now some p tests.\n#\n";

Test::More::ok same('<p>x<p>y<p>z'      => '<p>x</p><p>y</p><p>z');
Test::More::ok same('<p>x<p>y<p>z'      => '<p>x</p><p>y<p>z</p>');
Test::More::ok same('<p>x<p>y<p>z'      => '<p>x</p><p>y</p><p>z</p>');
Test::More::ok same('<p>x<p>y<p>z'      => \'<head></head><body><p>x</p><p>y</p><p>z</p>');


sub same {
    my ( $code1, $code2, $flip ) = @_;
    my $p1 = Marpa::UrHTML->new;
    my $p2 = Marpa::UrHTML->new;

    if (ref $code1) { $code1 = ${$code1} }
    if (ref $code2) { $code2 = ${$code2} }

    my $value1 = $p1->parse(\$code1);
    my $value2 = $p2->parse(\$code2);

    if ( not defined $value1 ) { print "No parse for $code1"; return $flip; }
    if ( not defined $value2 ) { print "No parse for $code2"; return $flip; }

    my $out1 = ${${$value1}};
    my $out2 = ${${$value2}};

    my $rv = ( $out1 eq $out2 );

    #print $rv? "RV TRUE\n" : "RV FALSE\n";
    #print $flip? "FLIP TRUE\n" : "FLIP FALSE\n";

    if ( $flip ? ( !$rv ) : $rv ) {
        if ( $DEBUG > 2 ) {
            print
                "In1 $code1\n",
                "In2 $code2\n",
                "Out1 $out1\n",
                "Out2 $out2\n",
                "\n\n";
        } ## end if ( $DEBUG > 2 )
    } ## end if ( $flip ? ( !$rv ) : $rv )
    else {
        local $_;
        foreach my $line (
            '',
            "The following failure is at " . join( ' : ', caller ),
            "Explanation of failure: "
            . ( $flip ? 'same' : 'different' )
            . " parse trees!",
            "Input code 1:",
            $code1,
            "Input code 2:",
            $code2,
            "Output tree (as XML) 1:",
            $out1,
            "Output tree (as XML) 2:",
            $out2,
            )
        {
            $_ = $line;
            s/\n/\n# /g;
            print "# ", $_, "\n";
        } ## end foreach my $line ( '', "The following failure is at " . join...)
    } ## end else [ if ( $flip ? ( !$rv ) : $rv ) ]

    return $rv;
} ## end sub same


