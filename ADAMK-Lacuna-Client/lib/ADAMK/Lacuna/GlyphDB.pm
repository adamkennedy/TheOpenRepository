package ADAMK::Lacuna::GlyphDB;

use strict;
use warnings;
use List::Util ();

use vars qw{ %BUILD2GLYPH %BUILD2ORDER %GLYPH2BUILD };
BEGIN {
	my $DATA = <<'END_DATA';
Algae Pond                      methane uraninite
Citadel of Knope                beryl galena monazite sulfur
Crashed Ship Site               bauxite gold monazite trona
Gas Giant Settlement Platform   anthracite galena monazite sulfur
Geo Thermal Vent                chalcopyrite sulfur
Interdimensional Rift           flourite methane zircon
Kalavian Ruins                  galena gold
Lapis Forest                    anthracite halite
Malcud Field                    flourite kerogen
Natural Spring                  halite magnetite
Pantheon of Hagness             anthracite beryl gypsum trona
Ravine                          flourite galena methane zircon
Temple of the Drajilites        chalcopyrite chromite kerogen rutile
Terraforming Platform           beryl magnetite methane zircon
Volcano                         magnetite uraninite
END_DATA

	foreach my $line ( split /\n/, $DATA ) {
		next unless $line =~ /\S/;
		my ($name, $glyphs) = split /\s{2,}/, $line;
		my @order = split /\s/, $glyphs;
		$BUILD2GLYPH{$name} = {};
		$BUILD2ORDER{$name} = [ @order ];
		foreach my $glyph ( split /\s/, $glyphs ) {
			$BUILD2GLYPH{$name}->{$glyph}++;
			$GLYPH2BUILD{$glyph}->{$name} = 1;
		}
	}
}





######################################################################
# High Level Methods

# Given a set of weighted building priorities, establish a weighted
# glyph type ratio.
sub priority2glyphs {
	my $class    = shift;
	my %priority = ();
	my %glyphs   = ();
	if ( @_ ) {
		%priority = @_;
	} else {
		# If given no priority, make it uniform
		%priority = map { $_ => 1 } $class->names;
	}
	foreach my $name ( sort keys %priority ) {
		my $need = $BUILD2GLYPH{$name} or die "Unknown building $name";
		foreach ( sort keys %$need ) {
			$glyphs{$_} += $need->{$_};
		}
	}
	return \%glyphs;
}

sub glyphs2buildable {
	my $class     = shift;
	my %have      = @_;
	my %buildable = ();
	foreach my $name ( sort keys %BUILD2GLYPH ) {
		my $need  = $BUILD2GLYPH{$name};
		my $multi = int List::Util::min(
			map {
				( $have{$_} || 0 ) / $need->{$_}
			} keys %$need
		) or next;
		$buildable{$name} = $multi;
	}
	return \%buildable;
}





######################################################################
# Lower Level Methods

sub names {
	my @names = sort keys %BUILD2GLYPH;
	return @names;
}

sub glyphs {
	my @glyphs = sort keys %GLYPH2BUILD;
	return @glyphs;
}

1;

__DATA__

Algae Pond                      methane uraninite
Citadel of Knope                beryl galena monazite sulfur
Crashed Ship Site               bauxite gold monazite trona
Gas Giant Settlement Platform   anthracite galena monazite sulfur
Geo Thermal Vent                chalcopyrite sulfur
Interdimensional Rift           flourite methane zircon
Kalavian Ruins                  galena gold
Lapis Forest                    anthracite halite
Malcud Field                    flourite kerogen
Natural Spring                  halite magnetite
Pantheon of Hagness             anthracite beryl gypsum trona
Ravine                          flourite galena methane zircon
Temple of the Drajilites        chalcopyrite chromite kerogen rutile
Terraforming Platform           beryl magnetite methane zircon
Volcano                         magnetite uraninite
