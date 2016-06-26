#! /usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard -debug);
use LWP::UserAgent;
use FindBin qw($Bin);
use lib "$Bin/lib";
use strict;

my $q      = new CGI;
my $method = $q->request_method;

#die "Use POST instead of $method" unless ($method eq "POST");

my $timeout = $q->param("timeout");
my $url     = $q->param("url");
if ( $url =~ m#^https?://# ) {
    checkUrl($url);
} else {
    die "Missing URL parameter\n";
}

sub checkUrl {
    my ( $url, $timeout ) = @_;
    $timeout = 3  if ( $timeout < 3 );
    $timeout = 15 if ( $timeout > 15 );
    my $ua = LWP::UserAgent->new();
    $ua->timeout($timeout);
    my $response = $ua->get($url);
    print "Status: " . $response->status_line;
    print "\n\n";
    print "Status: " . $response->status_line;
    exit;
}
