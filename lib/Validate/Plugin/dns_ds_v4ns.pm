package Validate::Plugin::dns_ds_v4ns;

use strict;
use Validate::Plugin::DNS;

sub new {
    my $classname = shift;
    my $self      = {};
    bless( $self, $classname );
    $self->{validate} = shift;
    return $self;
}

sub run {
    my $self     = shift;
    my $validate = $self->{validate};
    my $config   = $validate->{config};

    my %config = %{$config};
    my $site   = $config{"site"}{"name"};
    my $domain = $config{"load"}{"domain"};

    my $dns = Validate::Plugin::DNS->new($validate);
    my $check = "ds.v6ns.$domain";

    my %return = $dns->check( "$check", "2001:470:1:18:1000::4","A","AAAA");
    
    $return{"expect"} = <<EOF;
 $check A SERVFAIL
 $check AAAA SERVFAIL
 (When asking via IPv4-only resolver)
EOF
    
    $return{"notes"}  = <<"EOF";
This test is to ensure that the $check address is only resolved when using a
DNS server that is dual-stack.  It does not matter which protocol you use to
ask the DNS question; it does matter what the DNS server is capable of
using.  This is the last and final test that users see on test-ipv6.com.

To give accurate results, we must ONLY serve answers for $check when the
question is asked via IPv6.  For most people this means not running the
"v6ns" zone on the same server as your main DNS.  Most people run the v6ns1
server as part of their test-ipv6.com mirror; and one server is enough.

For the same of completeness, this is what we are looking for:

Dual stack DNS server test (should succeed):

 % dig \@8.8.8.8 $check A
 % dig \@8.8.8.8 $check AAAAA

Single stack DNS server test (should fail):

 % dig \@4.2.2.1 $check A
 % dig \@4.2.2.1 $check AAAA
 
Please see
https://github.com/falling-sky/source/wiki/InstallDNS for setup and
validation.
EOF

$DB::single=1;
    if (($return{"found"} =~ / A SERVFAIL/) &&
    ($return{"found"} =~ / AAAA SERVFAIL/)) {
      $return{"status"}="ok";
    } else {
      $return{"status"}="bad";
    }
    return \%return;
} ## end sub run

1;
