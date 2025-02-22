Copyright (C) 2008-2013 Free Software Foundation, Inc.
Copyright (C) 2009-2022 Vincent Goulet for the modifications.
See below for GNU Emacs license conditions.

Emacs Modified for macOS
========================

This is GNU Emacs 28.1 modified to include the following add-on
packages:

- ESS 18.10.3snapshot;
- AUCTeX 13.1;
- markdown-mode.el 2.5;
- exec-path-from-shell.el 1.12 to import the user's
  environment (by default PATH, MANPATH, LANG, TEXINPUTS and
  BIBINPUTS) at Emacs startup;
- dictionaries for the Hunspell spell checker (optional; see below for
  details);
- psvn.el r1573006 to work with Subversion repositories from
  within Emacs;
- default.el and site-start.el files to make everything work together.

The distribution is based on the latest stable release of GNU Emacs
compiled by David Caldwell (<https://emacsformacosx.com>).

In order to use Markdown you may need to install a parser such as
Pandoc (see <https://github.com/jgm/pandoc/releases/latest>) and
customize `markdown-command`.

You may want to customize `exec-path-from-shell-variables`.

Please direct questions or comments on this version of Emacs Modified
for macOS to Vincent Goulet <vincent.goulet@act.ulaval.ca>.

GNU Emacs Modified is free software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Spell checking and dictionaries
===============================

Spell checking inside Emacs on macOS requires an external checker. I
recommend to install Hunspell (<https://hunspell.github.io>) using
Homebrew (<https://brew.sh>).

The Hunspell installation does not include any dictionaries.
Therefore, this distributions of Emacs ships with the following Libre
Office dictionaries suitable for use with Hunspell:

- English (version 2022.07.01);
- French (version 5.7);
- German (version 2017.01.12);
- Spanish (version 2.5).

Copy the files in the `Dictionaries` directory of the disk image to
`~/Library/Spelling`. If needed, create a symbolic link named after
your LANG environment variable to the corresponding dictionary and
affix files. For example, if LANG is set to fr_CA.UTF-8, do from the
command line

  cd ~/Library/Spelling
  ln -s fr-classique.dic fr_CA.dic
  ln -s fr-classique.aff fr_CA.aff

Finally, if you have a Mac with an Apple Silicon CPU (M1 and above),
add the following lines to your ~/.emacs file:

  (setq-default ispell-program-name "/opt/homebrew/bin/hunspell")
  (setq ispell-really-hunspell t)

For an Intel CPU, use instead:

  (setq-default ispell-program-name "/usr/local/bin/hunspell")
  (setq ispell-really-hunspell t)

Spell checking should now work with `M-x ispell`.

See <https://extensions.libreoffice.org/extensions> to install
additional dictionnaries.

GNU Emacs
=========

[The following are excerpts from the file etc/NEXTSTEP in the GNU
Emacs sources.]

The Nextstep support code works on many POSIX systems (and possibly
W32) using the GNUstep libraries, and on MacOS X systems using the
Cocoa libraries.

GNU Emacs is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

GNU Emacs is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
