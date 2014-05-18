package Validate::Plugin::IMAGES;

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
              foreach my $a (qw( Content-Type Expires Vary Exit-Code)) {
    $s .= "$a\: $hash{$a}\n" if (exists $hash{$a});
  }
  return $s;
}

sub check {
  my $self = shift;
  my $url = shift;
  my $expected_headers = shift;
       my $validate = $self->{validate};
       
       
  my ( $content, $headers ) = $self->{validate}->curl( $url, "--head");
  my($status) = split(/[\r\n]/,$headers);

$DB::single=1 ;
  my %results = $self->header_to_hash($headers);
  my $found = $self->comparable(%results);
  my $expect = $self->comparable($self->header_to_hash($expected_headers));
  
  my $found_i = $validate->indent($found);
  my $expect_i = $validate->indent($expect);

my $bignotes = <<"EOF";

URL: $url

Please make sure images are installed; are not mapped 
to another location on your file system; and have the correct
expiration data.  Expires are handled using mod_expires
plus the apache configuration that came with the falling-sky projoect.

We recommend allowing this virtualhost to override options;
doing so, will allow the bundled .htaccess files to take effect.

http://code.google.com/p/falling-sky/wiki/InstallContent
http://code.google.com/p/falling-sky/wiki/InstallApacheVirtualHost
EOF

           
  
  
  if ($found ne $expect) {
    return(status=>"bad",url=>$url,expect=>$expect_i,found=>$found_i,notes=>"One or more headers is missing or wrong." . $bignotes);
  }
  
  return(status=>"ok",url=>$url,  expect=>$expect_i,found=>$found_i);
  
}

1;
