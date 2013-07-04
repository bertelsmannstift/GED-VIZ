# Source code and images

Unless stated otherwise, the MIT license applies to the files in this repository.

Copyright (C) 2013 The Bertelsmann Stiftung<br>
Global Economic Dynamics (GED)<br>
Carl-Bertelsmann-Str. 256<br>
33311 Gütersloh<br>
Germany<br>
http://www.bertelsmann-stiftung.de

The Bertelsmann Stiftung is an independent foundation under civil law, governed
by Sec. 1 of the Foundation Act of the state of North Rhine-Westphalia.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

# Data files

The data files in `import/*.csv` were compiled by [Prognos AG](http://www.prognos.com/)
for the Bertelsmann Foundation. You must delete these data files after download. 
The data originate from several sources:

- OECD: http://www.oecd.org/statistics/
- OECD Migration Database: http://www.oecd.org/els/mig/keystat.htm
- AMECO: http://ec.europa.eu/economy_finance/db_indicators/ameco/
- UN Comtrade: http://comtrade.un.org/
- Bank for International Settlements (BIS): http://www.bis.org/statistics/consstats.htm

# Trademarks

“Bertelsmann Stiftung” and “GED VIZ” as well as the logos are trademarks of
the Bertelsmann Stiftung. If you install this software on an Internet or
Intranet web server, you have to replace these trademarks and logo in the user
interface.

To replace the trademarks in the source code, search for the strings
“Bertelsmann Stiftung” and “GED VIZ” in `*.haml` and `*.hamlc` files.
Also replace these logos:

- `app/assets/images/stiftung-logo.svg`
- `app/assets/images/stiftung-logo.png`
- `app/assets/images/ged-logo*.svg`
- `app/assets/images/ged-logo*.png`

# Fonts

## Icon font

The icon font is using glyphs from several icons sets licensed under the
SIL Open Font License (OFL, http://scripts.sil.org/OFL). See
`app/assets/fonts/LICENSE.txt` for details.

## Camingo Dos

The online version of GED VIZ – [viz.ged-project.de](http://viz.ged-project.de) –
uses the
[Camingo Dos font family](http://www.janfromm.de/typefaces/camingodos/std/),
copyrighted by [Jan Fromm](http://www.janfromm.de/). It is not open source
and not free of charge, therefore it’s not part of this repository.

If you would like to use the original font, please
[obtain a license](http://www.janfromm.de/typefaces/camingodos/buy/)
to support the type designer.

You need to place the fonts files in `app/assets/fonts/` and enable them in
`app/assets/stylesheets/_typography.css.sass`.
