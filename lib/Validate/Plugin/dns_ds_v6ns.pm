package Validate::Plugin::dns_ds_v6ns;

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

    my %return_dualstackdns = $dns->check( "$check", "66.220.4.227", "A", "AAAA" );
    my %return_singlestackdns = $dns->check( "$check", "66.220.4.226", "A", "AAAA" );
$DB::single=1;
    if ( $return_dualstackdns{"status"} ne "ok" ) {
        return \%return_dualstackdns;
    }

    my %return;
    $return{"expect"} = <<EOF;
 Success with a dual stack DNS server
 Failure with a single stack DNS server.
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

 % dig \@66.220.4.227 $check A
 % dig \@66.220.4.227 $check AAAAA

Single stack DNS server test (should fail):

 % dig \@66.220.4.226 $check A
 % dig \@66.220.4.226 $check AAAA
 
You can also reproduce this with other DNS servers.  Examples 
(in order) would be 8.8.8.8 for a dual stack DNS server operated
by Google; and 4.2.2.1 for a single stack DNS server operated by Level 3.
 

Please see
https://github.com/falling-sky/source/wiki/InstallDNS for setup and
validation.
EOF

    if ( $return_singlestackdns{"status"} eq "ok" ) {

        # Wait, that is unexpected.
        $return{"status"} = "bad";
        $return{"found"}  = "found results via '<code>dig \@66.220.4.226 a $check</code>'";
        return \%return;
    } else {
        $return{"status"} = "ok";
        $return{"found"}  = $return{"expect"};
        return \%return;

    }
} ## end sub run

1;
