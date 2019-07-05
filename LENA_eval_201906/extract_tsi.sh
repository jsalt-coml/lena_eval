
#!/usr/bin/env bash
# prepared for tsi only, and folder-specific
# extract bits of lena's rttm using the gold ones

goldfolder="gold/"
goldoldfolder="gold/oldname"
lenatsifolder="lena/TSI"
lenafolder="lena/"

for j in $goldoldfolder/*.rttm  
do 
echo $j
   kid=`echo $j | sed 's/.*\///' | sed 's/_.*//'` 
   date=`echo $j | sed 's/.*M.._//' | sed 's/_.*//'` 
   start=`echo $j | sed 's/.*_//' | sed 's/.rttm//'` 

echo $kid $date $start

# we need to pull out all the lines corresponding to the 60 s of annotation

# this pulls out all lines greater than the start & smaller than start + 60

   awk -v start=$start '{ if ($4 >= start && $4 < start+60) {print $0} }' $lenatsifolder/${kid}_${date}.rttm > $lenafolder/${kid}_${date}_${start}.rttm

# add previous line 
   first_onset=`head -n 1 $lenafolder/${kid}_${date}_${start}.rttm | cut -f 4 -d " "`
   previous_line=`grep $first_onset -C 1 $lenatsifolder/${kid}_${date}.rttm | head -n 1`

   echo -e "$previous_line\n$(cat $lenafolder/${kid}_${date}_${start}.rttm)" >  $lenafolder/${kid}_${date}_${start}.rttm


# fix onset and duration of first
   first_onset=`head -n 1 $lenafolder/${kid}_${date}_${start}.rttm | cut -f 4 -d " "`
   first_dur=`head -n 1 $lenafolder/${kid}_${date}_${start}.rttm | cut -f 5 -d " "`
   real_dur=`echo "$first_onset + $first_dur - $start" | bc`
   sed "1 s/$first_onset/$start/" < $lenafolder/${kid}_${date}_${start}.rttm > temp.txt
   sed "1 s/$first_dur/$real_dur/" < temp.txt > $lenafolder/${kid}_${date}_${start}.rttm 

# fix duration of last
   last_onset=`tail -n 1 $lenafolder/${kid}_${date}_${start}.rttm | cut -f 4 -d " "`
   last_dur=`tail -n 1 $lenafolder/${kid}_${date}_${start}.rttm | cut -f 5 -d " "`
   real_dur=`echo "$start + 60 - $last_onset" | bc`
   sed "$ s/$last_dur/$real_dur/" < $lenafolder/${kid}_${date}_${start}.rttm > temp.txt 

# fix all the names
   sed "s/${kid}_${date}/${kid}_${date}_${start}/" <  temp.txt > $lenafolder/${kid}_${date}_${start}.rttm


# fix all onset times
   awk -v start=$start '{$4 = $4-start; print}' < $lenafolder/${kid}_${date}_${start}.rttm > temp.txt
   mv temp.txt $lenafolder/${kid}_${date}_${start}.rttm

# and to end, create a copy of the gold with the new name
  cp $j $goldfolder/${kid}_${date}_${start}.rttm

done