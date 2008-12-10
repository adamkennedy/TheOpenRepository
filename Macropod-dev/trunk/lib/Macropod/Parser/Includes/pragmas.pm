package Macropod::Parser::Includes::pragmas;

use strict;
use warnings;

use Macropod::Util qw( dequote_list ppi_find_list );
use base qw( Macropod::Parser::Plugin );

use Carp qw( confess carp );
use Data::Dumper;

# Shamelessly copied from http://perldoc.perl.org/index-pragmas.html
our %known_pragmas = (
    attributes => 'get/set subroutine or variable attributes',
    attrs => 'set/get attributes of a subroutine (deprecated)',
    autouse => 'postpone load of modules until a function is used',

# see Macropod::Parser::Includes::base
#    base => 'Establish an ISA relationship with base classes at compile time',

    bigint => 'Transparent BigInteger support for Perl',
    bignum => 'Transparent BigNumber support for Perl',
    bigrat => 'Transparent BigNumber/BigRational support for Perl',
    blib => 'Use MakeMaker\'s uninstalled version of a package',
    bytes => 'Perl pragma to force byte semantics rather than character semantics',
    charnames => 'define character names for \N{named} string literal escapes',
    constant => 'Perl pragma to declare constants',
    diagnostics => 'produce verbose warning diagnostics',
    encoding => 'allows you to write your script in non-ascii or non-utf8',
    feature => 'Perl pragma to enable new syntactic features',
    fields => 'compile-time class fields',
    filetest => 'Perl pragma to control the filetest permission operators',
    if => 'use a Perl module if a condition holds',
    integer => 'Perl pragma to use integer arithmetic instead of floating point',
    less => 'perl pragma to request less of something',
    lib => 'manipulate @INC at compile time',
    locale => 'Perl pragma to use and avoid POSIX locales for built-in operations',
    mro => 'Method Resolution Order',
    open => 'perl pragma to set default PerlIO layers for input and output',
    ops => 'Perl pragma to restrict unsafe operations when compiling',
    overload => 'Package for overloading Perl operations',
    re => 'Perl pragma to alter regular expression behaviour',
    sigtrap => 'Perl pragma to enable simple signal handling',
    sort => 'perl pragma to control sort() behaviour',
    strict => 'Perl pragma to restrict unsafe constructs',
    subs => 'Perl pragma to predeclare sub names',
    threads => 'Perl interpreter-based threads',
    'threads::shared' => 'Perl extension for sharing data structures between threads',
    utf8 => 'Perl pragma to enable/disable UTF-8 (or UTF-EBCDIC) in source code',
    vars => 'Perl pragma to predeclare global variable names (obsolete)',
    vmsish => 'Perl pragma to control VMS-specific language features',
    warnings => 'Perl pragma to control optional warnings',
    'warnings::register' => 'warnings import function',

);


sub parse {
    my ($plugin,$doc,$class,$node) = @_;
    return 0 unless exists ( $known_pragmas{$class} );
   
    $doc->mk_accessors( 'pragmas' );
    my $args = $node->find( ppi_find_list );
    my @args  = ($args) ? dequote_list( $args->[0] ) : ();
    my $skip = 1;
    if ( $node->child(0) eq 'no' ) {
      $doc->add( 'pragmas' => 'disables' => { $class => \@args } ); 
    }
    elsif ( $node->child(0) eq 'use' ) {
      $doc->add( 'pragmas' => 'enables' => { $class => \@args } ); 
    }
    elsif ( $node->child(0) eq 'require' ) {
      $doc->add( 'pragmas' => 'runtime' => { $class => \@args } );
    }
    else { 
        carp sprintf( 'Cannot understand include statement \'%s\'' , $node->content );
        $skip = 0;
    }
    return $skip;
}


1;

