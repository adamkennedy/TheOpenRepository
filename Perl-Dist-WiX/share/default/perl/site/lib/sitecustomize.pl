#!perl

# This is to make sure that Strawberry has the new (5.11.0+) style
# order for the @INC directories, and other small @INC quibbles.
# Do not yell and scream if you break something here by changing
# or renaming this file, because "hyre be (miniature) dragones".

# Original order = 'core', 'site', 'vendor'.
# New order = 'site', 'vendor', 'core'

# Are we running under -t?
my $constant = ( q{.} eq $INC[-1] ) ? -4 : -3;

# Grab the variables we need.
my @x = @INC[$constant .. $constant + 2];
my $vendor = pop @x;
my $core = shift @x;

# Fix 'vendor' to look like the other 2.
$vendor =~ s{\\}{/}g;

# Portable needs relocating, and this code won't hurt D-drive versions.
if ('C:/strawberry/' ne substr $core, 0, 14 ) { 
    my $dir = substr $core, 0, -4; # peel off '/lib'
	$vendor = "$dir/vendor/lib";
}

# Do the reordering.
push @x, $vendor;
push @x, $core; 
splice @INC, $constant, 3, @x;
