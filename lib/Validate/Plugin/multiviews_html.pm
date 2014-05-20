package Validate::Plugin::multiviews_html;

use strict;
use Validate::Plugin::MULTIVIEWS;


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
   
   my $modip =  Validate::Plugin::MULTIVIEWS->new($validate);
   my %return = $modip->check("http://$site/index.html",<<"EOF");
HTTP/1.1 200 OK
Content-Location: index.html.gz.fr_FR
Vary: negotiate,accept-language,accept-encoding
Content-Type: text/html; charset=utf-8
Content-Encoding: gzip
Content-Language: fr-fr
Exit-Code: 0
EOF
   
   unless ($return{"status"} eq "ok") {
   }
   
   return \%return;
}

1;
