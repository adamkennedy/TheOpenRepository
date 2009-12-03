package Marpa::Display;

use 5.010;
use strict;
use warnings;
use integer;
use Fatal qw(open close);
use YAML::XS;
use Data::Dumper; # for debugging

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub read {
    my ( $self, $data_arg, $name ) = @_;
    my @lines;
    GET_LINES: {
        if ( not ref $data_arg ) {
            $name //= $data_arg;
            open my $fh, q{<}, $data_arg;
            @lines = <$fh>;
            close $fh;
            last GET_LINES;
        } ## end if ( not ref $data_arg )
        $name //= "?";
        @lines = split "\n", ${$data_arg};
    } ## end GET_LINES:
    chomp @lines;
    for my $zero_based_line ( 0 .. $#lines ) {
        my $line = $lines[$zero_based_line];

        my $display_spec = {};
        my $line_number = $zero_based_line + 1;
        if ( $line =~ /^[#] \s+ Marpa[:][:]Display/xms ) {
            say STDERR "Found at $name, line $line_number: $line";
            my $yaml = q{};
            while ( ( my $yaml_line = $lines[ ++$zero_based_line ] )
                =~ /^[#]/xms )
            {
                $yaml .= "$yaml_line\n";
            }
            if ($yaml =~ / \S /xms) {
                $yaml =~ s/^ [#] \s? //xmsg;
                local $@;
                my $eval_ok =
                    eval { $display_spec = YAML::XS::Load($yaml); 1 };
                if ( not $eval_ok ) {
                    say STDERR $@;
                    say STDERR
                        "Fatal error in YAML Display spec at $name, line "
                        . ( $line_number + 2 );
                } ## end if ( not $eval_ok )
            }
            print STDERR "YAML: ", Data::Dumper::Dumper($display_spec);
        } ## end if ( $line =~ /^[#] \s+ Marpa[:][:]Display/xms )
        if ( $line =~ /^[=]for \s+ Marpa[:][:]Display/xms ) {
            say STDERR "Found at $name, line $line_number: $line";
            my $yaml = q{};
            while (
                ( my $yaml_line = $lines[ ++$zero_based_line ] ) =~ /\S/xms )
            {
                $yaml .= "$yaml_line\n";
            }
            if ( $yaml =~ / \S /xms ) {
                local $@;
                my $eval_ok =
                    eval { $display_spec = YAML::XS::Load($yaml); 1 };
                if ( not $eval_ok ) {
                    say STDERR $@;
                    say STDERR
                        "Fatal error in YAML Display spec at $name, line "
                        . ( $line_number + 2 );
                } ## end if ( not $eval_ok )
            } ## end if ( $yaml ~= / \S /xms )
            print STDERR "YAML: ", Data::Dumper::Dumper($display_spec);
        } ## end if ( $line =~ /^[=]for \s+ Marpa[:][:]Display/xms )
    } ## end for my $zero_based_line ( 0 .. $#lines )
} ## end sub read

1;
