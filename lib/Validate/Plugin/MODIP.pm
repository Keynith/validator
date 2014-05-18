package Validate::Plugin::MODIP;

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
  foreach my $a (qw( Content-Type Expires Pragma Cache-control Exit-Code)) {
    $s .= "$a\: $hash{$a}\n" if (exists $hash{$a});
  }
  return $s;
}

sub check {
  my $self = shift;
  my $host = shift;
     my $validate = $self->{validate};
     
  my $url = ($host =~ /:/) ? "http://[$host]/ip/?callback=example&asn=1" : "http://$host/ip/?callback=example&asn=1";
$DB::single=1;  
  my ( $content, $headers ) = $self->{validate}->curl( $url, "--get" );
  my($status) = split(/[\r\n]/,$headers);

$DB::single=1 ;
  my %results = $self->header_to_hash($headers);
  my $found = $self->comparable(%results);
  
  my $expected_headers = <<"EOF";
HTTP/1.1 200 OK
Cache-Control: no-cache
Pragma: no-cache
Expires: Thu, 01 Jan 1971 00:00:00 GMT
Content-Type: application/javascript;charset=UTF-8
Exit-Code: 0
Exit-Reason: No reason.
EOF
  
  my $expect = $self->comparable($self->header_to_hash($expected_headers));
  
  my $expected_headers_i = $validate->indent($expected_headers);
  my $expect_i = $validate->indent($expect);
  my $found_i = $validate->indent($found);
  
   my $wanted = $content;
   $wanted =~ s/"via":""/"via":"","asn":"6939","asn_name":"HURRICANE - Hurricane Electric, Inc.","asnlist":"6939"/;
   my $wanted_i = $validate->indent($wanted);
   my $content_i = $validate->indent($content);

my $header_notes = <<"EOF";

One or more headers is missing or wrong. 

This is likely correctable by simply updating to the latest version of
mod_ip.  Additionally, if you have upgraded from an installation predating
May 2013, you may need to still clean up your Apache configuration.

When testing, we expect to see something like this for the headers:

 % curl -I "$url"
$expected_headers_i

Solutions:

* Upgrade
* Clean up your Apache configuration per May 2013 recommendations
* http://code.google.com/p/falling-sky/wiki/InstallModIP
* http://code.google.com/p/falling-sky/wiki/InstallApacheVirtualHost
EOF

my $content_notes = <<"EOF";
We did not see the asnlist feature in mod_ip working.

This is likely correctable by simply updating to the latest version of
mod_ip.

When testing, we expect to see something like:

 % curl "$url"
<code>$wanted</code>

Solutions:

* Upgrade
* Clean up your Apache configuration per May 2013 recommendations
* http://code.google.com/p/falling-sky/wiki/InstallModIP
* http://code.google.com/p/falling-sky/wiki/InstallApacheVirtualHost
EOF

           
  
  
  if ($found ne $expect) {
    return(status=>"bad",url=>$url,expect=>$expect_i,found=>$found_i,notes=>$header_notes);
  }
  
#   Okay, the headers were fine.  What about content?

  if ($content !~ /asnlist/) {
   
   return(status=>"bad",url=>$url,expect=>$wanted_i,found=>$content_i,notes=>"Looks like an outdated version of mod_ip; missing asnlist in the output." . $content_notes);
  }
  
  return(status=>"ok",url=>$url,  expect=>$expect_i,found=>$found_i);
  
  
}

1;
