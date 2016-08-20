#! /usr/bin/perl

use CGI::Carp qw(fatalsToBrowser);
use CGI qw(:standard -debug);
use LWP::UserAgent;
use URI;
use Socket;
use Socket6;
use strict;

my $q      = new CGI;
my $method = $q->request_method;

die "Use POST instead of $method" unless ($method eq "POST");

my $timeout = $q->param("timeout");
my $url     = $q->param("url");
if ( $url =~ m#^https?://# ) {
    checkHostname($url);
    checkUrl($url,$timeout);
} else {
    die "Missing URL parameter\n";
}

sub checkHostname {
    my ($url) = @_;
    my $u = URI->new($url);
    die "bad url"    unless ($u);
    die "bad scheme" unless ( $u->scheme =~ m#^(http|https)$# );
    die "bad port"   unless ( $u->port =~ m#^(80|443)$# );
    my ( $family, $socktype, $proto, $saddr, $canonname, @res );
    @res = getaddrinfo( $u->host, 'daytime', AF_UNSPEC, SOCK_STREAM );
    while ( scalar @res == 5 ) {
        ( $family, $socktype, $proto, $saddr, $canonname, @res ) = @res;
        my ( $host, $port ) = getnameinfo( $saddr, NI_NUMERICHOST | NI_NUMERICSERV );
        die "bad host" if ( $host eq "127.0.0.1" );
        die "bad host" if ( $host eq "::1" );
    }
}

sub checkUrl {
    my ( $url, $timeout ) = @_;
    $timeout = 3  if ( $timeout < 3 );
    $timeout = 15 if ( $timeout > 15 );
    my $ua = LWP::UserAgent->new();
    $ua->timeout($timeout);
    my $response = $ua->get($url);
    print "Status: " . $response->status_line . "\n";
    foreach my $label (qw( Content-Type )) {
      my $val = $response->header($label);
      print "$label: $val\n" if ($val);
    }
    print "Content-length: 0\n\n";
    exit;
}
