for file in po/*po;
do
	lang=`echo $file | sed 's/po\/\(.*\)\.po/\1/gi'`
	mkdir -p ./out/$lang
	xml2po -a -p $file cheatsheet.svg > out/$lang/cheatsheet.svg
	#create eps
	#inkscape -z -B -T -E out/$lang/testpage-letter.eps out/$lang/testpage-letter.svg
	#remove svgs
	rm ./out/$lang/*svg
done

