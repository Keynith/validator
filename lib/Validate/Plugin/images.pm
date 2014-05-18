package Validate::Plugin::images;

use strict;
use Validate::Plugin::IMAGES;


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
   
   my %config = %{ $config};
   my $site   = $config{"site"}{"name"};
   my $domain = $config{"load"}{"domain"};
   
   my $modip =  Validate::Plugin::IMAGES->new($validate);
   my %return = $modip->check("http://$site/images/knob_info.png",<<"EOF");
HTTP/1.1 200 OK
Expires: Mon, 01 Jan 2035 00:00:00 GMT
Content-Type: image/png
Exit-Code: 0
EOF
   
   unless ($return{"status"} eq "ok") {
   }
   
   return \%return;
}

1;
