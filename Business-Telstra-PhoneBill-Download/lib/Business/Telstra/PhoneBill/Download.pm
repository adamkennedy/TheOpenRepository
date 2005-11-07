package Business::Telstra::PhoneBill::Download;

use 5.006001;
use strict;
use warnings;
use WWW::Mechanize;
use HTTP::Cookies;
use Business::Telstra::PhoneBill;

our $VERSION = '0.01';

#==================================================#
# creates a new object                             #
# optional parameters:                             #
#   * user     => username of Telstra account      #
#   * password => password for Telstra account     #
#   * account  => the nth bill-account that is     #
#                 mapped to your Telstra account   #
#==================================================#
sub new{
  my ($class,%args) = @_;
  
  my $self = {Error    => '',
              User     => '',
              Password => '',
              Data     => '',
              Account  => 1,
              };
  
  bless $self,$class;
  
  $self->{User}     = $args{-user}     if(exists $args{-user});
  $self->{Password} = $args{-password} if(exists $args{-password});
  $self->{Account}  = $args{-account}  if(exists $args{-account} 
                                              && $args{-account} =~ /^\d+$/);
  
  return $self;
}# new

#==================================================#
# starts the download of the bill                  #
# optional parameters:                             #
#   * user     => username of Telstra account      #
#   * password => password for Telstra account     #
#   * account  => the nth bill-account that is     #
#                 mapped to your Telstra account   #
#==================================================#
sub download{
  my ($self,%args) = @_;
  my $return_value = 0;
  
  $self->{User}     = $args{-user}     if(exists $args{-user});
  $self->{Password} = $args{-password} if(exists $args{-password});
  $self->{Account}  = $args{-account}  if(exists $args{-account}
                                              && $args{-account} =~ /^\d+$/);
  
  my $login     = $self->_login();
  $return_value = 1 if($login);
  
  return $return_value;
}# download


#==================================================#
# downloads the bill, creates a PhoneBill object   #
# parses the bill and returns the PhoneBill object #
# optional parameters:                             #
#   * user     => username of Telstra account      #
#   * password => password for Telstra account     #
#   * account  => the nth bill-account that is     #
#                 mapped to your Telstra account   #
#==================================================#
sub phonebill{
  my ($self,%args) = @_;
  
  my $phonebill;
  
  $self->{User}     = $args{-user}     if(exists $args{-user});
  $self->{Password} = $args{-password} if(exists $args{-password});
  $self->{Account}  = $args{-account}  if(exists $args{-account}
                                              && $args{-account} =~ /^\d+$/);
  
  my $login     = $self->_login();
  
  my $newline =  $/;
  my @lines   = split(/$newline/,$self->{Data});
  my @order   = qw(Item From_Number Type Date Call_Time To_Number Inclusive_GST);
  $phonebill  = Business::Telstra::PhoneBill->new();
  if(ref($phonebill) eq 'Business::Telstra::PhoneBill'){
    $phonebill->set_fieldorder(\@order);
    $phonebill->data(\@lines);
  }
  
  return $phonebill;
}# phonebill

#==================================================#
# saves the downloaded data into a file            #
#==================================================#
sub save_as{
  my ($self,$filename) = @_;
  $self->{Error} = undef;
  my $return_value = 0;
  if($filename){
    if(open(my $fh,">$filename")){
      binmode $fh;
      print $fh $self->{Data};
      if(close $fh){
        $return_value = 1;
      }
      else{
        $self->{Error} = $!;
      }
    }
    else{
      $self->{Error} = $!;
    }
  }
  else{
    $self->{Error} = 'no filename given';
  }
  return $return_value;
}# save_as

#==================================================#
# returns the downloaded data                      #
#==================================================#
sub data{
  my ($self) = @_;
  return $self->{Data};
}# data

#==================================================#
# sets the user of the Telstra account             #
#==================================================#
sub user{
  my ($self,$user) = @_;
  $self->{User} = $user if(defined $user);
}# user

#==================================================#
# returns the error message                        #
#==================================================#
sub error{
  my ($self) = @_;
  return $self->{Error};
}# error

#==================================================#
# sets the password of the Telstra account         #
#==================================================#
sub password{
  my ($self,$password) = @_;
  $self->{Password} = $password if(defined $password);
}# password

#==================================================#
# sets the number of the telephon number of that   #
# the bill should be downloaded                    #
#==================================================#
sub account{
  my ($self,$account) = @_;
  $self->{Account} = $account if(defined $account && $account =~ /^\d+$/);
}# account

#==================================================#
# login to the Telstra account                     #
#==================================================#
sub _login{
  my ($self) = @_;
  $self->{Cookie_jar} = HTTP::Cookies->new();
  $self->{Error}      = undef;
  
  my $user       = $self->{User};
  my $pwd        = $self->{Password};
  my $url        = _get_URL($user,$pwd); 
  my $target     = 'https://telstra.com/siteminderagent/SMLogin/postCIBSLogin.do';
  my $mechanizer = WWW::Mechanize->new(autocheck => 1);
  
  $mechanizer->cookie_jar($self->{Cookie_jar});
  # necessary to get the cookie values
  $mechanizer->get($url);
  $self->{Error} = 'Site not found' unless($mechanizer->content);
  # real login
  $mechanizer->submit_form(fields => {
                                     user         => $user, 
                                     password     => $pwd,
                                     TARGET       => $target,
                                     SMAUTHREASON => 0,
                                     });
  $self->{Error} = 'Could not login' unless($mechanizer->content());
  $mechanizer->follow_link(text_regex => qr/Online Bill/);
  # get page with download link
  my $linkref             = $mechanizer->find_all_links(text_regex => qr/View Bill/);
  my $account             = ($self->{Account} -1) * 2;
  my $link                = $linkref->[$account];
  my $view_url            = $link->url();
  my ($doc_id,$ddn,$site) = _parse_URL($view_url);
  my $down_url            = _get_download_URL($doc_id,$ddn,$site);
  
  # download csv file
  $mechanizer->get($down_url);
  $self->{Data} = $mechanizer->content();
}# _login

#==================================================#
# returns the URL for download in dependency of    #
# the ddn                                          #
#==================================================#
sub _get_download_URL{
  my ($doc,$ddn,$site) = @_;
  my $flexcab_url = 'https://onlinebilling.telstra.com.au/postbill/'.$site;
  $flexcab_url   .= '?app=UserMain&jsp=/app/jsp/PresentCSV.jsp&viewName=AFCSVDownLd&ddn='.$ddn;
  $flexcab_url   .= '&viewType=HTML&docId='.$doc;
  
  
  my $mnet_url = 'https://onlinebilling.telstra.com.au/postbill/'.$site;
  $mnet_url   .= '?app=UserMain&jsp=/app/jsp/PresentCSV.jsp&viewName=AMCSVDownLd&ddn='.$ddn;
  $mnet_url   .= '&viewType=HTML&docId='.$doc;
  
  my $download_url = $ddn eq 'MNET_Post' ? $mnet_url : $flexcab_url;
  
  return $download_url
}# _get_download_URL

#==================================================#
# parses the ddn and the filename out off the      #
# javascript URL                                   #
#==================================================#
sub _parse_URL{
  my ($url) = @_;
  my ($ddn,$doc,$site) = $url =~ /\('(.*?)','(.*?)','(.*?)'/;
  return ($doc,$ddn,$site);
}# _parse_url


#==================================================#
# returns initial URL                              #
#==================================================#
sub _get_URL{
  my ($user,$password) = @_;
  
  my $url = 'https://telstra.com/siteminderagent/SMLogin/preLogin.do?SMSESSION=NO';
  $url   .= '&user='.$user.'&password='.$password.'&target=&smauthreason=0&';
  $url   .= 'error_target=https://register.telstra.com.au/login/TocTraLoginError.html&';
  $url   .= 'final_target=$SM$https://shopfront.telstra.com.au/bizonline/reg.htm&';
  $url   .= 'postpreservationdata=&generallogondata=SMLogonVersion=1.0&Debug=false&';
  $url   .= 'Referer=https://register.telstra.com.au/login/TocTraLogin.html?TYPE=3353&';
  $url   .= 'REALMOID=06-def45&GUID=&SMAUTHREASON=0&';
  $url   .= 'TARGET=$SM$https://shopfront.telstra.com.au/bizonline/reg.htm';
  $url   .= '&SMIDENTITY=QUERY';
  
  return $url;
}# _get_URL


# Preloaded methods go here.

1;
__END__

=head1 NAME

Business::Telstra::PhoneBill::Download - Download phone bills from Telstra site
(CSV-files)

=head1 SYNOPSIS

  use Business::Telstra::PhoneBill::Download;
  my $download = Business::Telstra::PhoneBill::Download->new();
  
  $download->user($user);
  $download->password($password);
  $download->account($account_nr);
  $download->download();
  
  $download->save_as('download.csv');

=head1 DESCRIPTION

C<Business::Telstra::PhoneBill::Download> allows to automate the download of
Telstra PhoneBills as CSV-files.

=head1 METHODS

=head2 new([-user => $user[, -password => $pwd[, -account => $account_nr]]])

Returns a new C<Business::Telstra::PhoneBill::Download> object. Optional
parameters:

  * user     => username of Telstra account
  * password => password for Telstra account
  * account  => the nth bill-account that is mapped to your Telstra account

=head2 download([-user => $user[, -password => $pwd[, -account => $account_nr]]])

downloads the bill and has the same optional parameters as new

=head2 phonebill([-user => $user[, -password => $pwd[, -account => $account_nr]]])

phonebill starts the download, parses the bill and returns an 
C<Business::Telstra::PhoneBill> object.

It has the same optional parameters as new.

=head2 data()

returns the downloaded data as a scalar

=head2 save_as($filename)

saves the data into a file ($filename).

=head2 user($user)

sets the user for the Telstra account

=head2 password($password)

sets the password for the Telstra account

=head2 account($account_nr)

sets the account number. Sometimes there are more than one telephone numbers
mapped to the Telstra account. To select which bill should be downloaded, you
can set the account number.

=head2 error()

returns the error message when a method fails

=head1 REQUIREMENTS

  WWW::Mechanize
  HTTP::Cookies
  Business::Telstra::PhoneBill

=head1 ACKNOWLEDGEMENTS

Thanks to Adam Kennedy and Phase-N Australia

=head1 AUTHOR

Renee Baecker, E<lt>module@renee-baecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Renee Baecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
