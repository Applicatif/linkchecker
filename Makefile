# This Makefile is only used by developers.
# You will need a Debian Linux system to use this Makefile because
# some targets produce Debian .deb packages
VERSION=$(shell ./setup.py --version)
PACKAGE=linkchecker
NAME=$(shell ./setup.py --name)
PACKAGEDIR=/home/groups/l/li/$(PACKAGE)
HTMLDIR=shell1.sourceforge.net:$(PACKAGEDIR)/htdocs
FTPDIR=shell1.sourceforge.net:/home/groups/ftp/pub/$(PACKAGE)
HOST=treasure.calvinsplayground.de
#LCOPTS=-ocolored -Ftext -Fhtml -Fgml -Fsql -Fcsv -Fxml -R -t0 -v -s
LCOPTS=-ocolored -Ftext -Fhtml -Fgml -Fsql -Fcsv -Fxml -R -t0 -v -s
OFFLINETESTS = test_base test_misc test_file test_frames
ONLINETESTS = test_mail test_http test_https test_news test_ftp
DESTDIR=/.

.PHONY: all
all:
	@echo "Read the file INSTALL to see how to build and install"

.PHONY: clean
clean:
	-./setup.py clean --all # ignore errors of this command
	$(MAKE) -C po clean
	find . -name '*.py[co]' | xargs rm -f

.PHONY: distclean
distclean: clean cleandeb
	rm -rf dist build # just to be sure clean also the build dir
	rm -f $(PACKAGE)-out.* VERSION _$(PACKAGE)_configdata.py MANIFEST Packages.gz

.PHONY: cleandeb
cleandeb:
	rm -rf debian/$(PACKAGE) debian/$(PACKAGE)-ssl debian/tmp
	rm -f debian/*.debhelper debian/{files,substvars}
	rm -f configure-stamp build-stamp

.PHONY: config
config:
	./setup.py config -lcrypto

# no more rpm package; too much trouble, cannot test
.PHONY: dist
dist:	locale config
	./setup.py sdist --formats=gztar,zip # bdist_rpm
	# extra run without SSL compilation
	./setup.py bdist_wininst

.PHONY: deb
deb:
	# cleandeb because distutils choke on dangling symlinks
	# (linkchecker.1 -> undocumented.1)
	$(MAKE) cleandeb
	fakeroot debian/rules binary
	fakeroot dpkg-buildpackage -sgpg -pgpg -k959C340F

.PHONY: packages
packages:
	-cd .. && dpkg-scanpackages . | gzip --best > Packages.gz

.PHONY: sources
sources:
	-cd .. && dpkg-scansources  . | gzip --best > Sources.gz

.PHONY: files
files:	locale
	env http_proxy="" ./$(PACKAGE) $(LCOPTS) -i$(HOST) http://$(HOST)/~calvin/

VERSION:
	echo $(VERSION) > VERSION

.PHONY: upload
upload: distclean dist deb files VERSION
	scp debian/changelog $(HTMLDIR)/changes.txt
	scp README $(HTMLDIR)/readme.txt
	scp linkchecker-out.* $(HTMLDIR)
	scp VERSION $(HTMLDIR)/raw/
	scp dist/* $(FTPDIR)/
	ssh -C -t shell1.sourceforge.net "cd $(PACKAGEDIR) && make"

.PHONY: test
test:
	python2 test/regrtest.py $(OFFLINETESTS)

.PHONY: onlinetest
onlinetest:
	python2 test/regrtest.py $(ONLINETESTS)

.PHONY: locale
locale:
	$(MAKE) -C po
