package Validate::Plugin::dns_base;

use strict;
use Validate::Plugin::DNS;

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
   
   my $dns =  Validate::Plugin::DNS->new($validate);
   my %return = $dns->check("$site","2001:470:1:18:1000::46","A");
   unless ($return{"status"} eq "ok") {
     if ($return{"found"} =~ /AAAA/) {
       $return{"brief"}="$site should be single stack IPv4";
     }
     $return{"notes"} .= "\n\nIn particular, we expect this name to be IPv4 only.  If a client has IPv6 problems, we wish them to reach our IPv4 site, so we can tell them that IPv6 is broken.\n";
   }
   
   return \%return;
}

1;
