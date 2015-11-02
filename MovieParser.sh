#!/bin/bash

#create directories
mkdir -v MovieLists;
cp movie_list MovieLists;
cp genre_list MovieLists;
cd MovieLists;
while read line; do mkdir -v "$line"; done < movie_list;

#### function to check whether a string1 contains string2 as substring####
function contains() {
    string="$1"
    substring="$2"
    if test "${string#*$substring}" != "$string"
    then
        return 0    # $substring is in $string
    else
        return 1    # $substring is not in $string
    fi
}

echo "<html><head></head><style>
table, th, td {
    border: 1px solid black;
    border-collapse: collapse;
}
th, td {
    padding: 5px;
}
table tr:nth-child(even) {
    background-color: #eee;
}
table tr:nth-child(odd) {
   background-color:#fff;
}
</style><body>" > movieList.html;
echo "<table style=\"width:100%\">" >> movieList.html;
echo " <caption>Movie Informations</caption>" >> movieList.html;
echo "<tr><th>Title</th><th>Genre</th><th>Rating</th></tr>" >> movieList.html;
str=$(grep " " genre_list |awk '{print $1":"$2":"$3":"$4":";}'|tr '\n' '\0');
IFS=":";
genreList=($str);
cnt=0;
for folder in *; do
	if [[ -d  $folder ]]; then
		inputi=$folder;
		name=$(echo $inputi|awk '{
		n=split($0,a,"[ .\(\)\{\}\[\]\-\_\]\=\+\-\*\/\@\#\%\&]")
			for(i=1;i<=n;i++){
			if(a[i]!="")print a[i];
 			if(a[i]>=1800&&a[i]<=2020)i=n+1;
			}
		}'|tr '\n' '+');

		URL="www.imdb.com/find?q="$name"&s=tt&ttype=ft";

		####download the Page####
		wget --output-document=index.html  --no-parent $URL;
		
		#####Parse movie Id and load the page#####
		movieId=$(grep "/title/" index.html|awk '{print $7}');
		
		domain="www.imdb.com";
		ext=`echo ${movieId:6:32}`;
		
		URL=`echo $domain$ext`;
		wget --output-document=index2.html  --no-parent $URL;

		#######Retrieve Genre Info#######
		tmp=$(grep "itemprop=\"genre\"" index2.html|awk '{print $3}');
		genreInfo="";
		separator=false;
		for key in "${!genreList[@]}"; 
		do 
		 if contains $tmp ${genreList[$key]};
		 then
		  if $separator ; then
			genreInfo=$genreInfo`echo ","`;	
		  fi
		  genreInfo=`echo $genreInfo${genreList[$key]}`;
		  separator=true;
		 fi
		#	echo "$key ${genreList[$key]}"; 
		done
		
		####Retrieve Movie Rating####
		tmpRating=$(grep "<strong><span itemprop=\"ratingValue\">" index2.html|awk '{print $2 }');
		rating=`echo ${tmpRating:23:3}`;
		echo "<tr>" >> movieList.html;
		echo "<td>" >> movieList.html;
		echo "<span><a href=\"MovieLists/$folder\">$folder</a></span><br/>" >> movieList.html;
		echo "</td><td>" >> movieList.html;
		echo "<span>$genreInfo</span><br/>" >> movieList.html;
		echo "</td><td>" >> movieList.html;
		echo "<span>$rating</span><br/>" >> movieList.html;
		echo "</td></tr>" >> movieList.html;	
			
		#fifty=50;
		#cnt=`expr $cnt + 1`;
		#if [ $cnt == $fifty ]; then 
		#	break;
		#fi
	
fi
done 

echo "</table></body></html>" >> movieList.html;
####remove resulting files####
mv movieList.html ..
rm movie_list;
rm genre_list;
rm index.html;
rm index2.html;

#back to the original directory
cd ..

