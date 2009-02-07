#!perl

use Pod::Parser;
use warnings;
use strict;
use English qw( -no_match_vars );
use Fatal qw(open close);
use Text::Diff;
use Carp;
use Getopt::Long qw(GetOptions);

my $warnings = 0;
my $result = GetOptions("warnings"  => \$warnings);
croak("$PROGRAM_NAME options parsing failed")
    unless $result;

our $preamble   = q{};
our $in_command = 0;
our @display;
our $default_code             = q{ no_code_defined($_) };
our $current_code             = $default_code;
our $collecting_from_line_num = -1;
our $collected_display;
our $command_countdown = 0;
our $current_file      = '!!! NO CURRENT FILE !!!';
our $display_skip      = 0;

sub no_code_defined {
    my $display = shift;
    return 'No code defined to test display:';
}

my %raw                 = ();
my %normalized          = ();
my %raw_display         = ();
my %normalized_display  = ();

sub normalize_whitespace {
    my $raw_ref = shift;
    my $text = ${$raw_ref};
    $text =~ s/\A\s*//xms;
    $text =~ s/\s*\z//xms;
    $text =~ s/\s+/ /gxms;
    \$text;
}

sub slurp {
    open( my $fh, '<', shift );
    local ($RS) = undef;
    return \<$fh>;
}

sub parse_displays {
    my $raw_ref = shift;

    my $result = {};

    while (
        my ( $display_name, $display_text ) = (
            ${$raw_ref} =~ m/
               ^ [ \t]* [#] \h* [#] [\h#]* use [ \t]+ Marpa[:][:]Test[:][:]Display \h+ (\w+) \h* $
               (.*?)
               ^ [ \t]* [#] \h* [#] [\h#]* no [ \t]+ Marpa[:][:]Test[:][:]Display \h* $
           /xmsgc
        )
      )
    {
        $result->{$display_name} = \$display_text;
    }

    return $result;

}

sub read_file {
    my $file_name    = shift;
    my $display_name = shift;

    my $file_ref = $normalized{$file_name};
    if (not defined $file_ref) {
        my $raw_ref = $raw{$file_name} = slurp($file_name);
        $file_ref = $normalized{$file_name} = normalize_whitespace($raw_ref);
        my $raw_display = $raw_display{$file_name} = parse_displays($raw_ref);
        for my $raw_display_name (keys %{$raw_display}) {
            $normalized_display{$file_name}{$raw_display_name}
                = normalize_whitespace($raw_display->{$raw_display_name})
        }
    }
    return $file_ref
        if not defined $display_name;
    my $display_ref = $normalized_display{$file_name}{$display_name};
    if (not defined $display_ref) {
        croak("No display named '$display_name' in file: $file_name");
    }
    $normalized_display{$file_name}{$display_name}++;
    $display_ref;
}

sub in_file {
    my ($pod_display, $file_name, $display_name) = @_;

    my $pod_display_ref  = normalize_whitespace(\$pod_display);
    my $file_display_ref = read_file($file_name, $display_name);

    my $location = index( ${$file_display_ref}, ${$pod_display_ref} );

    return (
        (
            $location >= 0
            ? ""
            : "Display in $::current_file not in $file_name\n" . $pod_display
        ),
        1
    );

}

sub is_file {
    my ($pod_display, $file_name, $display_name) = @_;

    my $pod_display_ref  = normalize_whitespace(\$pod_display);
    my $file_display_ref = read_file($file_name, $display_name);

    return "" if ${$file_display_ref} eq ${$pod_display_ref};

    my $raw_file_display =
      defined $display_name
      ? $raw_display{$file_name}{$display_name}
      : $raw{$file_name};

    $pod_display =~ s/^\h*//gxms;
    ${$raw_file_display} =~ s/^\h*//gxms;

    return (
        (
            "Display in $::current_file differs from the one in $file_name"
              . ( diff \$pod_display, $raw_file_display, { STYLE => 'Table' } )
        ),
        1
    );

}

package MyParser;
@MyParser::ISA = qw(Pod::Parser);
use Carp;

sub queue_display {
    my $display  = shift;
    my $line_num = shift;
    push @::display,
        {
        'display' => $display,
        'code'    => $::current_code,
        'file'    => $::current_file,
        'line'    => $line_num,
        }
        if not $::display_skip;
    $::command_countdown--;
    if ( $::command_countdown <= 0 ) {
        $::current_code = $::default_code;
        $::display_skip = 0;
    }
}

sub verbatim {
    my ( $parser, $paragraph, $line_num ) = @_;

    if ( defined $::collected_display ) {
        $::collected_display .= $paragraph;
        $::collecting_from_line_num //= $line_num;
        return;
    }
    queue_display( $paragraph, $line_num );
}

sub process_instruction {
    my $instruction = shift;
    my $code        = shift;
    my $line_num    = shift;

    $instruction =~ s/\s$//;     # eliminate trailing whitespace
    $instruction =~ s/\s/ /g;    # normalize whitespace
    if ($instruction =~ /^next display$/) {
        $::command_countdown = 1;
        $::current_code = join( "\n", @{$code} );
    } elsif ($instruction =~ /^next\s+(\d+)\s+display(s)?$/) {
        $::command_countdown = $1;
        croak(
            "File: $::current_file  Line: $line_num\n",
            "  'next $::command_countdown display' has countdown less than one\n"
        ) unless $::command_countdown >= 1;
        $::current_code = join( "\n", @{$code} );
            $::default_code = join( "\n", @{$code} );
            $::current_code = $::default_code if $::command_countdown <= 0;
    } elsif ($instruction =~ /^preamble$/) {
        $::preamble .= join( "\n", @{$code} );
    } elsif ($instruction =~ /^skip display$/) {
        $::command_countdown = 1;
        $::display_skip++;
    } elsif ($instruction =~ /^skip (\d+) display(s)?$/) {
        $::command_countdown = $1;
        croak(
            "File: $::current_file  Line: $line_num\n",
            "  'display $::command_countdown skip' has countdown less than one\n"
        ) unless $::command_countdown >= 1;
        $::display_skip++;
    } elsif ($instruction =~ /^start\s+display$/) {
        $::collected_display = q{};
    } elsif ($instruction =~ /^end\s+display$/) {
        # line num will be set when first part of display is found
        queue_display( $::collected_display,
            $::collecting_from_line_num );
        $::collected_display        = undef;
        $::collecting_from_line_num = -1;
    } else {
        croak(
            "File: $::current_file  Line: $line_num\n",
            "  unrecognized instruction: '$_'\n"
        );
    }
}

sub textblock {
    return unless $in_command;
    my ( $parser, $paragraph, $line_num ) = @_;

    ## Translate/Format this block of text; sample actions might be:

    my @lines = split /\n/, $paragraph;
    my $found_instruction = 0;
    LINE: while ( my $line = shift @lines ) {
        next LINE if $line =~ /^\s*$/xms;    # skip whitespace
        if ( $line =~ /^[#][#]/xms ) {
            $line =~ s/^[#][#]\s*//;
            process_instruction( $line, \@lines, $line_num );
            $found_instruction = 1;
            next LINE;
        }
        croak( "File: $::current_file  Line: $line_num\n",
            "test block doesn't begin with ## instruction\n$paragraph" )
            if not $found_instruction;
        last LINE;
    }

    return;

}

sub interior_sequence { }

sub command {

    my ( $parser, $command, $paragraph ) = @_;
    if ($command eq 'begin') {
        $in_command++ if $paragraph =~
            /
                \A
                Marpa[:][:]Test[:][:]Display[:]
                \s* \Z
            /xms;
        $in_command++ if $paragraph =~ /\Amake:$/xms;
    }
    elsif ($command eq 'end') {
        $in_command = 0;
    }

}

package main;

my %exclude = map { ( $_, 1 ) } qw(
    Changes
    MANIFEST
    META.yml
    Makefile.PL
    README
    etc/perlcriticrc
    etc/perltidyrc
    etc/last_minute_check.sh
);

my $parser = new MyParser();

open my $manifest, '<', '../MANIFEST'
    or croak("open of MANIFEST failed: $ERRNO");

FILE: while ( my $file = <$manifest> ) {
    chomp $file;
    $file =~ s/\s*[#].*\z//xms;
    next FILE if $file =~ /.pod\z/xms;
    next FILE if $file =~ /.marpa\z/xms;
    next FILE if $file =~ /\/Makefile\z/xms;
    next FILE if $exclude{$file};
    $file = '../' . $file;
    next FILE if -d $file;
    croak("No such file: $file") unless -f $file;

    $::current_file      = $file;
    @::display           = ();
    $::default_code      = q{ no_code_defined($_) };
    $::current_code      = $default_code;
    $::command_countdown = 0;
    $::display_skip      = 0;
    my $problems = 0;

    $parser->parse_from_file($file);
    eval $preamble;
    croak($EVAL_ERROR) if $EVAL_ERROR;

    for my $display_test (@::display) {
        my ( $display, $code, $file, $line ) =
            @{$display_test}{qw(display code file line)};
        local $_ = $display;
        my $result = eval '[ ' . $code . ' ] ';
        croak($EVAL_ERROR) unless $result;
        my $message = $result->[0];
        if ($message) {
            my $do_not_add_display = $result->[1];
            unless ($do_not_add_display) {
                $message .= "\n$display";
            }
            print "=== $message";
            $problems++;
        }
    }    # $display_test
    print $problems, " display blocks with problems in $file\n"
        if $problems > 0;
}

exit unless $warnings;

while (my ($file_name, $displays) = each %normalized_display) {
    while (my ($display_name, $uses) = each %{$displays}) {
        next DISPLAY if $uses > 0;
        print "display '$display_name' in $file_name never used\n";
    }
}
