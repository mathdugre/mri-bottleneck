#!/usr/bin/python env
import os.path as op
import sys

import nibabel as nb
from nilearn.image import resample_to_img, new_img_like
from nipype.utils.filemanip import copyfile
import numpy as np



mridir = sys.argv[1]
skullstripped = sys.argv[2]

t1 = op.join(mridir, "T1.mgz")
bm_auto = op.join(mridir, "brainmask.auto.mgz")
bm = op.join(mridir, "brainmask.mgz")

if not op.exists(bm_auto):
    img = nb.load(t1)
    mask = nb.load(skullstripped)
    bmask = new_img_like(mask, np.asanyarray(mask.dataobj) > 0)
    resampled_mask = resample_to_img(bmask, img, "nearest")
    masked_image = new_img_like(
        img, np.asanyarray(img.dataobj) * resampled_mask.dataobj
    )
    masked_image.to_filename(bm_auto)

if not op.exists(bm):
    copyfile(bm_auto, bm, copy=True, use_hardlink=True)
