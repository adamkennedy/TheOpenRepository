DIRS = c_stuff

PREFIX = /usr/local
DATADIR = $(PREFIX)/share
BINDIR = $(PREFIX)/bin
MANDIR = $(DATADIR)/man

all: dirs

dirs:
	@for n in . $(DIRS); do \
		[ "$$n" = "." ] || $(MAKE) -C $$n ;\
	done
	@if [ ! -d save_virgin ]; then mkdir save_virgin; cp c_stuff/lib/fb_stuff.pm save_virgin; fi
	cp -f save_virgin/fb_stuff.pm c_stuff/lib/fb_stuff.pm
	perl -pi -e 's|\@DATADIR\@|$(DATADIR)|' c_stuff/lib/fb_stuff.pm


install: $(ALL)
	@for n in $(DIRS); do \
		(cd $$n; $(MAKE) install) \
	done
	install -d $(BINDIR)
	install frozen-bubble frozen-bubble-editor $(BINDIR)
	install -d $(DATADIR)/frozen-bubble
	cp -a gfx snd data $(DATADIR)/frozen-bubble
	install -d $(MANDIR)/man6
	install doc/*.6 $(MANDIR)/man6

clean: 
	@for n in $(DIRS); do \
		(cd $$n; $(MAKE) clean) \
	done
	@if [ -d save_virgin ]; then cp -f save_virgin/fb_stuff.pm c_stuff/lib/fb_stuff.pm; rm -rf save_virgin; fi

