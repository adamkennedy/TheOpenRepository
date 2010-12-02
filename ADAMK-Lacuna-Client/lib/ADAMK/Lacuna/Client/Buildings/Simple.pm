package ADAMK::Lacuna::Client::Buildings::Simple;

use 5.008;
use strict;
use warnings;
use Carp 'croak';

use ADAMK::Lacuna::Client;
use ADAMK::Lacuna::Client::Module;
use Class::MOP;

our @BuildingTypes = (
  qw(
    AlgaePond
    AlgaeCropper
    AppleOrchard
    Bean
    Beeldeban
    Bread
    Burger
    Capitol
    Cheese
    Chip
    Cider
    CloakingLab
    CornPlantation
    CornMeal
    Crater
    DairyFarm
    Denton
    EnergyReserve
    EntertainmentDistrict
    EspionageMinistry
    EssentiaVein
    Fission
    FoodReserve
    FusionReactor
    GasGiantLab
    GasGiantPlatform
    GeneticsLab
    GeoEnergyPlant
    GeoThermalVent
    Grove
    HydrocarbonEnergyPlant
    InterdimensionalRift
    KalavianRuins
    Lake
    Lagoon
    Lapis
    LibraryOfJith
    LuxuryHousing
    MalcudFungusFarm
    MassadsHenge
    Mine
    MissionCommand
    MunitionsLab
    NaturalSpring
    OracleOfAnid
    OreRefinery
    OreStorageTanks
    Oversight
    Pancake
    Pie
    PilotTrainingFacility
    PotatoPatch
    PropulsionSystemFactory
    RockyOutcropping
    Sand
    Shake
    SingularityEnergyPlant
    Soup
    Stockpile
    SubspaceSupplyDepot
    Syrup
    TempleOfTheDrajilites
    TerraformingLab
    TerraformingPlatform
    University
    Volcano
    WasteEnergyPlant
    WasteSequestrationWell
    WasteDigester
    WasteTreatmentCenter
    WaterProductionPlant
    WaterPurificationPlant
    WaterReclamationFacility
    WaterStorageTank
    WheatFarm
  ),
);

sub init {
  my $class = shift;
  foreach my $type ( @BuildingTypes ) {
    my $bclass = "ADAMK::Lacuna::Client::Buildings::$type";
    Class::MOP::Class->create(
      $bclass => (
        superclasses => [
          'ADAMK::Lacuna::Client::Buildings'
        ],
      )
    );
  }
}

__PACKAGE__->init();

1;

__END__

=pod

=head1 NAME

ADAMK::Lacuna::Client::Buildings::Simple - All the simple buildings

=head1 SYNOPSIS

  use ADAMK::Lacuna::Client;

=head1 DESCRIPTION

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
