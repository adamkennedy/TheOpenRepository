package Kephra::Config::Tree;
$VERSION = '0.02';

# verbose config hash ops

use strict;

sub get_subtree{
	my $config = shift;
	my $path = shift;
	for (split '/', $path) {
		$config = $config->{$_} if defined $config->{$_}
	}
	return $config;
}
# -NI
sub diff {
	my $new = shift;
	my $old = shift;
	return my $diff;
}

sub merge {
	my $new = shift;
	my $old = shift;
	require Hash::Merge;
	Hash::Merge::set_behavior('LEFT_PRECEDENT');
	Hash::Merge::merge($new, $old);
}

# -NI
sub update {
	my $new = shift;
	my $old = shift;

}


1;