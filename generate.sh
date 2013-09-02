#!/bin/bash
echo ''
echo -n 'Looking for files not owned by :www-data...' 
found=$(find . -not -group www-data | wc -l)
(( ${found} )) && {
  echo "${found} found."
  echo ''
  echo 'Please correct and try again.'
  echo 'Correct via: chown :www-data . -R'
  echo ''
  exit 1
}

echo 'none found. OK.'

test=$(ps -o pid= -C gollum)
[ -z ${test} ] && {
	gollum --base-path wiki ${PWD}/wiki >/dev/null 2>&1 &
	gollum=$!
}

cd wiki
find . -type f -not -path "./.git/*" -and -not -name "*.html" | while read file; do
	[ "${file}" == "./gfm.php" ] && continue
	[ "${file}" == "./.htaccess" ] && continue
	[ "${file}" == "./php_errors.log" ] && continue
	echo "Processing wiki/${file/.\//}..."
	php gfm.php ${file/.\//} > /dev/null
	html=${file/.\//}.html
	find ${html} -size 0 | grep -q ${html} && {
		echo "Could not generate ${html}."
		exit 1
	}
done
cd ..

for i in menus.js xwalk.css markdown.css; do
	php $i.php > /dev/null
done

[ ! -z ${gollum} ] && {
	kill -9 ${gollum}
}

