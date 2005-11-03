package Business::Telstra::PhoneBill;

use 5.006001;
use strict;
use warnings;
use Tie::File;
use File::Type;
use Text::CSV_XS;
use Business::Telstra::PhoneBill::Entry;
use Archive::Zip qw(:CONSTANTS :ERROR_CODES);

our $VERSION = '0.01';

#===========================================================#
# new creates a new object                                  #
# Options:                                                  #
#   * -filename => File (zip | csv)                         #
#   * -colnames => 1: csv-file contains names in first line #
#                  0: does not...                           #
#          default: 1                                       #
#   * -sep_char => the fieldseparator in the csv-file       #
#          default: ,                                       #
#===========================================================#
sub new{
  my ($class,%args) = @_;
  my $self = {};
  
  bless $self,$class;
  
  $self->{ArchiveZip} = Archive::Zip->new();
  
  $self->{FirstLine}  = $args{-colnames} && $args{-colnames} == 0 ? 0 : 1;
  $self->{Separator}  = $args{-sep_char} || ','; 
  
  my $filename = $args{-file};
  
  if($filename && -e $filename){
    my $filetype = $self->_check_file($filename);
    $self->{FileType} = $filetype;
    if($filetype eq 'application/zip'){
      $self->{Members} = $self->_unzip_archive($filename);
    }
    elsif($filetype eq 'application/octet-stream'){
      $self->{Members} = $self->_parse_bill($filename);
    }
    else{
      print STDERR "No valid MIME-Type\n";
    }
  }
  
  if($filename && not -e $filename){
    print STDERR "File $filename does not exist\n";
  }
  
  return $self;
}# new

#================================#
# sets the file of the object and#
# parse it                       #
#================================#
sub file{
  my ($self,$filename) = @_;
  
  if($filename && -e $filename){
    my $filetype = $self->_check_file($filename);
    $self->{FileType} = $filetype;
    if($filetype eq 'application/zip'){
      $self->{Members} = $self->_unzip_archive($filename);
    }
    elsif($filetype eq 'application/octet-stream'){
      $self->{Members} = $self->_parse_bill($filename);
    }
    else{
      print STDERR "No valid MIME-Type\n";
    }
  }
  
  if($filename && not -e $filename){
    print STDERR "File $filename does not exist\n";
  }
  
  1;
}# file

#==================================#
# set the fieldseparator of the    #
# csv-file (default: ,)            #
#==================================#
sub set_separator{
  my ($self,$sepchar) = @_;
  $sepchar = undef if(length($sepchar) != 1);
  $self->{Separator} = $sepchar || ',';
}# set_separator

#=====================================#
# if colnames is set to 0, the csv-   #
# file does not contain columnnames   #
# in its first line                   #
#=====================================#
sub colnames{
  my ($self,$value) = @_;
  $self->{FirstLine} = $value == 0 ? 0 : 1;
}# colnames

#=====================================#
# if format of the csv changes, a new #
# fieldorder can be set, it has to    #
# include the standard fieldnames     #
#=====================================#
sub set_fieldorder{
  my ($self,$fieldnames) = @_;
  if(defined $fieldnames && ref($fieldnames) eq 'ARRAY'){
    $self->{Fieldorder} = $fieldnames;
  }
}# set_fieldorder

#===================================#
# help function to find specific    #
# entries                           #
# it provides the following types:  #
#  * like (RegExp-Match)            #
#  * greater                        #
#  * lower                          #
# there are actually two special    #
# fieldtypes that are supportet:    #
#  * date (for greater and lower)   #
#  * time (for greater and lower)   #
#===================================#
sub find_entries{
  my ($self,$field,$value,$type,$fieldtype) = @_;

  return undef unless(defined $field && defined $value);

  my %monthshash = (jan => 0, feb => 1, mar => 2, apr => 3, may  => 4, jun => 5,
                  jul => 6, aug => 7, sep => 8, oct => 9, nov  => 10, dec => 11);
                  
  # preprocess the data due to the chosen fieldtype
  $fieldtype ||= 'not specific';
  my @tmp_entries;
  if($fieldtype eq 'date'){
    # reformat the date-field to the format "MMDD"
    my ($v_day,$v_mon) = $value =~ /(\d+)\s*(\w+)/;
    $value = sprintf("%02d",$monthshash{lc $v_mon}) . $v_day;
    for my $entry(@{$self->{Members}}){
      my $date = $entry->date;
      next unless(defined $date);
      my ($day,$mon) = $date =~ /(\d+)\s*(\w+)/;
      next unless($day && $mon);
      $date = sprintf("%02d",$monthshash{lc $mon}) . $day;
      push(@tmp_entries,[$entry,$date]);
    }
  }
  elsif($fieldtype eq 'time'){
    # reformat the time-field to the format "HHMM" in 24-hour-format
    my ($t_hour,$t_min,$t_daytime) = $value =~ /(\d+):(\d+)\s*(\w+)/;
    $value = $t_daytime eq 'pm' ? ($t_hour+12).$t_min : $t_hour.$t_min;
    for my $entry(@{$self->{Members}}){
      my $time = $entry->call_time;
      next unless(defined $time);
      my ($hour,$min,$daytime) = $time =~ /(\d+):(\d+)\s*(\w+)/;
      next unless($hour && $min && $daytime);
      $time = $daytime eq 'pm' ? ($hour+12).$min : $hour.$min;
      push(@tmp_entries,[$entry,$time]);
    }
  }
  else{
    @tmp_entries = map{[$_,$_->value($field)]}@{$self->{Members}};
  }
    
  # find values in dependency to the type of filter
  my @entries;
  unless($type){
    @entries = grep{defined $_->value($field) && 
                      $_->value($field) eq $value
                   }@{$self->{Members}};
  }
  elsif($type eq 'like'){
    @entries = grep{defined $_->value($field) && 
                      $_->value($field) =~ /\Q$value\E/si
                   }@{$self->{Members}};
  }
  elsif($type eq 'greater'){
    @entries = map{$_->[0]}
                 grep{defined $_->[1] && 
                        $_->[1] gt $value
                     }@tmp_entries;
  }
  elsif($type eq 'lower'){
    @entries = map{$_->[0]}
                 grep{defined $_->[1] && 
                        $_->[1] lt $value
                     }@tmp_entries;
  }
  
  return \@entries;
}# find_entries

#=================================#
# returns a copy of the entries-  #
# array                           #
#=================================#
sub entries{
  my ($self,$index) = @_;
  my $ref = defined $index ? $self->{Members}->[$index-1] : $self->{Members};
  return $ref;
}# entries

#=================================#
# returns the filetype of the     #
# last parsed file                #
#=================================#
sub filetype{
  my ($self) = @_;
  return $self->{FileType};
}# filetype

#=================================#
# _check_file checks whether the  #
# given file is an archive or not #
# Parameter: filename             #
#=================================#
sub _check_file{
  my ($self,$file) = @_;
  my $filetype     = '';

  my $ft = File::Type->new();
  $filetype = $ft->mime_type($file);
  
  return $filetype;
}# _check_file


#=================================#
# _unzip_archive reads the content#
# of the zipped csv-files and     #
# creates new entries             #
#=================================#
sub _unzip_archive{
  my ($self,$zip_file) = @_;
  my $archive = $self->{ArchiveZip};
  my @entries;
  Archive::Zip::setErrorHandler(sub{});
  if($archive->read($zip_file) == AZ_OK){
    my @members = $archive->memberNames();
    for my $member(@members){

      #my $newline = $/;
      ## localize the newlines
      #my $content = $archive->contents($member);
      #$content =~ s/\015{1,2}\012|\015|\012/$newline/g;
      ## creating new entry-objects
      #my @new_entries = _create_entries($self,[split(/$newline/,$archive->contents($member))]);
      #push(@entries,@new_entries);
      open(my $fh,">$member") or die $!;
      print $fh $archive->contents($member);
      close $fh;
      push(@entries,@{_parse_bill($self,$member)});
      unlink($member);
    }
  }
  return \@entries;
}# _unzip_archive

#================================================#
# _parse_bill localizes the newlines of the      #
# csv-file and creates new entries               #
#================================================#
sub _parse_bill{
  my ($self,$csv_file) = @_;
  
  # localize the newlines
  tie my @array,'Tie::File',$csv_file or die $!;
  for(@array){
    my $newline = $/;
    s/\015{1,2}\012|\015|\012/$newline/g;
  }
  untie @array;
  
  # creating new entrie-objects  
  open(my $fh,"<$csv_file") or die $!;
  my @lines = <$fh>;
  close $fh;
  my @entries = _create_entries($self,\@lines);
  return \@entries;
}# _parse_bill

#================================================#
# for each csv-line, a new object of Entry.pm    #
# is created                                     #
#================================================#
sub _create_entries{
  my ($self,$arref) = @_;
  my $parser        = Text::CSV_XS->new({sep_char => $self->{Separator}});
  my $count_lines   = 0;
  my (@fieldnames,@tmp_members);
  for my $line(@$arref){
    next if($line =~ /^.$/);
    if($parser->parse($line)){
      my @fields = $parser->fields();
      my $entry  = Business::Telstra::PhoneBill::Entry->new();
      if($self->{FirstLine} == 0 || $count_lines != 0){
        if(defined $self->{Fieldorder}){
          $entry->fieldnames($self->{Fieldorder});
        }
        $entry->fields(\@fields);
        push(@tmp_members,$entry);
      }
      $count_lines++;
    }
  }
  return @tmp_members;
}# _create_entries

1;
__END__

=head1 NAME

Business::Telstra::PhoneBill - Parse and handle Telstra phone bills

=head1 SYNOPSIS

  use Business::Telstra::PhoneBill;
  my $phone_bill = Business::Telstra::PhoneBill->new();
  $phone_bill->file('text.csv');
  
  # or
  
  my $bill = Business::Telstra::PhoneBill->new('bill.zip');
  
  my $entriesref = $bill->entries();
  for my $entry(@$entriesref){
    print $entry->duration(),"\n";
  }

=head1 DESCRIPTION

Business::Telstra::PhoneBill parses the phone bill given in CSV-format

=head1 METHODS

=head2 new([-file => $file][, -colnames => 0|1])

  my $bill = Business::Telstra::PhoneBill->new();

new has three optional parameters:

  * -file     => a csv- or a zip-file
  * -colnames => if colnames is set to 0, the csv-file does not contain 
                 the columnnames in its first line (default: 1)
  * -sep_char => sets the fieldseparator of the csv-file (default: ,)

and returns a new object of C<Business::Telstra::PhoneBill>

=head2 set_sepchar ($sepchar)

  $bill->set_sepchar(';');
  $bill->file($file);
  
The default separator is ','. If the fieldseperator has to be changed, then
it has to be set before the file is parsed, that means:
Set the separator in the constructor or use this method before using the C<file>-method.

=head2 entries ([$index])

  my $entryref = $bill->entries();

Returns an arrayref that contains all calls of the bill

  my $entry = $bill->entries(3);

Returns the third call of the bill (as an object of C<Business::Telstra::PhoneBill::Entry>)

=head2 find_entries($column,$value,[$type],[$fieldtype]);

C<find_entries> is a helper function to find specific  entries. It provides the 
following types: 

  like (RegExp-Match)
  greater
  lower

there are actually two special fieldtypes that are supportet:   

  date
  time

It returns an arrayref with all entries the search matched.

  my $foundref = $bill->find_entries('From_Number','1234 567 890');

returns an arrayref that contains all entries that have the number '1234 567 890'
as the 'From_Number'

  my $foundref = $bill->find_entries('Call_Time','28 Sep','greater','date');

returns an arrayref that contains all calls made after September 28th.

  my $foundref = $bill->find_entries('Duration','00:02:00','greater');

=head2 set_fieldorder (\@array)

  my @new_order = qw(From_Number To_Number Call_Time Duration);
  $bill->set_fieldorder(\@new_order);

If the order of the fields changes, you can tell the module the new
fieldorder. 
But the Array has to inlcude the following fieldnames:

  From_Number
  To_Number
  Call_Time
  Type
  Date
  Place
  Rate
  Duration
  Exclusive_GST
  Inclusive_GST
  Caller_Group


=head2 colnames (0|1)

  $bill->colnames(0);

If colnames is set to 0, the csv-file does not contain columnnames 
in its first line

=head2 filetype

  my $filetype = $bill->filetype();

Returns the filetype of the last file the module should parse

=head1 METHODS OF ENTRIES

=head2 from_number

  my $phone_number = $entry->from_number();

Returns the number that starts the call

=head2 to_number

  my $recipient = $entry->to_number();

Returns the recipients number

=head2 call_time

  my $time = $entry->call_time();

Returns the time the call starts

=head2 duration

  my $duration = $entry->duration();

Returns the duration of the call

=head2 date

  my $date = $entry->date();

Returns the date of the call

=head2 place

  my $place = $entry->place();

Returns the place of the call

=head2 rate

  my $rate = $entry->rate();

=head2 type

  my $type = $entry->type();

=head2 exclusive_gst

  my  $price_ex_gst = $entry->exclusive_gst();

=head2 inclusive_gst

  my $price_incl_gst = $entry->inclusive_gst();

=head2 caller_group

  my $group = $entry->caller_group();

=head1 PREREQUESITS

  Tie::File
  File::Type
  Archive::Zip
  Text::CSV_XS

=head1 BUGS

Bugs should be submitted to the Bugtracker of CPAN

=head1 ACKNOWLEDGEMENTS

Thanks to Adam Kennedy and Phase-N

=head1 AUTHOR

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Renee Baecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
