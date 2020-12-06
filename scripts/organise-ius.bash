#!/usr/bin/env bash

# busted IU codes = BEN, BWA, CMR, AGO, CAF, BDI, BFA

COMPLETED_FILES_LIST="completed-files"

for url in $(ag -v --no-numbers '^#' dropbox-url-list) ; do

   filename=${url:69}

   if [[ -f "${COMPLETED_FILES_LIST}" && -n $( ag "${filename}" "${COMPLETED_FILES_LIST}" ) ]] ; then
       echo "=> already processed file ${filename}"
       continue
   fi

   if [[ ! -f ${filename} ]] ; then
       echo "===== downloading ${filename} from ${url} ====="
       curl -OL "${url}"
   fi

   unzip -o "${filename}"

   files_name="${filename/res/files}"
   source_dirname="${files_name/.zip/}"

   if [[ ! -d ${source_dirname} ]] ; then
       echo "-> couldn't find dir ${source_dirname}, something's wrong"
       exit 1
   fi

   scen=${source_dirname#*_scen}
   echo "----- processing scenario ${scen} at $(date) -----"

   for iu in $(awk -F , '{print $2}'< "$source_dirname/scen${scen}IUscountry.csv" | sed 's/"//g' | grep -vw x) ; do

       country=${iu:0:3}
       found_code=${iu:3}
       padded_code=$( printf %05.0f "${found_code}" )
       padded_iu=${country}${padded_code}

       iu_data_dir=data/${country}/${padded_iu}
       mkdir -p "${iu_data_dir}"

       iu_files=$( ls "${source_dirname}/*${iu}*.csv" "${source_dirname}/*${iu}*.p" | tr '\n' ' ' )

       for file in ${iu_files} ; do
           renamed_file=$( echo "$file" | sed -e "s/${found_code}/${padded_code}/g" -e "s/${source_dirname}/data\/${country}\/${padded_iu}/g" )
           cmd="cp $file $renamed_file"
           echo "${cmd}"
           eval "${cmd}"
       done

   done

   echo "-> removing file ${filename}"
   rm -f "${filename}"

   echo "-> removing dir ${source_dirname}"
   rm -rf "${source_dirname}"

   echo "${filename}" >> ${COMPLETED_FILES_LIST}

   echo "----- rsync-ing scenario ${scen} -----"
   gsutil -m rsync -r ./data gs://ntd-disease-simulator-data/diseases/sth-roundworm/source-data

   echo "----- rm-ing data folders -----"
   rm -rf data

   echo
   echo

done
