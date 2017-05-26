#!/usr/bin/perl -w

use strict;
use Frontier::Client;
use Getopt::Long;
use Data::Dumper;
use SOAP::Lite;

my $RHN_HOST = '';
my $user = '';
my $pass = '';

my $dry_run = 0;

&GetOptions("dry-run" => \$dry_run);

my $client = new Frontier::Client(url => "http://$RHN_HOST/rpc/api");
my $session = $client->call('auth.login',$user, $pass);
  
my $groups = $client->call('systemgroup.listAllGroups', 
                            $session);

foreach my $g (@$groups) {
    my $grp = $g->{'name'};

    # now get systems in group
    my $systems = $client->call('systemgroup.listActiveSystemsInGroup', 
                                $session, $grp);
    foreach my $s (@$systems) {
        my $i = $client->call('system.getDetails', $session, $s);
        print $i->{'hostname'}, ",", $grp, ",", $i->{'release'}, ",";

        $i = $client->call('system.getCpu', $session, $s);
        print $i->{'model'}, ",";

        $i = $client->call('system.getMemory', $session, $s);
        print $i->{'ram'}, "MB\n";
    }
}
$client->call('auth.logout', $session);
