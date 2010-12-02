package ADAMK::Lacuna::Bot;

# Modular Lacuna automation framework

use 5.008;
use strict;
use warnings;
use Params::Util ();

our $VERSION = '0.01';

sub new {
  my $class = shift;

  # Boot the bot harness
  my $self = bless {
    plugins => [ ],
  }, $class;

  while ( @_ ) {
    my $driver = shift;
    if ( Params::Util::_IDENTIFIER($driver) ) {
      $driver = "ADAMK::Lacuna::Bot::$driver";
    }
    unless ( Params::Util::_DRIVER($driver, 'ADAMK::Lacuna::Bot::Plugin') ) {
      die "Missing or invalid bot plugin class '$driver'";
    }
    my $plugin = $driver->new( shift );
    unless ( $plugin ) {
      die "Failed to create $driver plugin object";
    }
    push @{ $self->{plugins} }, $plugin;
  }

  return $self;
}

sub run {
  my $self   = shift;
  my $client = shift;
  unless ( Params::Util::_INSTANCE($client, 'ADAMK::Lacuna::Client') ) {
    die "Did not provide a client object to run";
  }

  # Process the plugins
  my $i       = 0;
  my $plugins = $self->{plugins};
  foreach my $plugin ( @$plugins ) {
    print scalar(localtime time) . ' - ' . ++$i . " of " . scalar(@$plugins) . " - Executing plugin " . ref($plugin) . "\n";
    $plugin->run( $client );
  }

  return 1;
}

1;
