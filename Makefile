### -*-Makefile-*- to build Emacs Modified for macOS
##
## Copyright (C) 2009-2022 Vincent Goulet
##
## The code of this Makefile is based on a file created by Remko
## Troncon (http://el-tramo.be/about).
##
## Author: Vincent Goulet
##
## This file is part of Emacs Modified for macOS
## https://gitlab.com/vigou3/emacs-modified-macos

## Emacs Modified for macOS is free software; you can redistribute it
## and/or modify it under the terms of the GNU General Public License
## as published by the Free Software Foundation; either version 3, or
## (at your option) any later version.
##
## GNU Emacs is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with GNU Emacs; see the file COPYING.  If not, write to the
## Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
## Boston, MA 02110-1301, USA.

## Set most variables in Makeconf
include ./Makeconf

## Build directory et al.
TMPDIR = ${CURDIR}/tmpdir
TMPDMG = ${CURDIR}/tmpdmg.dmg
EMACSDIR = ${TMPDIR}/Emacs.app
DICTDIR = ${TMPDIR}/Dictionaries

## Emacs specific info
PREFIX = ${EMACSDIR}/Contents
EMACS = ${PREFIX}/MacOS/Emacs
EMACSBATCH = $(EMACS) -batch -no-site-file -no-init-file

## Override of ESS variables
DESTDIR = ${PREFIX}/Resources
SITELISP = ${DESTDIR}/lisp
ETCDIR = ${DESTDIR}/etc
DOCDIR = ${DESTDIR}/doc
INFODIR = ${DESTDIR}/info

## Toolset
CP = cp -p
RM = rm -r
MD = mkdir -p
UNZIP = unzip
UNTAR = tar xzf
SVN = /Library/Developer/CommandLineTools/usr/bin/svn # for macOS >= 11 Big Sur

all: get-packages emacs

get-packages: get-emacs get-ess get-auctex get-markdownmode get-execpath get-psvn get-dict

emacs: dir ess auctex markdownmode execpath psvn dict dmg

dmg: codesign bundle notarize

release: staple check-status create-release create-link publish

.PHONY: dir
dir:
	@echo ----- Creating the application in temporary directory...
	if [ -d ${TMPDIR} ]; then ${RM} -f ${TMPDIR}; fi
	hdiutil attach ${DMGFILE} -noautoopen -quiet
	ditto -rsrc ${VOLUME}/Emacs/Emacs.app ${EMACSDIR}
	hdiutil detach ${VOLUME}/Emacs -quiet
	${CP} default.el ${SITELISP}/
	${CP} site-start.el ${SITELISP}/
	sed -E -i "" \
	    '/^\(defconst/s/(emacs-modified-version '"'"')[0-9]+/\1${DISTVERSION}/' \
	    version-modified.el && \
	  ${CP} version-modified.el ${SITELISP}/
	$(EMACSBATCH) -f batch-byte-compile ${SITELISP}/version-modified.el
	${CP} Emacs.icns ${DESTDIR}/

.PHONY: ess
ess:
	@echo ----- Making ESS...
	if [ -d ESS-master ]; then ${RM} -f ESS-master; fi
	${UNZIP} ${ESS}.zip
	${MAKE} EMACS=${EMACS} DOWNLOAD=curl -C ESS-master all
	${MAKE} EMACS=${EMACS} DESTDIR=${DESTDIR} SITELISP=${SITELISP} \
	        ETCDIR=${ETCDIR}/ess DOCDIR=${DOCDIR}/ess \
	        INFODIR=${INFODIR} -C ESS-master install
	${RM} -f ESS-master
	@echo ----- Done making ESS

.PHONY: auctex
auctex:
	@echo ----- Making AUCTeX...
	if [ -d ${AUCTEX} ]; then ${RM} -f ${AUCTEX}; fi
	${UNTAR} ${AUCTEX}.tar.gz
	cd ${AUCTEX} && ./configure --datarootdir=${DESTDIR} \
		--without-texmf-dir \
		--with-lispdir=${SITELISP} \
		--with-emacs=${EMACS}
	make -C ${AUCTEX}
	make -C ${AUCTEX} install
	${RM} -f ${AUCTEX}
	@echo ----- Done making AUCTeX

.PHONY: markdownmode
markdownmode:
	@echo ----- Copying and byte compiling markdown-mode.el...
	${CP} markdown-mode.el ${SITELISP}/
	$(EMACSBATCH) -f batch-byte-compile ${SITELISP}/markdown-mode.el
	@echo ----- Done installing markdown-mode.el

.PHONY: execpath
execpath:
	@echo ----- Copying and byte compiling exec-path-from-shell.el...
	${CP} exec-path-from-shell.el ${SITELISP}/
	$(EMACSBATCH) -f batch-byte-compile ${SITELISP}/exec-path-from-shell.el
	@echo ----- Done installing exec-path-from-shell.el

.PHONY: psvn
psvn:
	@echo ----- Patching and byte compiling psvn.el...
	patch -o ${SITELISP}/psvn.el psvn.el psvn.el_svn1.7.diff
	$(EMACSBATCH) -f batch-byte-compile ${SITELISP}/psvn.el
	@echo ----- Done installing psvn.el

.PHONY: dict
dict:
	@echo ----- Installing dictionaries...
	if [ -d ${DICTDIR} ]; then ${RM} -f ${DICTDIR}; fi
	${MD} ${DICTDIR}
	${UNZIP} -j -d ${DICTDIR} ${DICT-EN}.zip "*.aff" "*.dic" "th_en*" "README*en*.txt"
	${UNZIP} -j -d ${DICTDIR} ${DICT-FR}.zip dictionaries/* 
	${UNZIP} -j -d ${DICTDIR} ${DICT-ES}.zip "*.aff" "*.dic" "th_es*" "README*es*.txt"
	${UNZIP} -j -d ${DICTDIR} ${DICT-DE}.zip "de_DE_frami/*.aff" "de_DE_frami/*.dic" "de_DE_frami/*README.txt" "hyph_de_DE/*.dic" "hyph_de_DE/*README.txt" "thes_de_DE_v2/th_de_DE*"

.PHONY: codesign
codesign:
	@echo ----- Signing the application...
	codesign --force --sign "Developer ID Application: ${DEVELOPERID}" \
		 --options=runtime --deep \
	         ${EMACSDIR}
	@echo ----- Done signing the application...

.PHONY: bundle
bundle:
	@echo ----- Creating disk image...
	if [ -e ${TMPDMG} ]; then rm ${TMPDMG}; fi
	hdiutil create ${TMPDMG} \
		-size 350m \
	 	-format UDRW \
		-fs HFS+ \
		-srcfolder ${TMPDIR} \
		-volname ${DISTNAME} \
		-quiet

	@echo ----- Mounting disk image...
	hdiutil attach ${TMPDMG} -noautoopen -quiet

	@echo ----- Populating top level image directory...
	sed -E -i "" \
	    -e 's/(GNU Emacs )[0-9.]+/\1${EMACSVERSION}/' \
	    -e 's/(ESS )[0-9.a-z]+/\1${ESSVERSION}/' \
	    -e 's/(AUCTeX )[0-9.]+/\1${AUCTEXVERSION}/' \
	    -e 's/(markdown-mode.el )[0-9.]+/\1${MARKDOWNMODEVERSION}/' \
	    -e 's/(exec-path-from-shell.el )[0-9.]+/\1${EXECPATHVERSION}/' \
	    -e 's/(psvn.el r)[0-9]+/\1${PSVNVERSION}/' \
	    -e 's/(English \(version )[0-9a-z.]+/\1${DICT-ENVERSION}/' \
	    -e 's/(French \(version )[0-9.]+/\1${DICT-FRVERSION}/' \
	    -e 's/(German \(version )[0-9.]+/\1${DICT-DEVERSION}/' \
	    -e 's/(Spanish \(version )[0-9.]+/\1${DICT-ESVERSION}/' \
	    ${README} && \
	  ${CP} ${README} ${VOLUME}/${DISTNAME}/
	${CP} ${NEWS} ${VOLUME}/${DISTNAME}/
	ln -s /Applications ${VOLUME}/${DISTNAME}/Applications

	@echo ----- Unmounting and compressing disk image...
	hdiutil detach ${VOLUME}/${DISTNAME} -quiet
	if [ -e ${DISTNAME}.dmg ]; then rm ${DISTNAME}.dmg; fi
	hdiutil convert ${TMPDMG} \
		-format UDZO \
		-imagekey zlib-level=9 \
		-o ${DISTNAME}.dmg -quiet
	${RM} -f ${TMPDIR} ${TMPDMG}
	@echo ----- Done building the disk image

.PHONY: notarize
notarize:
	@echo ----- Notarizing the application...
	xcrun altool --notarize-app --primary-bundle-id "notarization" \
	             --username ${AC_USERNAME} \
	             --password "@keychain:${AC_PASSWORD}" \
	             --file ${DISTNAME}.dmg
	@echo ----- Done notarizing the application...

.PHONY: staple
staple:
	@echo ----- Stapling ticket to the application...
	xcrun stapler staple ${DISTNAME}.dmg
	@echo ----- Done notarizing the application...

.PHONY: check-status
check-status:
	@{ \
	    printf "%s" "----- Checking status of working directory... "; \
	    branch=$$(git branch --list | grep ^* | cut -d " " -f 2-); \
	    if [ "$${branch}" != "master"  ] && [ "$${branch}" != "main" ]; \
	    then \
	        printf "\n%s\n" "not on branch master or main"; exit 2; \
	    fi; \
	    if [ -n "$$(git status --porcelain | grep -v '^??')" ]; \
	    then \
	        printf "\n%s\n" "uncommitted changes in repository; not creating release"; exit 2; \
	    fi; \
	    if [ -n "$$(git log origin/master..HEAD | head -n1)" ]; \
	    then \
	        printf "\n%s\n" "unpushed commits in repository; pushing to origin"; \
	        git push; \
	    else \
	        printf "%s\n" "ok"; \
	    fi; \
	}

.PHONY: create-release
create-release:
	@{ \
	    printf "%s" "----- Checking if a release already exists... "; \
	    http_code=$$(curl -I ${APIURL}/releases/${TAGNAME} 2>/dev/null \
	                     | head -n1 | cut -d " " -f2) ; \
	    if [ "$${http_code}" = "200" ]; \
	    then \
	        printf "%s\n" "yes"; \
	        printf "%s\n" "using the existing release"; \
	    else \
	        printf "%s\n" "no"; \
	        printf "%s" "Creating release on GitLab... "; \
	        name=$$(awk '/^# / { sub(/# +/, "", $$0); print $$0; exit }' ${NEWS}); \
	        desc=$$(awk ' \
	                      /^$$/ { next } \
	                      (state == 0) && /^# / { state = 1; next } \
	                      (state == 1) && /^# / { exit } \
	                      (state == 1) { print } \
	                    ' ${NEWS}); \
	        curl --request POST \
	             --header "PRIVATE-TOKEN: ${OAUTHTOKEN}" \
	             --output /dev/null --silent \
	             "${APIURL}/repository/tags?tag_name=${TAGNAME}&ref=master" && \
	        curl --request POST \
	             --header "PRIVATE-TOKEN: ${OAUTHTOKEN}" \
	             --data tag_name="${TAGNAME}" \
	             --data name="$${name}" \
	             --data description="$${desc}" \
	             --output /dev/null --silent \
	             ${APIURL}/releases; \
	        printf "%s\n" "done"; \
	    fi; \
	}

.PHONY: create-link-%
create-link-%: create-release
	@{ \
	    printf "%s" "----- Adding asset to the release... "; \
	    url=$$(curl --form "file=@${PACKAGE}.$*" \
	                --header "PRIVATE-TOKEN: ${OAUTHTOKEN}"	\
	                --silent \
	           ${APIURL}/uploads \
	           | awk -F '"' '{ print $$8 }'); \
	    curl --request POST \
	         --header "PRIVATE-TOKEN: ${OAUTHTOKEN}" \
	         --data name="${PACKAGE}.$*" \
	         --data url="${REPOSURL}$${url}" \
	         --data link_type="package" \
	         --output /dev/null --silent \
	         ${APIURL}/releases/${TAGNAME}/assets/links; \
	    printf "%s\n" "done"; \
	}

.PHONY: publish
publish:
	@echo ----- Publishing the web page...
	git checkout pages && \
	  ${MAKE} && \
	  git checkout master
	@echo ----- Done publishing

.PHONY: get-emacs
get-emacs:
	@echo ----- Fetching Emacs...
	if [ -f ${DMGFILE} ]; then ${RM} ${DMGFILE}; fi
	curl -O -L https://emacsformacosx.com/emacs-builds/${DMGFILE}

.PHONY: get-ess
get-ess:
	@echo ----- Fetching ESS...
	if [ -d ${ESS}.zip ]; then ${RM} ${ESS}.zip; fi
	curl -L -o ${ESS}.zip https://github.com/emacs-ess/ESS/archive/master.zip

.PHONY: get-auctex
get-auctex:
	@echo ----- Fetching AUCTeX...
	if [ -f ${AUCTEX}.tar.gz ]; then rm ${AUCTEX}.tar.gz; fi
	curl -O https://ftp.gnu.org/pub/gnu/auctex/${AUCTEX}.tar.gz

.PHONY: get-markdownmode
get-markdownmode:
	@echo ----- Fetching markdown-mode.el
	if [ -f markdown-mode.el ]; then ${RM} markdown-mode.el; fi
	curl -OL https://github.com/jrblevin/markdown-mode/raw/v${MARKDOWNMODEVERSION}/markdown-mode.el

.PHONY: get-execpath
get-execpath:
	@echo ----- Fetching exec-path-from-shell.el
	if [ -f exec-path-from-shell.el ]; then ${RM} exec-path-from-shell.el; fi
	curl -OL https://github.com/purcell/exec-path-from-shell/raw/${EXECPATHVERSION}/exec-path-from-shell.el

.PHONY: get-psvn
get-psvn:
	@echo ----- Fetching psvn.el
	if [ -f psvn.el ]; then ${RM} psvn.el; fi
	${SVN} cat http://svn.apache.org/repos/asf/subversion/trunk/contrib/client-side/emacs/psvn.el > psvn.el

.PHONY: get-dict
get-dict:
	@echo ----- Fetching dictionaries
	if [ -f ${DICT-EN}.zip ]; then ${RM} ${DICT-EN}.zip; fi
	curl -L -o ${DICT-EN}.zip https://extensions.libreoffice.org/assets/downloads/${DICT-EN-ID}/${DICT-EN}_lo.oxt
	if [ -f ${DICT-FR}.zip ]; then ${RM} ${DICT-FR}.zip; fi
	curl -L -o ${DICT-FR}.zip https://extensions.libreoffice.org/assets/downloads/z/${DICT-FR}.oxt
	if [ -f ${DICT-ES}.zip ]; then ${RM} ${DICT-ES}.zip; fi
	curl -L -o ${DICT-ES}.zip https://extensions.libreoffice.org/assets/downloads/z/${DICT-ES}.oxt
	if [ -f ${DICT-DE}.zip ]; then ${RM} ${DICT-DE}.zip; fi
	curl -L -o ${DICT-DE}.zip https://extensions.libreoffice.org/assets/downloads/z/${DICT-DE}.oxt

.PHONY: clean
clean:
	${RM} ${DISTNAME}.dmg
	cd ${ESS} && ${MAKE} clean
	cd ${AUCTEX} && ${MAKE} clean
