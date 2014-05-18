package Validate::Plugin::MULTIVIEWS;

# Called by modip_ipv4, modip_ipv6, modip_ds, and so forth.

use strict;

sub new {
    my $classname = shift;
    my $self      = {};
    bless( $self, $classname );
    $self->{validate}=shift;
    return $self;
}

sub header_to_hash {
  my $self = shift;
  my $s = shift;
  my @list = split(/[\r\n]+/,$s);
  my %hash;
  if ($list[0] !~ /:/) {
    $hash{"Status"} = shift @list;
  }
  foreach my $line (@list ){
    my($a,$b) = split(/: /,$line,2);
    $hash{$a}=$b;
  }
  return %hash;
}

sub comparable {
  my($self) = shift;
  my(%hash) = @_;
  my $s = $hash{"Status"} . "\n";
    if (! $hash{"Exit-Code"}) {
        delete $hash{"Exit-Code"};
            delete $hash{"Exit-Reason"};
              }
              
  foreach my $a (qw( Content-Type Content-Location Content-Type Content-Encoding Content-Language Vary Exit-Code)) {
    $s .= "$a\: $hash{$a}\n" if (exists $hash{$a});
  }
  return $s;
}

sub check {
  my $self = shift;
  my $url = shift;
  my $expected_headers = shift;
       my $validate = $self->{validate};
       
       
  my ( $content, $headers ) = $self->{validate}->curl( $url, "--head", "-H","Accept-Encoding: gzip,deflate","-H","Accept-Language: fr" );
  my($status) = split(/[\r\n]/,$headers);

$DB::single=1 ;
  my %results = $self->header_to_hash($headers);
  my $found = $self->comparable(%results);
  my $expect = $self->comparable($self->header_to_hash($expected_headers));
  
  my $content_i = $validate->indent($content);
  my $found_i = $validate->indent($found);
  my $headers_i = $validate->indent($headers);
  my $expect_i = $validate->indent($expect);
  my $expected_headers_i = $validate->indent($expected_headers);

my $notes = <<"EOF";
URL: $url<br>
(while pretending to be a French-speaking web browser)

Multiviews is either misconfigured; or needs to be explicitly
configured in your main Apache config file (particularly for RHEL/Centos/Fedora).

Please make sure your Apache virtual host configuration matches the documentation.
If it is, then double check your main httpd.conf, and add <code>multiviews</code>
to your <code>Options</code> statement for the directory you host from.

* http://code.google.com/p/falling-sky/wiki/InstallApacheVirtualHost
EOF

           
  
  
  if ($found ne $expect) {
    return(status=>"bad",url=>$url,expect=>$expect_i,found=>$found_i,notes=>$notes);
  }
  
  return(status=>"ok",url=>$url,  expect=>$expect_i,found=>$found_i,notes=>"");
  
}

1;
