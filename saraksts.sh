#!/bin/bash
cd /var/www/html/jsgym
mv "new.md5" "old.md5"
mv "md5sum_pic.new" "md5sum_pic.old"
/usr/bin/curl -s http://gym.ventspils.lv/gym1/index.php?id=izmaias-stundu-sarakst | md5sum | awk '{ print $1 }' > "new.md5"
NEW=`cat new.md5`
OLD=`cat old.md5`
ANTIFP=`/usr/bin/curl -s http://gym.ventspils.lv/gym1/index.php?id=izmaias-stundu-sarakst | md5sum | awk '{ print $1 }' > "new.md5"`
HOUR=`(date +"%H:%M")`
HOURSEC=`(date +"%H:%M:%S")`
MINSIZE=25
#DAY=`(date +"%d.%m.%Y")`
FROMCPN='saraksts.png'
TOCPN=/var/www/html/jsgym/saraksti/trim/$(date +"%y-%m-%d_%H:%M:%S")_saraksts.png
FROMCPUNTRIM='saraksts_untrimmed.png'
TOCPUNTRIMSM=/var/www/html/jsgym/saraksti/untrim/$(date +"%y-%m-%d_%H:%M:%S")_saraksts_too_small.png
TOCPUNTRIM=/var/www/html/jsgym/saraksti/untrim/$(date +"%y-%m-%d_%H:%M:%S")_saraksts.png

if [ "$OLD" == "$NEW" ]; then
	sleep 1;
else 
	if [ "$(/usr/bin/curl -s http://gym.ventspils.lv/gym1/index.php?id=izmaias-stundu-sarakst | md5sum | awk '{ print $1 }')" == "$OLD" ]; then
		sleep 1;
		/usr/bin/mutt -s "FP Found" -a /var/www/html/jsgym/saraksts.png "email@email.com" < /var/www/html/jsgym/txt.letter;	
	else
		/var/www/html/jsgym/phantomjs /var/www/html/jsgym/screen.js "http://gym.ventspils.lv/gym1/index.php?id=izmaias-stundu-sarakst" /var/www/html/jsgym/saraksts_untrimmed.png;
		sleep 3;
		FILESIZE_UNTRIM=`(du "/var/www/html/jsgym/saraksts_untrimmed.png"| grep -Eo '[0-9]{1,4}')`
	
		if (("$FILESIZE_UNTRIM" < "$MINSIZE")); then
			printf "Untrimmed too small \t $FILESIZE_UNTRIM" > /var/www/html/jsgym/txt.letter;
			/usr/bin/mutt -s "Stundu saraksta fails par mazu!" -a /var/www/html/jsgym/saraksts_untrimmed.png "email@email.com" < /var/www/html/jsgym/txt.letter;
			cp "$FROMCPUNTRIM" "$TOCPUNTRIMSM";
			sleep 10;	
		else
			#Nogirezam baltas malas
			convert saraksts_untrimmed.png -strip -fuzz 20% -trim +repage saraksts_chop.png;		
			#Nogriezam lapas footeri
			mogrify -chop 0x110+0+0 -gravity South saraksts_chop.png
			#Nogriezam atkal baltas malas
			convert saraksts_chop.png -strip -fuzz 20% -trim +repage saraksts_prespl1.png
			#Pieliekam nelielu baltu malinu.
			convert saraksts_prespl1.png -gravity South -splice 0x15 saraksts.png
			#TO DO
			#convert saraksts_prespl2.png -gravity West -splice 15x0 saraksts.png
			
			md5sum saraksts.png > "md5sum_pic.new";
			if [ "$(cat md5sum_pic.new | awk '{ print $1 }')" == "$(cat md5sum_pic.old | awk '{ print $1 }')" ]; then
				sleep 1;
				rm -f md5sum_pic.old;
			else 
				echo "Stundu saraksts tulit tiks atjaunots $HOURSEC" > /var/www/html/jsgym/txt.letter;
				FILESIZE_TRIM=`(du "/var/www/html/jsgym/saraksts.png" | grep -Eo '[0-9]{1,4}')`
				printf "Trim completed \n Trimmed $FILESIZE_TRIM \n Untrimmed $FILESIZE_UNTRIM" >> /var/www/html/jsgym/txt.letter;
				/usr/bin/mutt -s "Stundu saraksts" -a /var/www/html/jsgym/saraksts.png "email@email.com" < /var/www/html/jsgym/txt.letter;
				cp "$FROMCPN" "$TOCPN";
				cp "$FROMCPUNTRIM" "$TOCPUNTRIM";
				#sleep 10;
				#Codebird twitu posteris. Var izmantot arī citu.
				/usr/bin/php /var/www/html/jsgym/codebird/post_izmainas_img.php;
				#/usr/bin/mutt -s "Stundu saraksts ir ticis atjaunots plkst. $HOUR" -a /var/www/html/jsgym/saraksts.png "gym_izmainas.9845@twitpic.com" < /var/www/html/jsgym/timestamp.letter;
				rm -f md5sum_pic.old	
			fi
		fi
	fi
fi
rm -f old.md5
rm -f saraksts.png
rm -f saraksts_untrimmed.png
rm -f saraksts_chop.png
rm -f saraksts_prespl.png