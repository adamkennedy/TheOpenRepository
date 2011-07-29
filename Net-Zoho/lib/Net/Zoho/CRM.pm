package Net::Zoho::CRM;

use strict;
use 5.008005;
use LWP::UserAgent;
use Carp;
use Text::Autoformat;

our $VERSION = '0.01';

my $primary_url = "https://accounts.zoho.com/login";

sub new	{
		
	my ($class, $args) = @_;
	my $self = bless($args, $class);
	
	my $ua = LWP::UserAgent->new;
	$self->{ua} = $ua;
	
	return $self;
}

sub generate_ticket {

	my ($self, %param) = @_;
	
	my %form = ( "servicename" => "ZohoCRM", "FROM_AGENT" => "true");
	$form{"LOGIN_ID"} = $param{LOGIN_ID};
	$form{"PASSWORD"} = $param{PASSWORD};
	
	my $response = $self->{ua}->post($primary_url, \%form);
	
	if ($response->is_success) {
		return $response->decoded_content;
	}
	else {
		return $response->status_line;
	}
}

sub get_my_records {

	my ($self, %param) = @_;
	my $url;
	
	if (lc($param{res_type}) eq 'xml') {
		$url = 'https://crm.zoho.com/crm/private/xml/';
	}
	elsif (lc($param{res_type}) eq 'json') {
		$url = 'https://crm.zoho.com/crm/private/json/';
	}
	else {
		croak "Incorrect response type supplied. Must be either json or xml";
	}
	if (! $param{ticket}) {
		croak "API Ticket not supplied.";
	}
	if (! $param{apikey}) {
		croak "API Key not supplied.";
	}
	if (! $param{module}) {
		croak "Module not supplied.";
	}
	else {
		$param{module} = autoformat $param{module}, {case => 'title' };
		chop $param{module};
		chop $param{module};
	}
	if (! $param{select_columns}) {
		croak "Select columns not supplied.";
	}
	if (! $param{new_format} || $param{new_format} !~ /^[1-2]$/ ) {
		carp "Invalid New Format supplied. Default value (1) being used.";
		$param{new_format} = "1";
	}
	if (! $param{version} || $param{version} !~ /^[1-2]$/ ) {
		carp "Invalid version supplied. Default value (1) being used.";
		$param{version} = "1";
	}
	if (! $param{from_index} || $param{from_index} !~ /^\d+$/ ) {
		carp "Invalid fromIndex supplied. Default value (1) being used.";
		$param{from_index} = "1";
	}
	if (! $param{to_index} || $param{to_index} !~ /^\d+$/ || $param{to_index} > 200) {
		carp "Invalid toIndex supplied. Default value (20) being used.";
		$param{to_index} = "20";
	}
	if (! $param{sort_order_string} ) {
		carp "Invalid sortOrderString supplied. Default value (asc) being used.";
		$param{sort_order_string} = "asc";
	}
	if ( $param{last_modified_time} !~ /^\d{4}-\d{2}-\d{2}\s{1}\d{2}:\d{2}:\d{2}$/ && $param{last_modified_time} ne "null" ) {
		carp "Invalid lastModifiedTime supplied. Default value (null) being used.";
		$param{last_modified_time} = "null";
	}
	
	$url = $url.$param{module}."/getMyRecords?ticket=".
	$param{ticket}.
	"&apikey=".
	$param{apikey}.
	"&selectColumns=".
	$param{select_columns}.
	"&fromIndex=".
	$param{from_index}.
	"&toIndex=".
	$param{to_index}.
	"&sortColumnString=".
	$param{sort_column_string}.
	"&sortOrderString=".
	$param{sort_order_string}.
	"&lastModifiedTime=".
	$param{last_modified_time}.
	"&newFormat=".
	$param{new_format}.
	"&version=".
	$param{version};
	
	my $response = $self->{ua}->get($url);
	
	if ($response->is_success) {
		return $response->decoded_content;
	}
	else {
		return $response->status_line;
	}
}

sub get_records {

	my ($self, %param) = @_;
	my $url;
	
	if (lc($param{res_type}) eq 'xml') {
		$url = 'https://crm.zoho.com/crm/private/xml/';
	}
	elsif (lc($param{res_type}) eq 'json') {
		$url = 'https://crm.zoho.com/crm/private/json/';
	}
	else {
		croak "Incorrect response type supplied. Must be either json or xml";
	}
	if (! $param{ticket}) {
		croak "API Ticket not supplied.";
	}
	if (! $param{apikey}) {
		croak "API Key not supplied.";
	}
	if (! $param{module}) {
		croak "Module not supplied.";
	}
	else {
		$param{module} = autoformat $param{module}, {case => 'title' };
		chop $param{module};
		chop $param{module};
	}
	if (! $param{select_columns}) {
		croak "Select columns not supplied.";
	}
	if (! $param{new_format} || $param{new_format} !~ /^[1-2]$/ ) {
		carp "Invalid New Format supplied. Default value (1) being used.";
		$param{new_format} = "1";
	}
	if (! $param{version} || $param{version} !~ /^[1-2]$/ ) {
		carp "Invalid version supplied. Default value (1) being used.";
		$param{version} = "1";
	}
	if (! $param{from_index} || $param{from_index} !~ /^\d+$/ ) {
		carp "Invalid fromIndex supplied. Default value (1) being used.";
		$param{from_index} = "1";
	}
	if (! $param{to_index} || $param{to_index} !~ /^\d+$/ || $param{to_index} > 200) {
		carp "Invalid toIndex supplied. Default value (20) being used.";
		$param{to_index} = "20";
	}
	if (! $param{sort_order_string} ) {
		carp "Invalid sortOrderString supplied. Default value (asc) being used.";
		$param{sort_order_string} = "asc";
	}
	if ( $param{last_modified_time} !~ /^\d{4}-\d{2}-\d{2}\s{1}\d{2}:\d{2}:\d{2}$/ && $param{last_modified_time} ne "null" ) {
		carp "Invalid lastModifiedTime supplied. Default value (null) being used.";
		$param{last_modified_time} = "null";
	}
	
	$url = $url.$param{module}."/getRecords?ticket=".
	$param{ticket}.
	"&apikey=".
	$param{apikey}.
	"&selectColumns=".
	$param{select_columns}.
	"&fromIndex=".
	$param{from_index}.
	"&toIndex=".
	$param{to_index}.
	"&sortColumnString=".
	$param{sort_column_string}.
	"&sortOrderString=".
	$param{sort_order_string}.
	"&lastModifiedTime=".
	$param{last_modified_time}.
	"&newFormat=".
	$param{new_format}.
	"&version=".
	$param{version};
	
	my $response = $self->{ua}->get($url);
	
	if ($response->is_success) {
		return $response->decoded_content;
	}
	else {
		return $response->status_line;
	}
}

sub get_record_by_id {

	my ($self, %param) = @_;
	my $url;
	
	if (lc($param{res_type}) eq 'xml') {
		$url = 'https://crm.zoho.com/crm/private/xml/';
	}
	elsif (lc($param{res_type}) eq 'json') {
		$url = 'https://crm.zoho.com/crm/private/json/';
	}
	else {
		croak "Incorrect response type supplied. Must be either json or xml";
	}
	if (! $param{ticket}) {
		croak "API Ticket not supplied.";
	}
	if (! $param{apikey}) {
		croak "API Key not supplied.";
	}
	if (! $param{module}) {
		croak "Module not supplied.";
	}
	else {
		$param{module} = autoformat $param{module}, {case => 'title' };
		chop $param{module};
		chop $param{module};
	}
	if (! $param{id}) {
		croak "Record ID not supplied.";
	}
	if (! $param{new_format} || $param{new_format} !~ /^[1-2]$/ ) {
		carp "Invalid New Format supplied. Default value (1) being used.";
		$param{new_format} = "1";
	}
	if (! $param{version} || $param{version} !~ /^[1-2]$/ ) {
		carp "Invalid version supplied. Default value (1) being used.";
		$param{version} = "1";
	}
	
	$url = $url.$param{module}."/getRecordById?ticket=".
	$param{ticket}.
	"&apikey=".
	$param{apikey}.
	"&id=".
	$param{id}.
	"&newFormat=".
	$param{new_format}.
	"&version=".
	$param{version};
	
	my $response = $self->{ua}->get($url);
	
	if ($response->is_success) {
		return $response->decoded_content;
	}
	else {
		return $response->status_line;
	}
}

sub get_cv_records {

	my ($self, %param) = @_;
	my $url;
	
	if (lc($param{res_type}) eq 'xml') {
		$url = 'https://crm.zoho.com/crm/private/xml/';
	}
	elsif (lc($param{res_type}) eq 'json') {
		$url = 'https://crm.zoho.com/crm/private/json/';
	}
	else {
		croak "Incorrect response type supplied. Must be either json or xml";
	}
	if (! $param{ticket}) {
		croak "API Ticket not supplied.";
	}
	if (! $param{apikey}) {
		croak "API Key not supplied.";
	}
	if (! $param{module}) {
		croak "Module not supplied.";
	}
	else {
		$param{module} = autoformat $param{module}, {case => 'title' };
		chop $param{module};
		chop $param{module};
	}
	if (! $param{cv_name}) {
		croak "cvName not supplied.";
	}
	if (! $param{new_format} || $param{new_format} !~ /^[1-2]$/ ) {
		carp "Invalid New Format supplied. Default value (1) being used.";
		$param{new_format} = "1";
	}
	if (! $param{version} || $param{version} !~ /^[1-2]$/ ) {
		carp "Invalid version supplied. Default value (1) being used.";
		$param{version} = "1";
	}
	if (! $param{from_index} || $param{from_index} !~ /^\d+$/ ) {
		carp "Invalid fromIndex supplied. Default value (1) being used.";
		$param{from_index} = "1";
	}
	if (! $param{to_index} || $param{to_index} !~ /^\d+$/ || $param{to_index} > 200) {
		carp "Invalid toIndex supplied. Default value (20) being used.";
		$param{to_index} = "20";
	}
	if ( $param{last_modified_time} !~ /^\d{4}-\d{2}-\d{2}\s{1}\d{2}:\d{2}:\d{2}$/ && $param{last_modified_time} ne "null" ) {
		carp "Invalid lastModifiedTime supplied. Default value (null) being used.";
		$param{last_modified_time} = "null";
	}
	
	$url = $url.$param{module}."/getCVRecords?ticket=".
	$param{ticket}.
	"&apikey=".
	$param{apikey}.
	"&fromIndex=".
	$param{from_index}.
	"&toIndex=".
	$param{to_index}.
	"&cvName=".
	$param{cv_name}.
	"&lastModifiedTime=".
	$param{last_modified_time}.
	"&newFormat=".
	$param{new_format}.
	"&version=".
	$param{version};
	
	my $response = $self->{ua}->get($url);
	
	if ($response->is_success) {
		return $response->decoded_content;
	}
	else {
		return $response->status_line;
	}
}

sub get_search_records {

	my ($self, %param) = @_;
	my $url;
	
	if (lc($param{res_type}) eq 'xml') {
		$url = 'https://crm.zoho.com/crm/private/xml/';
	}
	elsif (lc($param{res_type}) eq 'json') {
		$url = 'https://crm.zoho.com/crm/private/json/';
	}
	else {
		croak "Incorrect response type supplied. Must be either json or xml";
	}
	if (! $param{ticket}) {
		croak "API Ticket not supplied.";
	}
	if (! $param{apikey}) {
		croak "API Key not supplied.";
	}
	if (! $param{module}) {
		croak "Module not supplied.";
	}
	else {
		$param{module} = autoformat $param{module}, {case => 'title' };
		chop $param{module};
		chop $param{module};
	}
	if (! $param{select_columns}) {
		croak "Select columns not supplied.";
	}
	if (! $param{search_condition}) {
		croak "Search condition not supplied.";
	}
	if (! $param{new_format} || $param{new_format} !~ /^[1-2]$/ ) {
		carp "Invalid New Format supplied. Default value (1) being used.";
		$param{new_format} = "1";
	}
	if (! $param{version} || $param{version} !~ /^[1-2]$/ ) {
		carp "Invalid version supplied. Default value (1) being used.";
		$param{version} = "1";
	}
	if (! $param{from_index} || $param{from_index} !~ /^\d+$/ ) {
		carp "Invalid fromIndex supplied. Default value (1) being used.";
		$param{from_index} = "1";
	}
	if (! $param{to_index} || $param{to_index} !~ /^\d+$/ || $param{to_index} > 200) {
		carp "Invalid toIndex supplied. Default value (20) being used.";
		$param{to_index} = "20";
	}
	
	$url = $url.$param{module}."/getSearchRecords?ticket=".
	$param{ticket}.
	"&apikey=".
	$param{apikey}.
	"&selectColumns=".
	$param{select_columns}.
	"&searchCondition=".
	$param{search_condition}.
	"&fromIndex=".
	$param{from_index}.
	"&toIndex=".
	$param{to_index}.
	"&newFormat=".
	$param{new_format}.
	"&version=".
	$param{version};
	
	my $response = $self->{ua}->get($url);
	
	if ($response->is_success) {
		return $response->decoded_content;
	}
	else {
		return $response->status_line;
	}
}

sub get_search_records_by_pdc {

	my ($self, %param) = @_;
	my $url;
	
	if (lc($param{res_type}) eq 'xml') {
		$url = 'https://crm.zoho.com/crm/private/xml/';
	}
	elsif (lc($param{res_type}) eq 'json') {
		$url = 'https://crm.zoho.com/crm/private/json/';
	}
	else {
		croak "Incorrect response type supplied. Must be either json or xml";
	}
	if (! $param{ticket}) {
		croak "API Ticket not supplied.";
	}
	if (! $param{apikey}) {
		croak "API Key not supplied.";
	}
	if (! $param{module}) {
		croak "Module not supplied.";
	}
	else {
		$param{module} = autoformat $param{module}, {case => 'title' };
		chop $param{module};
		chop $param{module};
	}
	if (! $param{select_columns}) {
		croak "Select columns not supplied.";
	}
	if (! $param{search_column}) {
		croak "Search column not supplied.";
	}
	if (! $param{search_value}) {
		croak "Search value not supplied.";
	}
	if (! $param{new_format} || $param{new_format} !~ /^[1-2]$/ ) {
		carp "Invalid New Format supplied. Default value (1) being used.";
		$param{new_format} = "1";
	}
	if (! $param{version} || $param{version} !~ /^[1-2]$/ ) {
		carp "Invalid version supplied. Default value (1) being used.";
		$param{version} = "1";
	}
	
	$url = $url.$param{module}."/getSearchRecordsByPDC?ticket=".
	$param{ticket}.
	"&apikey=".
	$param{apikey}.
	"&selectColumns=".
	$param{select_columns}.
	"&searchColumn=".
	$param{search_column}.
	"&searchvalue=".
	$param{search_value}.
	"&newFormat=".
	$param{new_format}.
	"&version=".
	$param{version};
	
	my $response = $self->{ua}->get($url);
	
	if ($response->is_success) {
		return $response->decoded_content;
	}
	else {
		return $response->status_line;
	}
}

sub insert_records {

	my ($self, %param) = @_;
	my $url;
	
	if (lc($param{res_type}) eq 'xml') {
		$url = 'https://crm.zoho.com/crm/private/xml/';
	}
	elsif (lc($param{res_type}) eq 'json') {
		$url = 'https://crm.zoho.com/crm/private/json/';
	}
	else {
		croak "Incorrect response type supplied. Must be either json or xml";
	}
	if (! $param{ticket}) {
		croak "API Ticket not supplied.";
	}
	if (! $param{apikey}) {
		croak "API Key not supplied.";
	}
	if (! $param{module}) {
		croak "Module not supplied.";
	}
	else {
		$param{module} = autoformat $param{module}, {case => 'title' };
		chop $param{module};
		chop $param{module};
	}
	if (! $param{xml_data}) {
		croak "xmlData not supplied.";
	}
	if (! $param{wf_trigger} || $param{wf_trigger} !~ /^true$|^false$/i ) {
		carp "Invalid wfTrigger supplied. Default value (false) being used.";
		$param{wf_trigger} = "false";
	}
	if (! $param{duplicate_check} || $param{duplicate_check} !~ /^[1-2]$/ ) {
		carp "Invalid duplicateCheck supplied. Default value (1) being used.";
		$param{duplicate_check} = "1";
	}
	if (! $param{is_approval} || $param{is_approval} !~ /^true$|^false$/i ) {
		carp "Invalid isApproval supplied. Default value (true) being used.";
		$param{is_approval} = "false";
	}
	if (! $param{new_format} || $param{new_format} !~ /^[1-2]$/ ) {
		carp "Invalid New Format supplied. Default value (1) being used.";
		$param{new_format} = "1";
	}
	if (! $param{version} || $param{version} !~ /^[1-2]$/ ) {
		carp "Invalid version supplied. Default value (1) being used.";
		$param{version} = "1";
	}
	
	$url = $url.$param{module}."/insertRecords";
	
	my %form;
	$form{ticket}         = $param{ticket};
	$form{apikey}         = $param{apikey};
	$form{xmlData}        = $param{xml_data};
	$form{wfTrigger}      = $param{wf_trigger};
	$form{duplicateCheck} = $param{duplicate_check};
	$form{isApproval}     = $param{is_approval};
	$form{newFormat}      = $param{new_format};
	$form{version}        = $param{version};
	
	my $response = $self->{ua}->post($url, \%form);
	
	if ($response->is_success) {
		return $response->decoded_content;
	}
	else {
		return $response->status_line;
	}
}

sub update_records {

	my ($self, %param) = @_;
	my $url;
	
	if (lc($param{res_type}) eq 'xml') {
		$url = 'https://crm.zoho.com/crm/private/xml/';
	}
	elsif (lc($param{res_type}) eq 'json') {
		$url = 'https://crm.zoho.com/crm/private/json/';
	}
	else {
		croak "Incorrect response type supplied. Must be either json or xml";
	}
	if (! $param{ticket}) {
		croak "API Ticket not supplied.";
	}
	if (! $param{apikey}) {
		croak "API Key not supplied.";
	}
	if (! $param{module}) {
		croak "Module not supplied.";
	}
	else {
		$param{module} = autoformat $param{module}, {case => 'title' };
		chop $param{module};
		chop $param{module};
	}
	if (! $param{id}) {
		croak "Record ID not supplied.";
	}
	if (! $param{xml_data}) {
		croak "xmlData not supplied.";
	}
	if (! $param{wf_trigger} || $param{wf_trigger} !~ /^true$|^false$/i ) {
		carp "Invalid wfTrigger supplied. Default value (false) being used.";
		$param{wf_trigger} = "false";
	}
	if (! $param{new_format} || $param{new_format} !~ /^[1-2]$/ ) {
		carp "Invalid New Format supplied. Default value (1) being used.";
		$param{new_format} = "1";
	}
	if (! $param{version} || $param{version} !~ /^[1-2]$/ ) {
		carp "Invalid version supplied. Default value (1) being used.";
		$param{version} = "1";
	}
	
	$url = $url.$param{module}."/updateRecords";
	$param{ticket}.
	"&apikey=".
	$param{apikey}.
	"&id=".
	$param{id}.
	"&xmlData=".
	$param{xml_data}.
	"&wfTrigger=".
	$param{wf_trigger}.
	"&newFormat=".
	$param{new_format}.
	"&version=".
	$param{version};
	
	my %form;
	$form{ticket}         = $param{ticket};
	$form{apikey}         = $param{apikey};
	$form{id}             = $param{id};
	$form{xmlData}        = $param{xml_data};
	$form{wfTrigger}      = $param{wf_trigger};
	$form{newFormat}      = $param{new_format};
	$form{version}        = $param{version};
	
	my $response = $self->{ua}->post($url, \%form);
	
	if ($response->is_success) {
		return $response->decoded_content;
	}
	else {
		return $response->status_line;
	}
}

sub delete_records {

	my ($self, %param) = @_;
	my $url;
	
	if (lc($param{res_type}) eq 'xml') {
		$url = 'https://crm.zoho.com/crm/private/xml/';
	}
	elsif (lc($param{res_type}) eq 'json') {
		$url = 'https://crm.zoho.com/crm/private/json/';
	}
	else {
		croak "Incorrect response type supplied. Must be either json or xml";
	}
	if (! $param{ticket}) {
		croak "API Ticket not supplied.";
	}
	if (! $param{apikey}) {
		croak "API Key not supplied.";
	}
	if (! $param{module}) {
		croak "Module not supplied.";
	}
	else {
		$param{module} = autoformat $param{module}, {case => 'title' };
		chop $param{module};
		chop $param{module};
	}
	if (! $param{id}) {
		croak "Record ID not supplied.";
	}
	
	$url = $url.$param{module}."/deleteRecords?ticket=".
	$param{ticket}.
	"&apikey=".
	$param{apikey}.
	"&id=".
	$param{id};
	
	my $response = $self->{ua}->get($url);
	
	if ($response->is_success) {
		return $response->decoded_content;
	}
	else {
		return $response->status_line;
	}
}

sub convert_lead {

	my ($self, %param) = @_;
	my $url;
	
	if (lc($param{res_type}) eq 'xml') {
		$url = 'https://crm.zoho.com/crm/private/xml/';
	}
	elsif (lc($param{res_type}) eq 'json') {
		$url = 'https://crm.zoho.com/crm/private/json/';
	}
	else {
		croak "Incorrect response type supplied. Must be either json or xml";
	}
	if (! $param{ticket}) {
		croak "API Ticket not supplied.";
	}
	if (! $param{apikey}) {
		croak "API Key not supplied.";
	}
	if (! $param{lead_id}) {
		croak "Lead ID not supplied.";
	}
	if (! $param{xml_data}) {
		croak "xmlData not supplied.";
	}
	if (! $param{new_format} || $param{new_format} !~ /^[1-2]$/ ) {
		carp "Invalid New Format supplied. Default value (1) being used.";
		$param{new_format} = "1";
	}
	if (! $param{version} || $param{version} !~ /^[1-2]$/ ) {
		carp "Invalid version supplied. Default value (1) being used.";
		$param{version} = "1";
	}
	
	$url = $url."Leads/convertLeads?ticket=".
	$param{ticket}.
	"&apikey=".
	$param{apikey}.
	"&id=".
	$param{lead_id}.
	"&xmlData=".
	$param{xml_data}.
	"&newFormat=".
	$param{new_format}.
	"&version=".
	$param{version};
	
	my $response = $self->{ua}->get($url);
	
	if ($response->is_success) {
		return $response->decoded_content;
	}
	else {
		return $response->status_line;
	}
}

sub get_related_records {

	my ($self, %param) = @_;
	my $url;
	
	if (lc($param{res_type}) eq 'xml') {
		$url = 'https://crm.zoho.com/crm/private/xml/';
	}
	elsif (lc($param{res_type}) eq 'json') {
		$url = 'https://crm.zoho.com/crm/private/json/';
	}
	else {
		croak "Incorrect response type supplied. Must be either json or xml";
	}
	if (! $param{ticket}) {
		croak "API Ticket not supplied.";
	}
	if (! $param{apikey}) {
		croak "API Key not supplied.";
	}
	if (! $param{module}) {
		croak "Module not supplied.";
	}
	else {
		$param{module} = autoformat $param{module}, {case => 'title' };
		chop $param{module};
		chop $param{module};
	}
	if (! $param{parent_module}) {
		croak "Parent Module not supplied.";
	}
	if (! $param{id}) {
		croak "Id not supplied.";
	}
	if (! $param{new_format} || $param{new_format} !~ /^[1-2]$/ ) {
		carp "Invalid New Format supplied. Default value (1) being used.";
		$param{new_format} = "1";
	}
	if (! $param{from_index} || $param{from_index} !~ /^\d+$/ ) {
		carp "Invalid fromIndex supplied. Default value (1) being used.";
		$param{from_index} = "1";
	}
	if (! $param{to_index} || $param{to_index} !~ /^\d+$/ || $param{to_index} > 200) {
		carp "Invalid toIndex supplied. Default value (20) being used.";
		$param{to_index} = "20";
	}
	
	$url = $url.$param{module}."/getRecords?ticket=".
	$param{ticket}.
	"&apikey=".
	$param{apikey}.
	"&parentModule=".
	$param{parent_module}.
	"&id=".
	$param{id}.
	"&fromIndex=".
	$param{from_index}.
	"&toIndex=".
	$param{to_index}.
	"&newFormat=".
	$param{new_format};
	
	my $response = $self->{ua}->get($url);
	
	if ($response->is_success) {
		return $response->decoded_content;
	}
	else {
		return $response->status_line;
	}
}

1;