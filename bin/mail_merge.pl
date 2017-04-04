#!/usr/bin/perl -w

use strict;
use Net::SMTP;
use Getopt::Long;
use Data::Dumper;

my ($dry_run, $template, $data, $from, $subject, @msg_tpl, $smtp_server);
$dry_run = 0;

GetOptions("template=s" => \$template, "input=s" => \$data, "dry-run" => \$dry_run, "from=s" => \$from,
           "subject=s" => \$subject, "server=s" => \$smtp_server);

if ($template && $data && $subject && $from && $smtp_server) {
  # format mail date
  my @days = ("Sunday", "Monday", "Tuesday", "Wednesday",
              "Thursday", "Friday", "Saturday");

  my @months = ('Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec');

  my $now_time_t = time();
  my ($mwd, $mmd, $mmon, $my, $mh, $mmin) = (localtime(time()))[6,3,4,5,2,1];
  if ($mmd < 10)  { $mmd = "0${mmd}"; }
  if ($mh < 10)   { $mh = "0${mh}"; }
  if ($mmin < 10) { $mmin = "0${mmin}"; }
  $my += 1900;
  my $mtime = join(':', $mh, $mmin, '00');
  my $mday = substr($days[$mwd], 0, 3) . ",";
  
  my $mail_date = join(' ', $mday, $mmd, $months[$mmon], $my, 
                       $mtime, '-0700');

  # read in template 
  open(FH, $template) || die "$!\n";
  @msg_tpl = <FH>;
  close(FH);
 
  # open input file and read in header to get variable substitutions
  open(DFH, $data) || die "$!\n";
  my $h = <DFH>;
  chomp($h);
  my @vars = split(/\,/, $h);

  while(my $l = <DFH>) {
    chomp($l);
    my $p = {};
    my @v = split(/\,/, $l);

    for (my $i = 0; $i < scalar(@vars); $i++) {
      $p->{"::" . $vars[$i]} = $v[$i];
    }

    my $msg = join('', @msg_tpl);

    foreach my $k (keys(%$p)) {
      my $val = $p->{$k};
      $msg =~ s/$k/$val/gm;    
    }

    if ($dry_run) {
      print $msg, "\n";
      close(DFH);
      exit(0);
    } else {
      my $rcpt = $p->{'::EMAIL'};

      print "Sending to $rcpt...\n";
      my $smtp = Net::SMTP->new($smtp_server);
      $smtp->mail($from);
      $smtp->to($rcpt);
      $smtp->data();

      $smtp->datasend("From: " . $from . "\n");
      $smtp->datasend("To: " . $rcpt . "\n");
      $smtp->datasend("MIME-Version: 1.0\n");
      $smtp->datasend("Date: " . $mail_date . "\n");
      $smtp->datasend("Subject: " . $subject . "\n\n");
      $smtp->datasend($msg);
      $smtp->dataend() or print "Message sending failed!";
      $smtp->quit;      
    }
  }
  close(DFH);
} else {
  print "Usage: $0 --template=<template file> --input=<input file> --subject=<message subject> --from=<from address> --srver=<smtp server> [--dry-run]\n";
  exit(-1);
}

exit(0);
