### -*-Makefile-*- to build GNU Emacs Modified for macOS
##
## Copyright (C) 2014-2017 Vincent Goulet
##
## The code of this Makefile is based on a file created by Remko
## Troncon (http://el-tramo.be/about).
##
## Author: Vincent Goulet
##
## This file is part of GNU Emacs Modified for macOS
## http://github.com/vigou3/emacs-modified-macos

## Set most variables in Makeconf
include ./Makeconf

## Build directory et al.
TMPDIR=${CURDIR}/tmpdir
TMPDMG=${CURDIR}/tmpdmg.dmg
EMACSDIR=${TMPDIR}/Emacs-configured.app

## Emacs specific info
PREFIX=${EMACSDIR}/Contents
EMACS=${PREFIX}/MacOS/Emacs
EMACSBATCH = $(EMACS) -batch -no-site-file -no-init-file

## Override of ESS variables
DESTDIR=${PREFIX}/Resources
SITELISP=${DESTDIR}/site-lisp
#LISPDIR=${DESTDIR}/site-lisp
ETCDIR=${DESTDIR}/etc
DOCDIR=${DESTDIR}/doc
INFODIR=${DESTDIR}/info

all : emacs release

emacs : get-emacs dir dmg

release : create-release upload publish

.PHONY : emacs dir dmg release create-release upload publish clean

dir :
	@echo ----- Creating the application in temporary directory...
	if [ -d ${TMPDIR} ]; then rm -rf ${TMPDIR}; fi
	hdiutil attach ${DMGFILE} -noautoopen -quiet
	ditto -rsrc ${VOLUME}/Emacs/Emacs.app ${EMACSDIR}
	hdiutil detach ${VOLUME}/Emacs -quiet
	cp -p default.el ${SITELISP}/
	curl --output ${SITELISP}/site-start.el https://raw.githubusercontent.com/izahn/dotemacs/master/init.el
	curl --output ${SITELISP}/essh.el https://raw.githubusercontent.com/izahn/dotemacs/master/lisp/essh.el
	curl --output ${SITELISP}/hfyview.el https://raw.githubusercontent.com/izahn/dotemacs/master/lisp/hfyview.el
	curl --output ${SITELISP}/win-win.el https://raw.githubusercontent.com/izahn/dotemacs/master/lisp/win-win.el
	sed -e '/^(defconst/s/<DISTVERSION>/${DISTVERSION}/' \
	    version-modified.el.in > ${SITELISP}/version-modified.el
	$(EMACSBATCH) -f batch-byte-compile ${SITELISP}/version-modified.el
	cp -p Emacs.icns ${DESTDIR}/

dmg :
#	@echo ----- Signing the application...
	@echo ----- Warning _Not_ Signing the application...
	rm -rf ${PREFIX}/_CodeSignature
#	codesign --force --sign "Developer ID Application: Vincent Goulet" \
#		${EMACSDIR}

	@echo ----- Creating disk image...
	if [ -e ${TMPDMG} ]; then rm ${TMPDMG}; fi
	hdiutil create ${TMPDMG} \
		-size 200m \
	 	-format UDRW \
		-fs HFS+ \
		-srcfolder ${TMPDIR} \
		-volname ${DISTNAME} \
		-quiet

	@echo ----- Mounting disk image...
	hdiutil attach ${TMPDMG} -noautoopen -quiet

	@echo ----- Populating top level image directory...
	cp -p README.txt.in ${VOLUME}/${DISTNAME}/README.txt
	cp -p NEWS ${VOLUME}/${DISTNAME}/
	ln -s /Applications ${VOLUME}/${DISTNAME}/Applications

	@echo ----- Unmounting and compressing disk image...
	hdiutil detach ${VOLUME}/${DISTNAME} -quiet
	if [ -e ${DISTNAME}.dmg ]; then rm ${DISTNAME}.dmg; fi
	hdiutil convert ${TMPDMG} \
		-format UDZO \
		-imagekey zlib-level=9 \
		-o ${DISTNAME}.dmg -quiet

	rm -rf ${TMPDIR} ${TMPDMG}
	@echo ----- Done building the disk image

create-release :
	@echo ----- Creating release on GitHub...
	if [ -e relnotes.in ]; then rm relnotes.in; fi
	git commit -a -m "Version ${VERSION}" && git push
	awk 'BEGIN { ORS=" "; print "{\"tag_name\": \"v${VERSION}\"," } \
	      /^$$/ { next } \
              (state==0) && /^# / { state=1; \
	                            print "\"name\": \"Emacs Modified for macOS ${VERSION}\", \"body\": \""; \
	                             next } \
	      (state==1) && /^# / { state=2; print "\","; next } \
	      state==1 { printf "%s\\n", $$0 } \
	      END { print "\"draft\": false, \"prerelease\": false}" }' \
	      NEWS > relnotes.in
	curl --data @relnotes.in ${REPOSURL}/releases?access_token=${OAUTHTOKEN}
	rm relnotes.in
	@echo ----- Done creating the release

upload :
	@echo ----- Getting upload URL from GitHub...
	$(eval upload_url=$(shell curl -s ${REPOSURL}/releases/latest \
	 			  | awk -F '[ {]' '/^  \"upload_url\"/ \
	                                    { print substr($$4, 2, length) }'))
	@echo ${upload_url}
	@echo ----- Uploading the disk image to GitHub...
	curl -H 'Content-Type: application/zip' \
	     -H 'Authorization: token ${OAUTHTOKEN}' \
	     --upload-file ${DISTNAME}.dmg \
             -s -i "${upload_url}?&name=${DISTNAME}.dmg"
	@echo ----- Done uploading the disk image

publish :
	@echo ----- Publishing the web page...
	${MAKE} -C docs
	@echo ----- Done publishing

get-emacs :
	@echo ----- Fetching Emacs...
	if [ -f ${DMGFILE} ]; then rm ${DMGFILE}; fi
	curl -O -L http://emacsformacosx.com/emacs-builds/${DMGFILE}

clean :
	rm ${DISTNAME}.dmg
