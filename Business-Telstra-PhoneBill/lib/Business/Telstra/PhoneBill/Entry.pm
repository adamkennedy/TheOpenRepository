package Business::Telstra::PhoneBill::Entry;

use 5.006001;
use strict;
use warnings;
use Data::Dumper;

our $VERSION = '0.01';
our $AUTHOR  = 'Renee Baecker (module@renee-baecker.de)';

#=================================#
# new creates a new object        #
#=================================#
sub new{
  my ($class) = @_;
  my $self = {};
    
  bless $self,$class;
  
  $self->{Fieldnames} = [qw(From_Number
                            Type
                            Date
                            Call_Time
                            Place
                            To_Number
                            Rate
                            Duration
                            Exclusive_GST
                            Inclusive_GST
                            Caller_Group
                           )];
  $self->fieldnames($self->{Fieldnames});
  
  return $self;
}# new

#=====================================#
# fieldnames set the names of the     #
# fields                              #
#=====================================#
sub fieldnames{
  my ($self,$names) = @_;
  $self->{Fieldmapping} = ();
  for(0..scalar(@$names)-1){
    $self->{Fieldmapping}->{$_} = $names->[$_];
  }
}# fieldnames

#========================================#
# fills the hash with fieldname => value #
#========================================#
sub fields{
  my ($self,$arrayref) = @_;
  my %fields = %{$self->{Fieldmapping}};
  for my $index(0..scalar(keys(%fields))-1){
    my $name = $fields{$index};
    $self->{Properties}->{$name} = $arrayref->[$index];
  }
  delete($self->{Fieldmapping});
  delete($self->{Fieldnames}  );
}# fields

#====================================#
# returns the value of a given field #
#====================================#
sub value{
  my ($self,$name) = @_;
  my $value = '';
  if(exists $self->{Properties}->{$name}){
    $value = $self->{Properties}->{$name};
  }
  return $value;
}# value

#====================================#
# returns the number                 #
#====================================#
sub from_number{
  my ($self) = @_;
  return $self->{Properties}->{From_Number};
}# from_number

#====================================#
# returns recipient's number         #
#====================================#
sub to_number{
  my ($self) = @_;
  return $self->{Properties}->{To_Number};
}# to_number

#====================================#
# returns the duration               #
#====================================#
sub duration{
  my ($self) = @_;
  return $self->{Properties}->{Duration};
}# duration

#====================================#
# returns the type                   #
#====================================#
sub type{
  my ($self) = @_;
  return $self->{Properties}->{Type};
}# type

#====================================#
# returns the date of the call       #
#====================================#
sub date{
  my ($self) = @_;
  return $self->{Properties}->{Date};
}# date

#====================================#
# returns the time of the call       #
#====================================#
sub call_time{
  my ($self) = @_;
  return $self->{Properties}->{Call_Time};
}# call_time

#====================================#
# returns the place                  #
#====================================#
sub place{
  my ($self) = @_;
  return $self->{Properties}->{Place};
}# place

#====================================#
# returns the rate of the call       #
#====================================#
sub rate{
  my ($self) = @_;
  return $self->{Properties}->{Rate};
}# rate

#====================================#
# returns price exclusive gst        #
#====================================#
sub exclusive_gst{
  my ($self) = @_;
  return $self->{Properties}->{Exclusive_GST};
}# exclusive_gst

#====================================#
# returns the price inclusive gst    #
#====================================#
sub inclusive_gst{
  my ($self) = @_;
  return $self->{Properties}->{Inclusive_GST};
}# inclusive_gst

#====================================#
# returns the caller group           #
#====================================#
sub caller_group{
  my ($self) = @_;
  return $self->{Properties}->{Caller_Group};
}# caller_group
 

1;