#! /usr/bin/perl

use LWP::Simple qw();
use HTTP::Async;
use HTML::Strip;
use JSON;
use YAML::Syck;
use Getopt::Long;
use strict;
use MIME::Entity

$| = 1;

my %mailto = ( 'test-ipv6.internet.fo' => [ 'Pall Wiberg Joensen', 'PWJ@ft.fo' ], );

my ( %argv, %input, $usage );

%input = (
           "s|server=s"    => "server to audit",
           "v|validator=s" => "validator url to use",
           "m|mirrors"     => "check all mirrors",
           "email"         => "generate email (But don't send without --verp=jfesler)",
           "verp=s"        => "go ahead and send the email",
           "v|verbose"     => "spew extra data to the screen",
           "h|help"        => "show option help"
         );

my $result = GetOptions( \%argv, keys %input );
$argv{"v"} ||= $argv{"n"};

if ( ( !$result ) || ( $argv{h} ) ) {
    &showOptionsHelp;
    exit 0;
}
$argv{"v"} ||= "http://beta.validator.test-ipv6.com/validate.cgi";

my @servers;
if ( $argv{"s"} ) {
    push( @servers, $argv{"s"} );
}
if ( $argv{"m"} ) {
    push( @servers, get_mirrors() );
}
if (@ARGV) {
    push( @servers, @ARGV );
}

if ( !@servers ) {
    print "No servers specified or found.\n\n";
    &showOptionsHelp;
    exit 1;
}

my $async = HTTP::Async->new( slots => 20 ) or die;
my %ids;
foreach my $server (@servers) {
    my $url = server_plugin_url( $server, "_all" );
    my ($id) = $async->add( HTTP::Request->new( GET => $url ) );
    $ids{$id} = $server;
}

while ( $async->not_empty ) {

#  print "Waiting\n";
#      print $async->info;

    my ( $response, $id ) = $async->wait_for_next_response;
    my $server = $ids{$id};
    if ( $response->is_success ) {
        handle_response( $server, $response->decoded_content );
    } else {
        print STDERR "$server: ", $response->status_line, "\n";
    }

}

sub handle_response {
    my ( $server, $content ) = @_;
    my $ref    = decode_json($content);
    my $all    = $ref->{all} || die;
    my $config = $all->{_config}->{config} || die;
    delete $all->{_config};
    
    if (-d ".dump") {
      DumpFile(".dump/$server.yaml",$all);
    }
    

    # Do we have any problems?
    my @plugins = sort keys %{$all};
    my @not_ok = grep( $all->{$_}->{status} ne "ok", @plugins );
    return unless (@not_ok);

    # Boy do we.
    print "$server - please fix:  @not_ok\n";
    

    return unless ( $argv{"email"} );
$DB::single=1;
    # Who do we need to notify?
    my $contact = $config->{site}->{contact};
    my $mailto  = $config->{site}->{mailto};
    if ( exists $mailto{$server} ) {
        ( $contact, $mailto ) = @{ $mailto{$server} };
    }
    
    my $errors="";
    foreach my $plugin (@not_ok) {
    $DB::single=1;
      my $brief = $all->{$plugin}->{brief};
      $brief = $brief ? "- $brief" : "";
      $errors .= "       $plugin $brief\n";
    }
    $errors =~ s/^       /Errors:/;
    
    

    my $message = <<"EOF";
Hello, $contact

My (automated) audit scripts show one or more errors with your mirror site.
Please schedule time to correct these in a reasonable time frame.

Server: $server
$errors

You can find more info, with real time testing/auditing, by visiting:

http://validate.test-ipv6.com/?#server=$server

Thanks, -jason <jfesler\@test-ipv6.com>
EOF

    my $subject = "$server mirror status (@not_ok)";
    my $entity = MIME::Entity->build(
                                   From     => Encode::encode( "MIME-Header", 'Jason Fesler <jfesler@test-ipv6.com>' ),
                                   Cc       => Encode::encode( "MIME-Header", 'Jason Fesler <jfesler@test-ipv6.com>' ),
                                   To       => Encode::encode( "MIME-Header", "$contact <$mailto>" ),
                                   Subject  => Encode::encode( "MIME-Header", $subject ),
                                   Type     => "text/plain",
                                   Charset  => "UTF-8",
                                   Encoding => "quoted-printable",
                                   Data     => Encode::encode( "UTF-8",       $message ),
                                    );
    if ( $argv{"verp"} ) {
        print "Sending VERP'd mail to $mailto\n";
        open( SENDMAIL, "| /usr/sbin/sendmail -XV -f $argv{verp} -t" );
    } else {
        open( SENDMAIL, "|egrep -n ^" );
    }
            print SENDMAIL $entity->stringify;
                    close SENDMAIL;
                    

} ## end sub handle_response

sub get_mirrors {
    my $url = server_plugin_url( "test-ipv6.com", "_mirrors" );
    my $got = LWP::Simple::get($url);
    my $ref = decode_json($got);
    if ( !$ref ) {
        die "Something went wrong getting the mirror list from $url, or parsing it";
    }
    return @{ $ref->{mirrors} };
}

sub server_plugin_url {
    my ( $server, $plugin ) = @_;
    my $url = $argv{"v"} . "?" . "server=" . $server . "&plugin=" . $plugin;
    return $url;
}

sub showOptionsHelp {
    my ( $left, $right, $a, $b, $key );
    my (@array);
    print "Usage: $0 [options] $usage\n";
    print "where options can be:\n";
    foreach $key ( sort keys(%input) ) {
        ( $left, $right ) = split( /[=:]/, $key );
        ( $a,    $b )     = split( /\|/,   $left );
        if ($b) {
            $left = "-$a --$b";
        } else {
            $left = "   --$a";
        }
        $left = substr( "$left" . ( ' ' x 20 ), 0, 20 );
        push( @array, "$left $input{$key}\n" );
    }
    print sort @array;
}
