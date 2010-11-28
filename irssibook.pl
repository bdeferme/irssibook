#!/usr/bin/perl -w
#
# Irssibook.pl
#
# This script allows you to change your facebook status from within your irssi.
#

use strict;
use vars qw($VERSION %IRSSI);
use Irssi qw(command_bind signal_add settings_add_str settings_get_str settings_set_str);
use JSON;
# Use LWP::UserAgent to do status updates via GRAPH API POST
use LWP::UserAgent; 
my $ua = new LWP::UserAgent;

$VERSION = '0.3';

%IRSSI = (
        authors         => 'Bert Deferme',
        contact         => 'fbook@bdeferme.net',
        name            => 'irssibook.pl',
        description     => 'This script allows you to change your facebook status from within your irssi.',
	url		=> 'http://projects.bdeferme.net/projects/irssibook',
        license         => 'GPL',
);

# API_KEY
my $api_key = '994152b1c0bb21fb796c69febf3f059d';

# FB_AUTH method, used to auth irssibook to facebook
sub fb_auth
{
  my ($text, $server, $dest) = @_;

  if (Irssi::settings_get_bool('irssibook_authed'))
  {
    Irssi::active_win()->print("You have already authed Irssibook to facebook, you should only do this once! If you would like to do this anyway please '/set irssibook_authed OFF' first...");
  }
  else
  {
    if ($text =~ /.+/) {
      my $token = $text;
      $token =~ s/http\:\/\/www.facebook.com\/connect\/login_success\.html\#access_token=//;
      $token =~ s/&expires_in=0//;
      Irssi::settings_set_str('irssibook_access_token', $token);
      Irssi::settings_set_bool('irssibook_authed', 1);
    }
    else
    {
      Irssi::active_win()->print("Step 1: Open the following URL in your browser, click allow, and copy the URL when the page displays Success");
      Irssi::active_win()->print("URL: https://graph.facebook.com/oauth/authorize?client_id=$api_key&redirect_uri=http://www.facebook.com/connect/login_success.html&type=user_agent&display=popup&scope=offline_access,publish_stream,read_stream");
      Irssi::active_win()->print("Step 2: Use /irssibook_auth <URL> (the WHOLE url you copied) to set your access token.");
      Irssi::active_win()->print("Step 3: WIN!");
    }
  }
}

# FB_SETSTATUS method, used to set / get facebook status
sub fb_setStatus
{
  my ($text, $server, $dest) = @_;
  if (Irssi::settings_get_bool('irssibook_authed'))
  {
    my $access_token = Irssi::settings_get_str('irssibook_access_token');
    if ($text) 
    {
      eval
      {
        $ua->post('https://graph.facebook.com/me/feed',{access_token => $access_token, message => $text});
      };
      if ($@)
      {
        Irssi::active_win()->print("Error, perhaps you forgot to allow this application access to update your status?");
        Irssi::active_win()->print("Use /irssibook_auth !");
      }
      else 
      {	
        Irssi::active_win()->print("Your facebook status was updated successfully.");
      }
    }
    else 
    {
      my $response = $ua->get("https://graph.facebook.com/me/posts?access_token=$access_token&fields=message&limit=1");
      my %decoded_json = %{ decode_json($response->content) };
      my %dataHash = %{ $decoded_json{data}[0]};
      Irssi::active_win()->print("Your latest facebook status is: ".$dataHash{message});
    }
  }
  else
  {
    Irssi::active_win()->print("Please, make sure you used the /irssibook_auth command!");
  }
}

Irssi::active_win()->print("Irssibook $VERSION loaded.");
Irssi::active_win()->print("Please start with /irssibook_auth!");
Irssi::active_win()->print("Irssibook supports: Check status with /fbstatus || Set status with /fbstatus <message>");
Irssi::active_win()->print("http://projects.bdeferme.net/projects/irssibook");

Irssi::settings_add_str('irssibook','irssibook_access_token','');
Irssi::settings_add_bool('irssibook','irssibook_authed',0);

Irssi::command_bind('irssibook_auth','fb_auth');
Irssi::command_bind('fbstatus','fb_setStatus');
