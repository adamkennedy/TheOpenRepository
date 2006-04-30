package Algorithm::Graph;

=pod

=head1 NAME

Algorithm::Graph - The successor to Algorithm::Dependency, based on Higher-Order Perl techniques

=head1 SYNOPSIS

  # A simple identifier-based graph
  my $basic_graph => Algorithm::Graph->new(
      # Short-syntax declaration
      property_foo  => [ boolean => \&is_installed ],
  
      # Full-syntax declaration
      property_bar => {
          type  => 'numeric',
          using => sub { get_value($_[0]) * 2 },
      },
  
      # Define an edge to other vectors
      edge_baz => {
          type  => 'edge',
          using => \&children,
      },
  );
  
  # An more complex object-based graph
  my $object_graph = Algorithm::Graph->new(
      # Mapping from objects to identifiers
      OBJECT => {
          singular_from => sub { My::Class->find($_[0]) },
          singular_to   => sub { $_[0]->id },
      },
  
      property_foo => {
          type  => 'number',
          from  => 'object', # Derived from 'object' or 'id'?
          using => sub { $_[0]->property_name },
      },
  
      edge_bar => {
          type  => 'edge',
          from  => 'object',
          to    => 'id',
          using => sub { $_[0]->children },
      },
  );

=head1 DESCRIPTION

B<Algorithm::Graph> is the successor to Algorithm::Dependency

=cut

use strict;

