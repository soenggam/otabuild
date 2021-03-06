#!/bin/bash

function clean_and_quit()
{
  echo -e "\e[32m clean input, output, and then quit \e[0m"
  if [ -d $otabuild ]; then rm -vr $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME; fi
  if [ -d $otabuild ]; then rm -vr $otabuild/input/$SIGNTYPE/$PROJECT_NAME/$TIME; fi
  exit
}

# detect if installed dos2unix and enca was installed, laterly we will use dos2unix to convert line break, use enca to convert file encoding.
type dos2unix >/dev/null 2>&1 || { echo -e >&2 "\e[31m we need dos2unix to convert dos style line break,using sudo apt-get install dos2unix to install it. Aborting. \e[0m"; exit 1; }
type enca >/dev/null 2>&1 || { echo -e >&2 "\e[31m we need enca to convert ota_param_file's encoding,using sudo apt-get install enca to install it. Aborting. \e[0m"; exit 1; }

TIME=`date +%y%m%d_%H%M%S`
STEP=0
printf "%s\n" "$BUILD_TAG--step$((STEP++))--Compile Start"

otabuild=$ANDROID/../otabuild
source $otabuild/tools/init.sh

# 'fullpkg','forward','backward' are used to debug for inside use, aiming to generate full-package, forward diff-package and backward diff-package respectively.
if [ $ota_style = "all" ] || [ $ota_style = "full" ] || [ $ota_style = "fullpkg" ]; then
  printf "\e[32m =====================full-package building start================== \e[0m\n"
  source $otabuild/tools/makeota.sh full
fi
if [ $ota_style = "all" ] || [ $ota_style = "full" ] || [ $ota_style = "forward" ]; then
  printf "\e[32m =====================forward diff-package building start================== \e[0m\n"
  source $otabuild/tools/makeota.sh up
  mv -v $ota_param_file $outputdir/$packfolder
  python $otabuild/tools/makeupc.py $diffpack_signed $PROJECT_NAME "$description" $priority $hw_version $old_ver $new_ver
fi

if [ $ota_style = "all" ] || [ $ota_style = "diff" ] || [ $ota_style = "backward" ]; then
  printf "\e[32m ======================backward diff-package building start================= \e[0m\n"
  # we need to swap old and new target-files for backward diff-package.
  tmpdir=$target_old_dir;target_old_dir=$target_new_dir;target_new_dir=$tmpdir
  tmpfile=$target_old_file;target_old_file=$target_new_file;target_new_file=$tmpfile
  tmpver=$old_ver;old_ver=$new_ver;new_ver=$tmpver
  source $otabuild/tools/makeota.sh down
  python $otabuild/tools/makeupc.py $diffpack_signed $PROJECT_NAME "$description" $priority $hw_version $old_ver $new_ver
fi

if [ "$window_out_path_one" != "" ]; then
  cp -rvf $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME/* $window_out_path_one
  if [ $check_integrity = "true" ]; then
    # REMEMBER WE HAD SWAPED 'OLD_VER' AND 'NEW_VER' !
    test_integrity $window_out_path_one/OTA_V${old_ver}_V${new_ver}_${TIME}_${OTA_TYPE}_F/ota_diff_${old_ver}_${new_ver}_${hw_version}_${OTA_TYPE}_signed.zip
    test_integrity $window_out_path_one/OTA_V${new_ver}_V${old_ver}_${TIME}_${OTA_TYPE}/ota_diff_${new_ver}_${old_ver}_${hw_version}_${OTA_TYPE}_signed.zip
    test_integrity $window_out_path_one/OTA_V${new_ver}_V${old_ver}_${TIME}_${OTA_TYPE}/ota_full_${old_ver}_${hw_version}_${OTA_TYPE}_signed.zip
  fi
fi
if [ "$window_out_path_two" != "" ]; then
  if [ $autosync == "true" ]; then
    echo -e "\e[32m all of ota packgages had copied to 20 server, we can get them from 20, now begin copy to 17 server \e[0m"
    cp -rvf $otabuild/output/$SIGNTYPE/$PROJECT_NAME/$TIME/* $window_out_path_two
  elif [ $autosync == "false" ]; then
    echo -e "\e[32m you had selected don't sync building result to $window_out_path_two, you should copy them manually. \e[0m"
  fi
fi
clean_and_quit



