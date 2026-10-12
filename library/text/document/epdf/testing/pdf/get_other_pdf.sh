#!/bin/bash


if [ ! -d other ]; then
	mkdir other
fi

cd other

if [ ! -f v112-367_3_STANDARD.pdf ]; then
	echo Getting v112-367_3_STANDARD.pdf
	curl -sSL -o v112-367_3_STANDARD.pdf  https://ecma-international.org/wp-content/uploads/ECMA-367_2nd_edition_june_2006.pdf
else
	echo Reuse v112-367_3_STANDARD.pdf
fi
if [ ! -f OOSC2.pdf ]; then
	echo Getting OOSC2.pdf
	curl -sSL -o OOSC2.pdf  https://bertrandmeyer.com/wp-content/upLoads/OOSC2.pdf
else
	echo Reuse OOSC2.pdf
fi
if [ ! -f PDF32000_2008.pdf ]; then
	echo Getting PDF32000_2008.pdf
	curl -sSL -O https://github.com/clintel/PDFRenderer/blob/master/doc/32000-1-2008/PDF32000_2008.pdf
else
	echo Reuse PDF32000_2008.pdf
fi

if [ ! -f image-based-pdf-sample.pdf ]; then
	echo Getting image-based-pdf-sample.pdf
	curl -sSL -O https://nlsblog.org/wp-content/uploads/2020/06/image-based-pdf-sample.pdf
else
	echo Reuse image-based-pdf-sample.pdf
fi

if [ ! -f probable-provable.pdf ]; then
	echo Getting provable-probable.pdf
	curl -sSL -O https://se.inf.ethz.ch/~meyer/publications/cacm/probable-provable.pdf
else
	echo Reuse provable-probable.pdf
fi
if [ ! -f "Bodea Brochure - Linearized.pdf" ]; then
	echo Getting Bodea Brochure - Linearized.pdf
	curl -sSL -o  "Bodea Brochure - Linearized.pdf" "https://documentcloud.adobe.com/view-sdk-demo/PDFs/Bodea%20Brochure.pdf"
else
	echo Reuse Bodea Brochure - Linearized.pdf
fi

cd -
