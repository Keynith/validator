package Validate::Plugin::mtu_pmtud;

use strict;
use Validate::Plugin::DNS;
use CGI qw(escapeHTML);

sub new {
    my $classname = shift;
    my $self      = {};
    bless( $self, $classname );
    $self->{validate}=shift;
    return $self;
}

sub run {
   my $self = shift;
   my $validate = $self->{validate};
   my $config = $validate->{config};
   $DB::single=1;
   my %config = %{ $config};
   my $site   = $config{"site"}{"name"};
   my $domain = $config{"load"}{"domain"};
   my $mtu1280 = $config{"options"}{"v6mtu"};
   
   if (!$mtu1280) {
     return {
       status=>"bad",
       found=>"site config missing options -> v6mtu",
       expect=>"site config options->v6mtu configured",
       notes=>"Please see https://github.com/falling-sky/source/wiki/InstallPMTUD"
     };
   }
   
   my $pinghost = $mtu1280;
   my $cmd = "ping6 -M dont -c 3 -s 1452 " . "\Q$pinghost";
   my $output = `$cmd 2>&1`;
   
   my $output_html = escapeHTML($output);
   $output_html  =~ s/\n/<br>/g;
   
   my %return;
   # status=>"bad",url=>$url,expect=>$expect_i,found=>$found_i,notes=>"One or more headers is missing or wrong." . $bignotes
   
   $return{"notes"} = <<"EOF";
We ran this command:

$cmd

We expected to see (on this version test) to see a ping failure;
with a response of "Packet too big".

What we received was:

$output_html

For more information, please see
https://github.com/falling-sky/source/wiki/InstallPMTUD
EOF
   
   $return{"expect"} = "ping -M dont -c 3 -s 1452 $pinghost fails with 'Packet too big'<br>(testing for emulated MTU of 1280)";
   $return{"found"} = $output_html;
   if ($output =~ /mtu=1280/) {
     $return{"status"}="ok";
   } else {
     $return{"status"}="bad";
   }
   
   return \%return;
}

1;
