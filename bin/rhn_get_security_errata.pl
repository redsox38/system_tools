#!/usr/bin/perl -w

use strict;
use Frontier::Client;
use Getopt::Long;
use Data::Dumper;

my $RHN_HOST = '';
my $user = '';
my $pass = '';

my $group;

&GetOptions("group" => \$group);

my $client = new Frontier::Client(url => "http://$RHN_HOST/rpc/api");
my $session = $client->call('auth.login',$user, $pass);
  
my $systems = $client->call('systemgroup.listActiveSystemsInGroup', 
                            $session, $group);
my $i = 0;
my $j = 0;
print "System Name,Last Scheduled Patch Date,Outstanding Critical Errata,Last Reboot\n";

foreach my $s (@$systems) {
    my $cv = $client->call('system.getCustomValues', $session, $s);
    my $nm = $client->call('system.getName', $session, $s);
    my $ce = $client->call('system.getRelevantErrataByType', $session, $s, 'Security Advisory');
    my $deets = $client->call('system.getDetails', $session, $s);

    my $lb = sprintf("%d%02d%02d", unpack('A4A2A2', $deets->{'last_boot'}->value()));
    print $nm->{'name'} . "," . $cv->{'patch_date'} . "," . scalar(@$ce) . "," . $lb . "\n";
}

$client->call('auth.logout', $session);

exit(0);
