#!perl

use 5.010;
use strict;
use warnings;

use English qw( -no_match_vars );
use Fatal qw(open close);
use Text::Diff;
use Getopt::Long qw(GetOptions);
use Test::More;
use Carp;

use Marpa::Display;

my $warnings = 0;
my $options_result = GetOptions( 'warnings' => \$warnings );

Marpa::exception("$PROGRAM_NAME options parsing failed")
    if not $options_result;

sub normalize_whitespace {
    my $ref = shift;
    my $text    = ${$ref};
    $text =~ s/\A\s*//xms;
    $text =~ s/\s*\z//xms;
    $text =~ s/\s+/ /gxms;
    return \$text;
} ## end sub normalize_whitespace

my %exclude = map { ( $_, 1 ) } qw(
    Makefile.PL
    inc/Test/Weaken.pm
    sandbox/TODO.pod
);

my @test_files = @ARGV;
my $debug_mode = scalar @test_files;
if ( not $debug_mode ) {
    open my $manifest, '<', 'MANIFEST'
        or Marpa::exception("Cannot open MANIFEST: $ERRNO");
    FILE: while ( my $file = <$manifest> ) {
        chomp $file;
        $file =~ s/\s*[#].*\z//xms;
        next FILE if $exclude{$file};
        next FILE if -d $file;
        my ($ext) = $file =~ / [.] ([^.]+) \z /xms;
        next FILE if not defined $ext;
        $ext = lc $ext;
        next FILE
            if $ext ne 'pod'
                and $ext ne 'pl'
                and $ext ne 'pm'
                and $ext ne 't';

        push @test_files, $file;
    }    # FILE
    close $manifest;
} ## end if ( not $debug_mode )

Test::More::plan tests => 1 + scalar @test_files;

my $error_file;
## no critic (InputOutput::RequireBriefOpen)
if ($debug_mode) {
    open $error_file, '>&STDOUT'
        or Marpa::exception("Cannot dup STDOUT: $ERRNO");
}
else {
    open $error_file, '>', 'author.t/display.errs'
        or Marpa::exception("Cannot open display.errs: $ERRNO");
}
## use critic

my $display_data = Marpa::Display->new();

FILE: for my $file (@test_files) {
    if ( not -f $file ) {
        Test::More::fail("attempt to test displays in non-file: $file");
        next FILE;
    }
    $display_data->read($file);
    next FILE;

    my ( $mismatch_count, $mismatches ) =
        Marpa::Test::Display::test_file($file);
    my $clean = $mismatch_count == 0;

    my $message =
        $clean
        ? "displays match for $file"
        : "displays in $file has $mismatch_count mismatches";

    Test::More::ok( $clean, $message );
    next FILE if $clean;
    print {$error_file} "=== $file ===\n" . ${$mismatches}
        or Marpa::exception("print failed: $ERRNO");
} ## end for my $file (@test_files)

__END__

my $unused       = q{};
my $unused_count = 0;
while ( my ( $file_name, $displays ) = each %normalized_display_uses ) {
    DISPLAY: while ( my ( $display_name, $uses ) = each %{$displays} ) {
        next DISPLAY if $uses > 0;
        $unused .= "display '$display_name' in $file_name never used\n";
        $unused_count++;
    }
} ## end while ( my ( $file_name, $displays ) = each %normalized_display_uses)
if ($unused_count) {
    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
    Test::More::fail('$unused count displays not used');
    ## use critic
    print {$error_file} "=== UNUSED DISPLAYS ===\n" . $unused
        or Marpa::exception("print failed: $ERRNO");
} ## end if ($unused_count)
else {
    Test::More::pass('all displays used');
}
close $error_file;
