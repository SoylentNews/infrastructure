vcl 4.1;

# This is a basic VCL configuration file for varnish.  See the vcl(7)
# man page for details on VCL syntax and semantics.
# 
# Default backend definition.  Set this to point to your content
# server.
# 

# HOST must be localhost, not IP, slash goes boom otherwise
backend slash {
    .host = "rehash";
    .port = "80";
    .connect_timeout = 200ms;
    .first_byte_timeout = 30s;
    .between_bytes_timeout = 60s;
#    .probe = {
#          .url = "/slashcode.css";
#          .timeout = 34 ms;
#          .interval = 1s;
#          .window = 10;
#          .threshold = 8;
#     }
}

acl purge {
        "localhost";
}

#acl upstream_proxy {
#  "127.0.0.1";
#  "192.168.0.0"/16;
#}

#acl tor_proxy {
#  "173.255.194.21";
#  "192.168.170.201";
#  "2600:3c00::f03c:91ff:fe6e:c4bf";
#}

sub vcl_recv {
	# Fix X-Forwarded-For
	#if (client.ip ~ upstream_proxy && req.http.X-Forwarded-For) {
		set req.http.X-Forwarded-For = req.http.X-Forwarded-For;
	#} else {
	#	unset req.http.X-Forwarded-For;
	#	unset req.http.X-SSL-On;
	#	set req.http.X-Forwarded-For = client.ip;
	#}


#	if (!(client.ip ~ tor_proxy) && req.http.X-Forwarded-Proto !~ "(?i)https") {
#		set req.http.x-Redir-Url = "https://" + req.http.Host + req.url;
#		error 750 req.http.x-Redir-Url;
#   	}

        # allow PURGE from localhost and 192.168.55...
        if (req.method == "PURGE") {
                if (!client.ip ~ purge) {
			return(synth(405,"Not allowed."));
                }
                return (purge);
        }

	# do MAGIC if we're SSL
  	#if (!req.backend.healthy) {
	#    set req.grace = 1h;
	#    return (lookup);
	#}

	#if (req.url ~ "\.(png|gif|jpg|swf|css|js)(\?.*|)$") {
	#	return (lookup);
	#}
	
	# Many requests contain cookies on requests for resources which cookies don't matter -- such as static images or documents.
	if (req.url ~ "\.(png|gif|jpg|swf|css|js)(\?.*|)$") {
		# Remove cookies from these resources, and remove any attached query strings.
		unset req.http.cookie;
  	}

	# Always send posts through if not rate limited
	if (req.method == "POST") {
		return(pass);
	}

	# We don't cache if we're logged in, or if its the login page
	if (req.url ~ "(login).*") {
		return (pass);
	}

	# We don't cache subscribe.pl
        if (req.url ~ "(subscribe).*") {
                return (pass);
        }

	# We don't cache search
        if (req.url ~ "(search).*") {
                return (pass);
        }

        # We don't cache ppipn.pl
        if (req.url ~ "/ppipn.pl") {
                return (pass);
        }

	if (req.http.cookie ~ "(user)") {
		return(pass);
	}

	if (req.http.cookie ~ "(seasonkey)") {
		return(pass);
	}

	return(hash);
}

sub vcl_hit {

}

sub vcl_miss {

}
