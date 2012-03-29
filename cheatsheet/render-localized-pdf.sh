for file in po/*po;
do
	lang=`echo $file | sed 's/po\/\(.*\)\.po/\1/gi'`
	mkdir -p ./out/$lang
	xml2po -a -p $file gettingstarted.svg > out/$lang/gettingstarted.svg
	xml2po -a -p $file cheatsheet-01.svg > out/$lang/cheatsheet-01.svg
	xml2po -a -p $file cheatsheet-02.svg > out/$lang/cheatsheet-02.svg
	xml2po -a -p $file cheatsheet-03.svg > out/$lang/cheatsheet-03.svg
	#create eps
	#inkscape -z -B -T -E out/$lang/testpage-letter.eps out/$lang/testpage-letter.svg
	#remove svgs
	rm ./out/$lang/*svg
done

