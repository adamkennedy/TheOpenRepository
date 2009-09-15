#!perl

my $constant = ( q{.} eq $INC[-1] ) ? -4 : -3;

# Original order = 'core', 'site', 'vendor'.
# New order = 'site', 'vendor', 'core'
my @x = @INC[$constant .. $constant + 2];
my $core = shift @x;
push @x, $core; 
splice @INC, $constant, 3, @x;
