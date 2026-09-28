#!/usr/bin/env bash

# create 'imagetypes' {NN,ND}x{DEN,IMAGE}x{NO,}Lay 
#  ND    - original no distortion correction.
#  NN    - scanner default with distortion correction (Not-ND)
#  IMAGE - raw inv1:inv2 contrast. not denoised
#  DEN   - scanner denoised
#  Lay   - laynii applied denoising
#  NoLay - no denoising. only approprate for DEN subset
# SKIP_QUIET=1 MKNII_QUIET=1 ./03_fs_cmp_mkinputs.bash
set -euo pipefail
cd "$(dirname $0)"
checkcnt(){ test 1 -gt "$(find -L $@  -type f,l |wc -l)" && echo "# $(tput setaf 1)ERROR:$(tput sgr0) only $_ files in $*" && return 1; return 0; }
export PATH="$PATH:/opt/ni_tools/mp2rage-den-unicort" # unicort_one
imgtypes=(NNxIMAGExLay NNxDENxLay NDxIMAGExLay NNxDENxNoLay) # also makes *xImagexLayx{N4,unicort}
for subses in bids/sub-{Phant1,Eval{1,2,3}}/ses-*; do
	for img in "${imgtypes[@]}"; do
		! [[ $subses =~ sub-([^/]*)/ses-([0-9]+) ]] && echo "no sub ses in '$subses'" && continue
		sub=${BASH_REMATCH[1]} ses=${BASH_REMATCH[2]}

		outdir=$(readlink -f $PWD/deriv)/fs/compare/sub-${sub}_ses-${ses}
		fs_input=$outdir/$img.nii.gz
		echo -e "\n## MAKE $img $sub $ses => $fs_input"


		# default from bids
		inv1=$subses/anat/*_inv-1_MP2RAGE.nii.gz
		inv2=$subses/anat/*_inv-2_MP2RAGE.nii.gz
		uni=$subses/anat/*_UNIT1noden.nii.gz
		case $img in
			NNxIMAGExLay)
				dcminv1=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_INV1_[0-9]+_MR/" dcmdb.tsv|sort -u)
				dcminv2=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_INV2_[0-9]+_MR/" dcmdb.tsv|sort -u) 
				dcmuni=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_UNI_Images_[0-9]+_MR/" dcmdb.tsv|sort -u)

				inv1=$outdir/NN-inv1.nii.gz
				inv2=$outdir/NN-inv2.nii.gz
				uni=$outdir/NN-image.nii.gz;;
			NNxDENxLay)
				dcminv1=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_INV1_[0-9]+_MR/" dcmdb.tsv|sort -u) 
				dcminv2=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_INV2_[0-9]+_MR/" dcmdb.tsv|sort -u) 
				dcmuni=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_UNI-DEN_[0-9]+_MR/" dcmdb.tsv|sort -u)

				inv1=$outdir/NN-inv1.nii.gz
				inv2=$outdir/NN-inv2.nii.gz
				uni=$outdir/NN-den.nii.gz;;
			NNxDENxNoLay)
				dcminv1=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_INV1_[0-9]+_MR/" dcmdb.tsv|sort -u) 
				dcminv2=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_INV2_[0-9]+_MR/" dcmdb.tsv|sort -u) 
				# ADDED missing 'sort -u' need to rerun just NNxDENxNoLay
				dcmuni=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_UNI-DEN_[0-9]+_MR/" dcmdb.tsv|sort -u) 
				inv1=
				inv2=
				uni=$fs_input;;
			NDxIMAGExLay)
				dcminv1=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_INV1_ND_[0-9]+_MR/" dcmdb.tsv|sort -u)  || :
				dcminv2=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_INV2_ND_[0-9]+_MR/" dcmdb.tsv|sort -u)  || :
				dcmuni=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_UNI_Images_ND_[0-9]+_MR/" dcmdb.tsv|sort -u) || : 

				inv1=$outdir/ND-inv1.nii.gz
				inv2=$outdir/ND-inv2.nii.gz
				uni=$outdir/ND-image.nii.gz;;
			NDxDENxLay)
				dcminv1=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_INV1_ND_[0-9]+_MR/" dcmdb.tsv|sort -u)  || :
				dcminv2=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_INV2_ND_[0-9]+_MR/" dcmdb.tsv|sort -u)  || :
				dcmuni=$(grep -Po "raw/${ses}[^/]*$sub/DICOM/anat-UNIT1__mp2rage_cs6.5_0.65mm_pTx_UNI-DEN_ND_[0-9]+_MR/" dcmdb.tsv|sort -u) || :

				inv1=$outdir/ND-inv1.nii.gz
				inv2=$outdir/ND-inv2.nii.gz
				uni=$outdir/ND-image.nii.gz;;
			*) echo "ERROR: unknown image type '$img'" && continue;;
		esac

		[ -z "$dcmuni" -o ! -d "$dcmuni" ] && echo "## ERROR: $img: $sub/$ses: Missing dcmuni '$dcmuni' for $subses (expected for ND on eval2&3)"  && continue



		dryrun mkdir -p $(dirname $fs_input)
		dryrun mknii $uni   $dcmuni  
		checkcnt $dcmuni || continue

		# create laynii when needed. not run for *xNoLay
		if [ -n "$inv1" -a -n "$inv2" ]; then

                   # report when we're missing dicoms
		   checkcnt $dcminv1 || continue
		   checkcnt $dcminv2 || continue

                   # make into nifti
		   dryrun mknii $inv1  $dcminv1 
		   dryrun mknii $inv2  $dcminv2 

		   # record what made these files. Make sure NN and UNI vs DEN are correct
		   skip-exist -o  ${fs_input/.nii.gz/}.3dnotes\
		   	3dNotes_each -f $inv1 $inv2 $uni 

		   dryrun skip-exist $fs_input niinote __SKIPFILE \
		   	/opt/ni_tools/LayNii/LN_MP2RAGE_DNOISE   \
		   	-INV1 $inv1  -INV2 $inv2  -UNI  $uni -output __SKIPFILE
		fi

		if [[ $img =~ IMAGExLay ]]; then
		    n4=${fs_input/.nii.gz}xN4.nii.gz
		    skip-exist $n4 \
		     niinote $n4 \
			    N4BiasFieldCorrection -d 3 -i $fs_input -o $n4

		    unicort=${fs_input/.nii.gz}xUNICORT.nii.gz
		    skip-exist $unicort unicort_one $fs_input __SKIPFILE

		    n4unicort=${fs_input/.nii.gz}xN4UNICORT.nii.gz
		    skip-exist $n4unicort unicort_one $n4 __SKIPFILE
		fi

	done
done
wait
