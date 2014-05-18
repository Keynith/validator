package Validate::Plugin::htrev;

use strict;

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

    my $expect = $self->get_version("http://test-ipv6.com/htrev/");
    my $found  = $self->get_version("http://$site/htrev/");

    my ( $stable_svn, $stable_hash ) = split( /-/, $expect);
    my ( $remote_svn, $remote_hash ) = split( /-/, ($found?$found:"") );
    
    if (($stable_hash eq $remote_hash) && ($stable_svn ne $remote_svn)) {
      return { status=>"ok",expect=>$expect,found=>$found,notes=>"Close enough - hash is correct (this file is the same across many versions)"};
    }

    my $notes = "Checked http://$site/htrev/ against http://test-ipv6.com/htrev/";

    if ( $found ne $expect ) {
        $notes = <<"EOF";
Upgrade needed for .htaccess (or your virtual host config) from $remote_svn to $stable_svn.

We specifically checked:
 % curl -I http://$site/htrev/

This URL should be handled by your apache config, or by .htaccess, in the form of a redirect.  

What we have found is that your configuration is either
that you are out of sync with the example file, vhost-long.conf.example;
or that your .htaccess files are out of date.

The latest "stable" version of the content has the correct versions
of the configuration that you need.  You can also see what is
live and deployed on the master site, at
http://test-ipv6.com/vhost-long.conf.example .

If you use the short form, vhost-short.conf.example,
then the likely issue is merely that your content needs
updating.  The content's distributed .htaccess files   
will take care of your needs once you update.

* http://code.google.com/p/falling-sky/wiki/InstallApacheVirtualHost
* http://code.google.com/p/falling-sky/wiki/InstallContent
* http://code.google.com/p/falling-sky/wiki/StayCurrent   
EOF
        return { status => "bad", expect => $expect, found => $found, notes => $notes };
    }
    return { status =>"ok", expect => $expect, found => $found, notes => $notes };
} ## end sub run

sub get_version {
    my $self = shift;
    my $url  = shift;
    $DB::single = 1;
    my ( $content, $headers ) = $self->{validate}->curl( $url, "--head");
    #Location: http://test-ipv6.com/?htrev=1306-566c7485c9f6198cedbae242049a8c78
    
      if ( $headers =~ m#^Location: \S+htrev=(\d+-[0-9a-f]+)#ms) {
        return $1;
    } else { 
       my($status) = split(/[\r\n]/,$headers);
       return $status;
    }

}

1;
