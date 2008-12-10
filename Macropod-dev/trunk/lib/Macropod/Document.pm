package Macropod::Document;

use strict;
use warnings;

use Carp qw( confess );
use PPI;
use YAML qw( Dump );
use PPI::Dumper;
use Data::Dumper;
use Pod::Simple::Search;


use base qw( Class::Accessor );

__PACKAGE__->mk_accessors( 'foo' );

#$Object::Accessor::FATAL = 1;
#$Object::Accessor::DEBUG = 1;

sub new {
  my ($class,@args) = @_;
  my $obj = $class->SUPER::new();

  $obj->mk_accessors(
	qw( 
		ppi
		title
		source
		pod
		macropod
		macros 
		
		packages 
		subs
		includes
		
		method
		inherits
		requires 
		imports
		exports
		
		processed
			
		
	)
);
$obj
}


=pod

=head1 NAME

Macropod::Document

=head1 DESCRIPTION

Represent a perl/pod source's macro document

=head1 SYNOPSIS

   $newdoc 		= Macropod::Document->create( 	name=>'Test::More' );
   $fromfile 	= Macropod::Document->open( 	'./lib/MyModule.pm' );
   $fromdata 	= Macropod::Document->open( 	\$buffer );
   $fromstream 	= Macropod::Document->open(		 $handle )
   
   @depends_on = $doc->depends;
   @required   = $doc->requires;
   @inherits   = $doc->inherits;
   
=head1 ACCESSORS

=head2 depends


=head2 requires


=head2 inherits


=head2 exports


=head2 methods


=head2 inherited_methods


=head1 METHODS


=head2 create

Create a new empty document.

=head2 open

Open an existing document

=head2 save

Save the current document

=head2 serialize 

Serialize the current document into YAML




=cut


sub create {
	my ($class,%args) = @_;
	my %self = ( 
	
				 );
	my $self = $class->new;
        foreach my $attr ( keys %args ) {
		if ( $self->can($attr) && defined $args{$attr} ) {
			 $self->$attr( $args{$attr} );
		}
	}
	return $self;

}

sub open {
	my ($class,%args) = @_;
        if ( defined $args{file} ) {
            my $data = YAML::LoadFile( $args{file} );
            my $doc = $class->create( %$data );
            return $doc;
        }
        else {
            confess "usage: Macropod::Document->open( 'path/to/file.macropod' )";
        }
	
}

sub signature {
	my $self = shift;
	return Macropod::Signature->digest( $self->yaml );
}

sub yaml {
	my ($self) = @_;
	confess unless ref $self;
	
	my %out = (
		methods  => $self->method,
		inherits => $self->inherits,
		requires => $self->requires,
		exports  => $self->exports,
		imports  => $self->imports,
		title  => $self->title,
		source => $self->source,
                pod    => $self->pod,
	);
	return YAML::Dump( \%out );
}


sub add {
	my ($self,$collect,$key,$meta) = @_;
	my $collector = $self->$collect;
	$collector ||= {};
	#warn "Got " . Dumper $collector . " for $collect";
	confess "NOMETA $collect=>$key '$meta' " unless $meta;
	if ( exists $collector->{$key} ) {
		my $old = $collector->{$key};
		#confess unless ref $old eq 'HASH';;
		my %new = ( %$old , %$meta );
		$collector->{$key} = \%new;
	}
	else {
		$collector->{$key} = $meta;
	}
	$self->$collect( $collector );

}


1;
