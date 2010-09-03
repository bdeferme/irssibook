#!/usr/bin/perl -w
#
# Irssibook.pl
#
# This script allows you to change your facebook status from within your irssi.
#

use strict;
use vars qw($VERSION %IRSSI);
use Irssi qw(command_bind signal_add settings_add_str settings_get_str settings_set_str);
use WWW::Facebook::API;
use Data::Dumper;

$VERSION = '0.2';

%IRSSI = (
        authors         => 'Bert Deferme',
        contact         => 'fbook@bdeferme.net',
        name            => 'irssibook.pl',
        description     => 'This script allows you to change your facebook status from within your irssi.',
        license         => 'GPL',
);

my $api_key = '994152b1c0bb21fb796c69febf3f059d';
my $secret = '0fe2caa463afad261fbefae66f5a6a47';

my $client = WWW::Facebook::API->new(
	desktop => 1,
	api_key => $api_key,
	secret => $secret,
);


sub fb_auth
{
	my ($text, $server, $dest) = @_;

	if (Irssi::settings_get_bool('irssibook_authed'))
	{
		Irssi::active_win()->print("You have already authed Irssibook to facebook, you should only do this once! If you would like to do this anyway please '/set irssibook_authed OFF' first...");
	}
	else
	{
		if ($text !~ /.{6,6}/)
		{
			Irssi::active_win()->print("Please, make sure you are logged in to facebook and go to:");
			Irssi::active_win()->print("http://www.facebook.com/code_gen.php?v=1.0&api_key=$api_key");
			Irssi::active_win()->print("Copy the code, and use /irssibook_auth <code>");
		}
		else
		{
			my $token = $text;
			$client->auth->get_session( $token );

			Irssi::settings_set_str('irssibook_session_uid', $client->session_uid);
			Irssi::settings_set_str('irssibook_session_key', $client->session_key);
			Irssi::settings_set_str('irssibook_session_expires', $client->session_expires);
			Irssi::settings_set_str('irssibook_user_secret', $client->secret);
			Irssi::settings_set_bool('irssibook_authed', 1);

			Irssi::active_win()->print("Now please go to:");
			Irssi::active_win()->print("http://www.facebook.com/authorize.php?api_key=$api_key&v=1.0&ext_perm=status_update");
			Irssi::active_win()->print("To allow this application access to update your status");
		}
	}
}

sub fb_setStatus
{
	my ($text, $server, $dest) = @_;

	if (Irssi::settings_get_bool('irssibook_authed'))
	{
		$client->session_key(Irssi::settings_get_str('irssibook_session_key'));
		$client->session_uid(Irssi::settings_get_str('irssibook_session_uid'));
		$client->session_expires(Irssi::settings_get_str('irssibook_session_expires'));
		$client->secret(Irssi::settings_get_str('irssibook_user_secret'));

		if ($text) 
		{
			eval
			{
				if ($text =~ /^-clear$/) 
				{
					$client->users->set_status( clear => 1 );
				} 
				else 
				{
					$client->users->set_status( status => "$text", 'status_includes_verb' => 1 );
				}
			};

			if ($@)
			{
				Irssi::active_win()->print("Error, perhaps you forgot to allow this application access to update your status?");
				Irssi::active_win()->print("Go to:");
				Irssi::active_win()->print("http://www.facebook.com/authorize.php?api_key=$api_key&v=1.0&ext_perm=status_update");
			}
			else 
			{	
				if ($text =~ /^-clear$/) 
				{
					Irssi::active_win()->print("Your facebook status was cleared successfully.");
				} 
				else 
				{
					Irssi::active_win()->print("Your facebook status was updated successfully.");
				}
			}
		}
		else 
		{
			my $whatStatus = $client->users->get_info(
				uids => Irssi::settings_get_str('irssibook_session_uid'),
				fields => 'status'
			);
			Irssi::active_win()->print("Your facebook status is: ".%{@$whatStatus[0]}->{status}{message});
		}
	}
	else
	{
		Irssi::active_win()->print("Please, make sure you are logged in to facebook and go to:");
		Irssi::active_win()->print("http://www.facebook.com/code_gen.php?v=1.0&api_key=$api_key");
		Irssi::active_win()->print("Copy the code, and use /irssibook_auth <code>");
	}
}

Irssi::active_win()->print("Irssibook $VERSION loaded.");
Irssi::active_win()->print("Please start with /irssibook_auth!");
Irssi::active_win()->print("Irssibook supports: Check status with /fbstatus || Set status with /fbstatus message || Clear status with /fbstatus -clear");

Irssi::settings_add_str('irssibook','irssibook_session_uid', '');
Irssi::settings_add_str('irssibook','irssibook_session_key', '');
Irssi::settings_add_str('irssibook','irssibook_session_expires','');
Irssi::settings_add_str('irssibook','irssibook_user_secret','');
Irssi::settings_add_bool('irssibook','irssibook_authed',0);

Irssi::command_bind('irssibook_auth','fb_auth');
Irssi::command_bind('fbstatus','fb_setStatus');
