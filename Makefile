FILES=*.js *.css *.html *.cgi lib  .htaccess ../source/images
JSFILES=source/*.js
CSSFILES=source/*.css

BETA_HOST=gigo.com
BETA_DIR=/var/www/beta.validator.test-ipv6.com

PROD_HOST=london.gigo.com
PROD_DIR=/var/www/validator.test-ipv6.com/

default:: beta

test:
	perl  ./validate.cgi "server=test-ipv6.com&plugin=dns_ds_v4ns"

beta:
	make DESTHOST=$(BETA_HOST) DESTDIR=$(BETA_DIR) install
	
prod:
	make DESTHOST=$(PROD_HOST) DESTDIR=$(PROD_DIR) install



install: index.js index.css
	ssh -t $(DESTHOST) mkdir -p $(DESTDIR)/cache
	ssh -t $(DESTHOST) "ls -ld $(DESTDIR)/cache | cut -f1 | grep drwsrwxrwx || sudo chmod 4777 $(DESTDIR)/cache"
	rsync -av $(FILES) $(DESTHOST):$(DESTDIR)/  --delete


index.js: $(JSFILES)
	cat $(JSFILES) > index.js
	 
index.css: $(CSSFILES)
	cat $(CSSFILES) > index.css
	