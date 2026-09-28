# ---
# jupyter:
#   jupytext:
#     text_representation:
#       extension: .py
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.19.5
#   kernelspec:
#     display_name: Python 3 (ipykernel)
#     language: python
#     name: python3
# ---

# %% [markdown]
# ---
# Human Eval at Terra.X
# ---
# Running in jupyter notebook

# %% deletable=true editable=true slideshow={"slide_type": ""}
# from: upyter lab /raidmeduser/OngoingResearch/7TDATA/TerraX  --ip 0.0.0.0    --port 8888
# acess: http://10.48.88.67:8888/lab?
# export with: jupyter nbconvert HumanEvalTerraX.ipynb --TemplateExporter.exclude_input=True --to pdf
import os, sys
import nibabel as nib
import numpy as np
from glob import glob
from ipyniivue import NiiVue
import ipywidgets as widgets
from IPython.display import display
from ipyniivue import MultiplanarType, NiiVue, SliceType
import subprocess
from io import StringIO
from pathlib import Path
from matplotlib import pyplot as plt
from matplotlib.patches import Rectangle
import nilearn.plotting as nplt
import re    
import polars as pl
import plotnine as p9
from plotnine import ggplot, aes, geom_point, labs, facet_grid, geom_line


grasp_dir = '/raidmeduser/OngoingResearch/7TDATA/deriv'
fmri_dir = "/raidmeduser/OngoingResearch/7TDATA/TerraX/20260908HumanEval_fMRI_SPA_EyeTrack"
spa_dir = Path('/raidmeduser/OngoingResearch/7TDATA/TerraX/20260908HumanEval_fMRI_SPA_EyeTrack')

#mni='/home/hrfmri/.cache/templateflow/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_desc-brain_T1w.nii.gz'
mni='/home/hrfmri/.cache/templateflow/tpl-MNI152NLin2009cAsym/tpl-MNI152NLin2009cAsym_res-01_T1w.nii.gz'
# # !ls $fmri_dir

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# # tSNR 
# using `tsnr` script from `lncdtools`. tSNR after minimal processing by fmriprep.
#
# tSNR fmriprep output 3D images only exist where freesurfer was able to finish.

# %% deletable=true editable=true slideshow={"slide_type": ""}
tsnr_vols = glob(os.path.join(grasp_dir, "tsnr/sub*/ses*/*_space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz"))
[os.path.basename(x) for x in tsnr_vols]

# %% [markdown]
# We can compare "fast" TR with high resolution. Noticably better tSNR with faster TR.

# %% deletable=true editable=true slideshow={"slide_type": ""}

nv = NiiVue(is_colorbar=True, height=600,width=100)
nv2 = NiiVue(is_colorbar=True, height=600,width=100)
nv.broadcast_to([nv2]); nv2.broadcast_to([nv]);
nv.set_slice_mm = True
nv.scene.crosshair_pos = (0.65,0.49,0.53)
# volume = ipyniivue.Volume(name="outline.nii", data=dog.dog_ram(fnm_warped), colormap="actc")
nv.load_volumes([{'path': mni, 'colorbar_visible': False},
                 {"path": tsnr_vols[3], "colormap": "hot", "opacity": 0.75}])
nv2.load_volumes([{'path': mni, 'colorbar_visible': False},
                  {"path": tsnr_vols[4], "colormap": "hot", "opacity": 0.75}])
nv.volumes[1].cal_max = 80
nv2.volumes[1].cal_max = 80
nv_title = widgets.HTML(value=os.path.basename(tsnr_vols[3]))
nv2_title = widgets.HTML(value=os.path.basename(tsnr_vols[4]));
xyz_lab1 = widgets.HTML(value="&nbsp;x y z 1")
xyz_lab2 = widgets.HTML(value="&nbsp;x y z 2")

@nv.on_location_change
def handle_location1(data): handle_location(data, xyz_lab1)
@nv2.on_location_change
def handle_location1(data): handle_location(data, xyz_lab2)
def handle_location(data,xyz_lab):
    """Handle location string."""
    xyz_lab.value = "update fail"
    frac = ",".join(["%0.2f"%x for x in data.get('frac',[])])
    val = "%.2f"%data.get('values')[1]['value'] # overlay value (second volume)
    mni_coord = ", ".join(["% 3.0f"%float(x) 
                           for x in data.get('mm',[])])
    xyz_lab.value = f"{mni_coord} ({frac}) {val}"
    #xyz_lab.value = f"{data}"

#viewers = widgets.GridspecLayout(2, 1,height="600px")
#viewers[0, 0] = nv
#viewers[1, 0] = nv2
display(widgets.HBox([widgets.VBox([xyz_lab1,nv_title,nv]),widgets.VBox([xyz_lab2,nv2_title, nv2])]))


# %%
## Available gradients
# @hidden_cell ipython
# nv.colormaps()
print(f"pos: {nv.frac2mm(nv_sw.scene.crosshair_pos)}\n" \
      f"frac: {nv_sw.scene.crosshair_pos}\n"
      f"scene: {nv.scene.pan2d_xyzmm}")

# %%
# # !uv pip install rpy2
# #!guix install r
# # %load_ext rpy2.ipython # fail
# #!ldd /usr/lib/R/lib/libR.so
# #! R --version
# # ! guix install R
# #! which R

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# ## Brain average
# Average tSNR within brain extracted mask (native space) for raw and motion + slicetime corrected.
#
# Note: have depike and "full" preprocessing but wavelet despiking is more aggressive then expected (why terrax is flat after despike needs to be instpected still)

# %%
import seaborn as sns
import altair as alt


tsnr_raw = pl.read_csv("~/src/HumanEval/deriv/tsnr/means.tsv",
                   separator="\t", has_header=False,
                   new_columns=['sub','file','max','mean','maskmean','nvox','X1','X2'])
proc_labels = {
    "": "raw", "_": "raw",
    "ktm": "mot",     "km_": "mot",
    "dktm": "despike",    "dkm_": "despike",
    "wdktm": "warp",    "wdkm_": "warp",
    "nfswdktm": "full",  "nfswdkm_": "full",
}
tsnr = tsnr_raw.with_columns(
    pl.col("nvox").str.replace(r"[^0-9]", "").cast(int).alias("nvox"),
    pl.col("file").str.replace(r"(_\d)?.nii.gz", "").alias("file")).\
  with_columns(
    pl.when(pl.col.file.str.contains("highres")).then(pl.lit('1.5m@2s')).otherwise(pl.lit('2mm@1.3s')).alias("type"),
    pl.col("file").str.extract(r"-(\d+)", 1).cast(int).alias("run").fill_null(1),
    pl.col("file").str.extract(r"(rest|grasp)", 1).alias("task"),
    pl.col("file").str.replace(r"_.*", "").alias("proc"),
).with_columns(
      pl.concat_str(["task", "type", "run",]).alias("linegroup"),
      pl.col.proc.replace(proc_labels).alias("proc").alias("proclab"),
  )

# %% deletable=true editable=true slideshow={"slide_type": ""}

(ggplot(tsnr.filter(pl.col.proc.str.contains(r"^$|^k"))) +
    aes(x="proc", y="maskmean")  +
    #p9.scale_y_log10() +
    geom_line(aes(group="linegroup"),color='black',alpha=.6)+
    geom_point(aes(color="task", shape="type")) +
    facet_grid(".~sub") +
    p9.scale_x_discrete(labels=["raw","mot&slc"]) +
    p9.theme_bw() +
    labs(title='tSNR Terra.X Human Eval fMRI', 
         y="average tSNR in brain mask",
         x="Processing", shape="Acq Param", color="Task"))


# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# ## vs BST3
#
# Luna 7TPlus old "BrainMechR01" project tSNR from `rhea:/Volumes/Hera/Projects/7TBrainMech/scripts/mri/013_20260825_tsnr.R`

# %%
lunaBMR01 = pl.read_csv("/raidmeduser/OngoingResearch/7TDATA/deriv/tsnr/BrainMechR01.csv")
tsnr_cmb = pl.concat([tsnr.select(["maskmean","proc"],dfrom=pl.lit("TerraX")),
                      lunaBMR01.select(maskmean="brainmean",
                                       proc="preproc",
                                       dfrom=pl.lit("BST3"))]).\
    with_columns(pl.col.proc.replace(proc_labels)).\
    filter(pl.col.maskmean>0)

# %% deletable=true editable=true slideshow={"slide_type": ""}
(ggplot(tsnr_cmb.filter(pl.col.proc.str.contains("raw|mot"))) +
        aes(x="proc",y="maskmean", fill="dfrom") +
        p9.geom_violin() +
        p9.theme_bw() +
        p9.scale_x_discrete(limits=["raw","mot"]) +
        labs(fill="Dataset", x="Processing", y="Average tSNR in brain mask", title="tSNR across scanners")
)

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# ## TODO: vs Prisma

# %% [markdown]
# # Rest
# Correlation of a network seed and ROI correlation matrix 
#

# %%

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# # Grasp
# The first 4 evaulation participants did a grasp task with 15 TRs of "on" full right hand grasping and 15 TRs of a rest block. The first two participants did not have a dispaly screen. All participants heard a voice say "grasp" every TR during the on block.
#
# The last two (?) participants also saw a TR counter during the on block.

# %%
# # !uv pip install 'nilearn[plotting]'
# # !uv pip install nbconvert

# %%

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# ## Motor mask
# Mask created from `ttest` after GLM (`3dDeconvolve`) with motor block. Threshold at `p=.01`
#

# %%
motor_mask= '/raidmeduser/OngoingResearch/7TDATA/deriv/glm/3ddeconvolve-mh-1.0/mask_motor_ttest_p01.nii.gz'
eval1mask = '/raidmeduser/OngoingResearch/7TDATA/deriv/glm/3ddeconvolve-mh-1.0/Eval1GraspFast1_amublock_motorclustermask_space-func.nii.gz'
!3dNotes $motor_mask | perl -lne 'print if s/\[.*?\]|.*ubuntu_24_64.//gp'
# !echo
!3dNotes $eval1mask |& sed -n 's/.*\]//p' # export AFNI_NO_OBLIQUE_WARNING=NO

# %% deletable=true editable=true slideshow={"slide_type": ""}
from nilearn import plotting
plotting.plot_glass_brain(motor_mask,vmin=3,vmax=5, colorbar=False, title="Group Motor Mask")


# %%
def quicktsavg(mask,ts4d):
    data = subprocess.run(["3dmaskave", "-q", "-mask", mask, ts4d], capture_output=True, text=True)
    return np.array([float(x) for x in data.stdout.split("\n") if x])

def rect(events):
    ax = plt.gca() 
    btm,top = ax.get_ylim()
    for onset, duration in events:
        r = Rectangle((onset, btm), duration, top, # bl corner, w, h
            facecolor="red", edgecolor="none", alpha=0.5)
        ax.add_patch(r)
        
def readoneD(afni1d):
    """ read file like "onset:duration onset:duraiton ..." """
    with open(afni1d, 'r') as fh:
        onsets = [[float(y) for y in x.split(':')] for x in fh.read().split(' ') if x]
    return onsets
    

TR=1.3
decon_dir = Path(os.path.dirname(eval1mask))
subeval1_onsets = decon_dir / 'sub-Eval1_ses-20260707_task-grasp_acq-fast_run-1_grasp.1D'
tse1_4d = Path(grasp_dir) / 'hmproc/1.0/sub-Eval1/ses-20260707/sub-Eval1_ses-20260707_task-grasp_acq-fast_run-1_bold/ktm_grasp-1.nii.gz'

tse1_avg = quicktsavg(eval1mask, tse1_4d)
events = readoneD(subeval1_onsets)

# %% [markdown]
# Plotting motion and slice time corrected signal intensity within the group grasp mask (inverse warped into functional acquistion).

# %% deletable=true editable=true slideshow={"slide_type": ""}
fig=plt.figure(figsize=(12,3))
plt.plot(np.arange(tse1_avg.shape[0])*TR, tse1_avg)
rect(events)
plt.title("Grasp Task Signal change in Motor Cortex")
plt.xlabel("Time (s)"); plt.ylabel("Intensity (AU)")

# TODO: % signal change
# https://matplotlib.org/stable/gallery/subplots_axes_and_figures/secondary_axis.html
#secax = ax.secondary_xaxis('right', functions=(deg2rad, rad2deg))

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# ### TODO: % signal subplots for all 

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# ## GLM
# voxelwise t-stat for `BLOCK` fit. In addition to strong (t-stat up to 15!) motor response, we also see auditory. Because first particiapnts were run without the BOLDScreen, the task includes repeated sound: "grasp" repeated each TR for the "on" non-rest block. 

# %%
subeval1_glm = decon_dir / 'sub-Eval1_ses-20260707_task-grasp_acq-highres_run-1_amublock.nii.gz'
print("# 3dDeconvolve command")
!3dNotes $subeval1_glm | sed -n 's/.*3dD/3dD/p'|sed 's/ -/\n  -/g'
print("# volume labels - want Tstat and Coef\n")
!3dinfo -label $subeval1_glm | tr '|' '\n' | cat -n
print("# p<.001 t-stat value calucated from model metadata")
# !p2dsetstat -inset $subeval1_glm"[3]" -pval 0.001 -bisided

# %% deletable=true editable=true slideshow={"slide_type": ""}
import ipyniivue
nv_glm = NiiVue(is_colorbar=True, height=600,width=100)
nv_glm.load_volumes([{'path': mni, 'colorbar_visible': False},
                 ipyniivue.Volume(name="se1_tstat.nii", data=glm_se1.slicer[...,3].to_bytes(),
                                  colormap="hot", opacity=0.75)])
xyz_glm = widgets.HTML(value="x y z glm")
@nv_glm.on_location_change
def handle_location_glm(data): handle_location(data, xyz_glm)
display(widgets.VBox([xyz_glm,nv_glm]))

# %% deletable=true editable=true slideshow={"slide_type": ""}
nv_glm.volumes[1].cal_max = 16
nv_glm.volumes[1].cal_min = 3.3
#nv_glm.save_scene('nv_glm.png') # saves in browser client (download) , not server

# %% deletable=true editable=true slideshow={"slide_type": ""}
glm_se1 = nib.load(subeval1_glm)
plotting.plot_stat_map(glm_se1.slicer[...,3],
                       cut_coords=(-42, -18, 60),
                       vmin=3.3,vmax=15, colorbar=True, draw_cross=False, cmap="hot",
                      title="Grasp block GLM t-stat (p<0.001)")

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# ## TODO: Test Re-test
# show GLM for early and late blocks?

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# # Switch Task
# Single participant on repurposed Luna "SPA" grant switch task.
#
#
# ![task instructions](https://raw.githubusercontent.com/LabNeuroCogDevel/MMY4/refs/heads/master/img/instruct_cog_inf_only.png)

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# ## Buttons
# The task requires 3 distinct button pushes. Each finger (index, middle, ring) can be modeled indvidually.

# %% deletable=true editable=true slideshow={"slide_type": ""}
#switchbtn_glm = spa_dir / 'proc/glm/decon_switch_btn-rt_sep-123.nii.gz'
switchbtn_glm = spa_dir / 'proc/glm/decon_switch_btn_button_123_NOT-RT_DONTUSE.nii.gz'
print("# 3dDeconvolve command")
!3dNotes $switchbtn_glm | sed -n 's/.*3dD/3dD/p'|sed 's/ -/\n  -/g'
print("# volume labels - want Tstat and Coef\n")
!3dinfo -label $switchbtn_glm | tr '|' '\n' | cat -n
# large degree freedom, all near 3.3 
#print("# p<.001 t-stat value calucated from model metadata")
# #!p2dsetstat -inset $switchbtn_glm"[9]" -pval 0.001 -bisided 

# %%
sw_glm = spa_dir / 'proc/glm/decon_switch_btn_button_123_NOT-RT_DONTUSE.nii.gz'
glmsw = nib.load(switchbtn_glm)

# %% deletable=true editable=true slideshow={"slide_type": ""}
nv_sw = NiiVue(is_colorbar=True, height=600,width=100)
def sw_subvol(i,color):
    return ipyniivue.Volume(name=f"{color}.nii", 
                     data=glmsw.slicer[...,i].to_bytes(),
                     colormap=color, opacity=0.75)
nv_sw.load_volumes([{'path': mni, 'colorbar_visible': False},
                    sw_subvol(3,'red'), # NB. zero-base index. one less than label table above
                    sw_subvol(6,'green'),
                    sw_subvol(9,'blue')])
xyz_sw = widgets.HTML(value="x y z sw")
@nv_sw.on_location_change
def handle_location_glmsw(data): handle_location(data, xyz_sw)


nv_sw.set_slice_mm = True


display(widgets.VBox([xyz_sw,nv_sw]))

# %% deletable=true editable=true slideshow={"slide_type": ""}
# will change plot above
nv_sw.opts.drag_mode = ipyniivue.DragMode.PAN
# -44, -28, 57, in neurosynth has "finger" assocation with zscore=13.13
# 101,85,162 is what scene is below after zooming around
nv_sw.scene.pan2d_xyzmm = [101.5593032836914, 85.72687911987305, -162.17633056640625, 3]
for i in [1,2,3]: 
    nv_sw.volumes[i].cal_min = 5
    nv_sw.volumes[i].cal_max = 6


# %% deletable=true editable=true slideshow={"slide_type": ""}
print(f"pos: {nv_sw.frac2mm(nv_sw.scene.crosshair_pos)}\n" \
      f"scene: {nv_sw.scene.pan2d_xyzmm}")

# %% deletable=true editable=true slideshow={"slide_type": ""}
finger_coords = (-44, -28, 56)
def plot_btn(i, color, **kargs):
    return plotting.plot_stat_map(
        glmsw.slicer[...,i],
        cmap=color,
        vmin=3,vmax=7, #colorbar=False,
        draw_cross=False, transparency=.5,
        **kargs
    )
def mid(x1,x2): return (x2-x1)/2
def set_zoom(plane, ax, cut=finger_coords, zoom=3):
    x, y, z = cut
    if plane == "x":
        horz,vert = (y,z)
    elif plane == "y":
         horz,vert = (x,z)
    elif plane == "z":
        horz,vert = (x,y)
    half=mid(*ax.ax.get_xlim())
    ax.ax.set_xlim(horz - half/zoom, horz + half/zoom)
    half=mid(*ax.ax.get_ylim())
    ax.ax.set_ylim(vert - half/zoom, vert + half/zoom)

fig = plt.figure(figsize=(12, 7))
top_ax   = fig.add_axes([0.05, 0.52, 0.90, 0.40])
red_ax   = fig.add_axes([0.05, 0.05, 0.27, 0.40])
green_ax = fig.add_axes([0.36, 0.05, 0.27, 0.40])
blue_ax  = fig.add_axes([0.68, 0.05, 0.27, 0.40])
plt_swbtn = plot_btn(3, "Reds",axes=top_ax, colorbar=False, cut_coords=finger_coords, title="Button Push GLM by Button")
plt_swbtn.add_overlay(glmsw.slicer[...,6],cmap="Greens",vmin=3,vmax=5,transparency=.5)
plt_swbtn.add_overlay(glmsw.slicer[...,9],cmap="Blues",vmin=3,vmax=5,transparency=.5)

x_cut=[finger_coords[1]]
p_idv = [
    plot_btn(3, "Reds",  display_mode="y", axes=red_ax,   cut_coords=x_cut, title="Index"),
    plot_btn(6, "Greens",display_mode="y", axes=green_ax, cut_coords=x_cut, title="Middle"),
    plot_btn(9, "Blues", display_mode="y", axes=blue_ax,  cut_coords=x_cut, title="Ring")]

for ax_name, ax in plt_swbtn.axes.items():
    set_zoom(ax_name,ax)
for p in p_idv:
    set_zoom('y', list(p.axes.values())[0])

plt.show()

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""} tags=["extra"]
# ## Cognative
# The [Switch Task "nBMSI"](https://github.com/LabNeuroCogDevel/MMY4/) has two trial types, both with the pattern "cue" slide (red or green fixation cross) followed by a response slide (3 digit sequence) that expects a button push. Trial types are
#   1. "green" cross congruent responses push the finger of the number shown.
#      * '1 0 0' -> index finger
#      * '0 0 3' -> ring finger
#   2. "red" cross interference is pushing the odd one out
#      * '3 1 3' -> index finger
#      * '3 1 1' -> ring finger
#
# There are two "pure" runs where the trial type does not change and two mix blocks where the trial type can switch. Switch trials are ones that are not the same as the previous.
#
# There are 46 switch trials within 155 green and 155 red trials.
#
# We model 
#   * `red - green`
#     * (-40,-2,38) - [neruosynth](https://neurosynth.org/locations/-40_-2_38_6/) `action` @ z=5.3, `working memory` at z=4.97
#     * (-38,-60,48) - parietal. [neruosynth](https://neurosynth.org/locations/-38_-60_48_6/) `[memory] retrival` @ z=9.78
#   * `switch - noswitch`
#     * (-40,44,20) - prefrontal
#   

# %% deletable=true editable=true slideshow={"slide_type": ""}
oned_dir="/raidmeduser/OngoingResearch/7TDATA/TerraX/20260908HumanEval_fMRI_SPA_EyeTrack/scripts/txt/"
# !grep -hv '*' $oned_dir/cue-*TRUE.1D | \
#   tr ' ' '\n' | wc -l
# !grep -hv '*'  $oned_dir/cue-In*.1D | \
#   tr ' ' '\n' | wc -l
# !grep -hv '*'  $oned_dir/cue-Co*.1D | \
#   tr ' ' '\n' | wc -l

# %% deletable=true editable=true slideshow={"slide_type": ""} tags=["extra"]
swcogglm_fname = spa_dir / 'proc/glm/decon_switch_contrast-noswitch.nii.gz'
swcogglm=nib.load(swcogglm_fname)
print("# 3dDeconvolve command")
!3dNotes $swcogglm_fname | sed -n 's/.*3dD/3dD/p'|sed 's/ -/\n  -/g'
print("# volume labels - want Tstat and Coef\n")
!3dinfo -label $swcogglm_fname | tr '|' '\n' | cat -n


# %% deletable=true editable=true slideshow={"slide_type": ""}
nv_swcog = NiiVue(is_colorbar=True, height=600,width=100)
from nilearn import image
sw_infVcon_c =swcogglm.slicer[...,20]
sw_infVcon_t =swcogglm.slicer[...,21]
sw_inVcon_tmask = image.threshold_img(sw_infVcon_t, threshold=2.5, two_sided=False, cluster_threshold=40)
sw_swVnosw_cMasked = image.math_img("c*(t>0)",
                                    c=swcogglm.slicer[...,17],
                                    t=image.threshold_img(swcogglm.slicer[...,18], threshold=1.9, two_sided=False, cluster_threshold=40))


# %% deletable=true editable=true slideshow={"slide_type": ""}
def light_lines(fig):
    for ax in fig.axes:
        for line in ax.lines:
            line.set_linewidth(0.5)
            line.set_alpha(0.4)
            
from nilearn.masking import apply_mask
sw_coef_thres = image.math_img("a*b",a=sw_infVcon_c, b=image.binarize_img(sw_inVcon_tmask))
PFm = plotting.plot_stat_map(sw_coef_thres, cmap='hot',  vmax=300, draw_cross=True, cut_coords=(-38,-60,48), title="Int-Con: PFm")
PFm._cbar.ax.yaxis.set_major_formatter('{x:.0f}')
light_lines(plt.gcf())
plotting.plot_stat_map(sw_coef_thres, cmap='hot',  vmax=300, draw_cross=True, cut_coords=(-40,-2,38), title="Int-Con: Frontal Eye").\
    _cbar.ax.yaxis.set_major_formatter('{x:.0f}')
light_lines(plt.gcf())
plotting.plot_stat_map(sw_swVnosw_cMasked, cmap='hot',  vmax=300, draw_cross=True, cut_coords=(-40,44,20), title="Switch-noSwitch: Prefrontal").\
    _cbar.ax.yaxis.set_major_formatter('{x:.0f}')
light_lines(plt.gcf())

plt.show()

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# ### TODO: vs Luna
#

# %% deletable=true editable=true slideshow={"slide_type": ""}
print("TODO: compare with Luna 7TPlus example")

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""} tags=["extra"]
# ### Neurosynth lookup
# website is faster but would like to have local
#

# %% deletable=true editable=true slideshow={"slide_type": ""} tags=["extra"]
from nimare.extract import fetch_neurosynth
from nimare.decode.discrete import NeurosynthDecoder
studyset = fetch_neurosynth(
    version="7",
    source="abstract",
    vocab="terms",
)[0]
print(f"{neurosynth study id count: {len(studyset.ids)}")

# %% deletable=true editable=true slideshow={"slide_type": ""} tags=["extra"]
ids = studyset.get_studies_by_coordinate(
    [[-38, -60, 49]],
    r=10,
)

decoder = NeurosynthDecoder(correction=None)
decoder.fit(studyset)
result = decoder.transform(ids=ids)
terms = (
    result[["zReverse", "pReverse", "probReverse"]]
    .sort_values("zReverse", ascending=False)
)
terms.head(5)

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
# ### 
#

# %% [markdown] deletable=true editable=true slideshow={"slide_type": ""}
#
#

# %% [markdown]
# # Dollar Reward
# Dollar reward 
# ## TODO: Eye Tracker
# TODO: fix extractor to get trial x trial traces. (or redo fresh in python -- need to manually score anyway)
# ## TODO: Cognative
# TODO: run dot vs fix GLM
# ## TODO: Luna Prisma comparison
# example 3d image GLM side by side. Angela working on dot contrast. should reuse same GLM

# %% [markdown]
# # Freesurfer
#
# We have MP2Rage sequence with `inv-1`, `inv-2` and `uni-images`. Scanner does it's own denoising as `uni-den` and saves both a raw `ND` and computeed distortion corrected (no extra label in ouptut dicoms, called `NN` below). 
#
# Preprocesing with LayNii and/or mp2rage_scripts and SPM unicort. For SPA sequence `sub-fmri`, we did not use mp2rage_scripts.
# Also treid against freesurfer versions `7.4.1` and `8.2.0`.

# %%
segs = glob(f"{fmri_dir}/proc/fs/*/sub*/mri/aseg.mgz")
[re.sub('.*proc/|/mri.*','',x) for x in segs]


# %%
def seg_slice(a):
    x=a[a.shape[0]//2 +10, :,:]
    return np.ma.array(x,mask=x<1)
subdir=re.sub('/mri/.*','',segs[0])
labels, ctab, names = nib.freesurfer.read_annot(f"{subdir}/label/lh.aparc.annot")
labels[labels < 0] = 0
roi_color = np.vstack([[0,0,0,0],
                       np.hstack([ctab[:, :3] / 255.0,np.ones((ctab.shape[0],1))])
                      ])
import matplotlib.colors as mcolors
cmap = mcolors.ListedColormap(roi_color)    

# %%
seg_data = [{}]*6
for i, seg in enumerate(segs):
    sub = re.sub("^_","",re.search(r'(?<=sub-fmri)[^/]*', seg).group())
    ver = re.search(r'(?<=fs/)[0-9.]+', seg).group()
    seg_data[i] = {'seg': nib.load(seg).get_fdata(), 
                   'anat': nib.load(seg.replace('aseg','brain')).get_fdata(),
                   'ver': ver,
                   'sub': sub}
    plt.subplot(2,3,i+1)
    plt.imshow(seg_slice(seg_data[i]['seg']), cmap='jet')
    plt.axis('off')
    plt.title(f"{sub} {ver} ")
plt.show()

# %%
for i,seg in enumerate(seg_data):
    plt.subplot(2,3,i+1)
    plt.imshow(seg_slice(seg['anat']), cmap='bone')
    plt.axis('off')
    plt.title(f"{seg['ver']} {seg['sub']}")

# %%
plt.figure(figsize=(10,10))
def plt_fs(i, **kargs):
    x = nplt.plot_roi(segs[i], bg_img=re.sub('aseg.mgz','brain.mgz',segs[i]),
              cmap=cmap, colorbar=False, alpha=.5,
              display_mode='y', cut_coords=[-12],
              title= None,
              vmin=1, black_bg=False, **kargs)
    #for ax in plt.gcf().axes:
    #    ax.title.set_fontsize(2)
    #x.axes[-12].ax.title.set_fontsize(5)
    x.title(f"{seg_data[i]['ver']} {seg_data[0]['sub']}", size=3)
    return x

plt_fs(0, axes=( .00, 0, 1,.25))
plt_fs(1, axes=( .25, 0, 1,.25))
plt_fs(2, axes=( .50, 0, 1,.25))
plt_fs(3, axes=( .75, 0, 1,.25))

# %%
for ax in fig.axes:
    ax.title.set_fontsize(1)
fig

# %%
# #!uv pip install nilearn[surface]
#import importlib; importlib.reload(niiplt) # need restart kernel

nplt.plot_surf_roi(
    surf_mesh=f'{subdir}/surf/lh.inflated',
    roi_map=roi_mask,
    hemi="left",
    bg_map=f"{subdir}/surf/lh.sulc",
    view="lateral",
    colorbar=False,
) 

# %% [markdown]
# ## TODO: show laynii denoise vs UNI-DEN NN
# have 7 vs 8. can look at volume?

# %%

# %%

# %% [markdown]
# ## Multiverse

# %%
fs_inputs = glob('/raidmeduser/OngoingResearch/7TDATA/deriv/fs/compare/sub-*/*x*[T4y].nii.gz')
print("\n".join([f"{i+1:02d} {re.sub(r'.*compare/','',f)}" for i,f in enumerate(fs_inputs)]))

# %%
fs_res = subprocess.run(r"""perl -lne '
  $start=$_ if  $.==2; 
  $end="$2\t".($1=~m:without error:?"succes":"error") if m/recon-all -s [^ ]* (.*) at (.*)/; 
  if(eof){
    $id=(($ARGV =~ m;sub-([^/_-]*)_ses-([^/]*)/(N[^/]*);)?"$1\t$2\t$3":"NA");
    $id=~s/Lay-/LayxNone-/; 
    $id=~s:/|x|-(\d):\t$1:g;
    print($ARGV=~s;.*compare/[^/]+/|-[78].[42].[10].*;;gr,"\t$id\t$start\t$end");
    $end="";
    close ARGV
   }
    '  /raidmeduser/OngoingResearch/7TDATA/deriv/fs/compare/sub-*/N*/sub*/scripts/recon-all-status.log""", shell=True, capture_output=True, text=True)
import io
fs_runs = pl.read_csv(io.StringIO(fs_res.stdout),
            separator="\t", 
            new_columns=["inname","sub","ses","distort","uni","lay","crct","ver","start","fin","success"])

fs_runs

# %%
fs_input_df_init =pl.\
    DataFrame({'fn': fs_inputs, 
               'x': [re.sub(".*/|.nii.gz","",re.sub('Lay.nii','LayxNone.nii',x)) for x in fs_inputs]}).\
with_columns(
    pl.col("x")
    .str.split_exact("x", 3)
    .struct.rename_fields(["distort", "uni","lay","crct"])
    .alias("x"),
    pl.col("fn").str.replace_all(r".*compare/[^/]*/|.nii.gz","").alias("infile"),
    pl.col("fn").str.replace_all(r".*/sub-|ses-|/N[^/]*nii.gz","").str.split_exact("_",1)
    .struct.rename_fields(["sub","ses"]).alias('subses')
).unnest(["x","subses"])
fs_input_df_init

# %%
id_cols = ['sub','ses','distort','uni','lay','crct']
fs_joined = (
    fs_input_df_init.with_columns(pl.col.ses.cast(int))
    .join(pl.DataFrame({'ver':["7.4.1","8.2.0"]}),how='cross')
    .join(fs_runs, on=['ver',*id_cols], how='left'))

fs_input_df = (fs_joined    
    .group_by(['fn','infile',*id_cols])
    .agg(nsuccess=pl.col.success.str.contains("succes").sum(),
        finver=pl.col.ver.filter(pl.col.success.str.contains("succes")).sort().unique().str.join(","))
    .with_columns(
        scolor=pl.col.nsuccess.cast(str).replace({'0':'red','1':'orange','2':'green'}))
)

fs_input_df

# %%
#fs_rs = fs_runs.group_by(['distort','uni','lay','ver','success']).len()
ggplot(fs_runs) + aes(x="distort", fill="success") + p9.facet_grid("ver~uni+lay+crct") + p9.geom_bar() + p9.theme_bw()

# %%
(ggplot(fs_runs) + 
  aes(x="success", fill="lay") +
  p9.facet_grid("ver~uni") + p9.geom_bar(position="dodge") + p9.theme_bw() + p9.scale_fill_manual(["lightgreen","purple"]) 
)

# %%
fs_dt_fmt = "%a %b %d %H:%M:%S %Z %Y"
fs_dur = (fs_runs
    .with_columns(pl.col.start.str.to_datetime(format=fs_dt_fmt),
                     pl.col.fin.str.to_datetime(format=fs_dt_fmt))
    .with_columns(
        dur=pl.col.fin-pl.col.start,
        img_grp=pl.concat_str(["sub","distort", "uni","lay","crct"])))
fs_dur

# %%
(ggplot(fs_dur) + 
  aes(y="dur", color="success", x="ver", group="img_grp") +
   p9.geom_point() + p9.theme_bw() +
   p9.geom_line(color='black')
)

# %%
input_t1_cache = {}

fig = plt.figure(figsize=(15, 12))
# sub x 4: uni x 2; lay x 2; distort x2
# 4 x 8; uni + 2*lay + 4*distort
sublist = np.unique(fs_input_df['sub']).tolist()
# TODO: add other crct versions! (UNICORT, N4UNICORT, N4)
anat_image_sets = [
    ('IMAGE','ND','Lay', 'None'),
    ('IMAGE','NN','Lay', 'None',),
    ('DEN','NN','Lay', 'None'),
    ('DEN','NN','NoLay', 'None')]
nS=len(sublist); nI=len(anat_image_sets);
subax_y = np.linspace(0,1-1/nS,nS) # subs
imgax_x = np.linspace(0,1-1/nI,nI) # imgs

subax = {}
# generate all the axes
for i,y in enumerate(subax_y):
    for j,x in enumerate(imgax_x):
        #subax[(i,j)] = fig.add_axes([x, y, 1/nS, 1/nI]) # row of same sub
        subax[(i,j)] = fig.add_axes([y, x, 1/nS, 1/nI])  # row of same img
        subax[(i,j)].axis('off')
# place brains in the axis
for row in fs_input_df.iter_rows(named=True):
    id_tuple = (row['uni'], row['distort'], row['lay'], row['crct'])
    if not id_tuple in anat_image_sets:
        print(f"NOTE: have {id_tuple} but not setup to plot in anat_imge_sets")
        continue
    if not row['fn'] in input_t1_cache.keys():
        input_t1_cache[row['fn']] = nib.load(row['fn'])
    xi =sublist.index(row['sub'])
    #yi = (row['uni']=='DEN') + 2*(row['lay']=='NoLay') + 4*(row['distort']=='NN')
    yi = anat_image_sets.index( id_tuple)
    full_title = " ".join([row[x] for x in ['sub','uni','distort','lay','crct', 'finver']])
    print(f"{full_title}: {xi} {yi}; success color {row['scolor']}")
    
    disp = nplt.plot_anat(input_t1_cache[row['fn']], cut_coords=[10],
                          display_mode='x', title=None,
                          colorbar=False, axes=subax[(xi,yi)],
                          dim=-1)
    disp.title(full_title, size=10, color='black', bgcolor=row['scolor'])


# %% [markdown]
# ### Volume
# Do we get similiar results?

# %%
def read_fsstat(f):
    to_csv_cmd = f"sed -E 's/\\s+/,/g;s/^#.ColHeaders.//;/#/d;s/^,+//' {f}"
    proc_out = subprocess.run(to_csv_cmd, shell=True, capture_output=True, text=True)
    df = pl.read_csv(io.StringIO(proc_out.stdout))
    return df.with_columns(fname=pl.lit(f))
# files like deriv/fs//compare/sub-Eval1_ses-20260707/NNxDENxLay-7.4.1/sub-Eval1_ses-20260707/stats/wmparc.stats    
wm_stat_files = glob('/raidmeduser/OngoingResearch/7TDATA/deriv/fs/compare/sub-*/N*/sub*/stats/wmparc.stats')
fs_stats = pl.concat([read_fsstat(f) for f in wm_stat_files]).with_columns(
    caps=pl.col("fname").str.extract_groups(r"/(?<distort>NN|ND)x(?<uni>[^x]+)x(?<lay>[^-_]+)(?<crct>x[^-]*)?-(?<ver>[0-9.]+).*sub-(?<sub>[^_/-]+)_ses-(?<ses>[^_/-]+)")
).unnest("caps")


# %%
# fs_stats.group_by(['StructName']).agg(mean=pl.col.Volume_mm3.mean()).sort('mean') # high wm-lh-superiorfrontal, low wm-lh-frontalpole
fs_stats_plot = fs_stats\
    .select(['Volume_mm3','StructName','sub','ses','distort','uni','lay','ver'])\
    .with_columns(group=pl.concat_str(['sub','ses','distort','uni','lay','StructName']),
                 hemi=pl.col.StructName.str.extract('(lh|rh)'), 
                 roi=pl.col.StructName.str.replace_all('wm-|[lr]h-',''))
ggplot(fs_stats_plot.filter(pl.col.StructName.str.contains('frontalpole|superiorfrontal'))) + \
 aes(x="ver", y="Volume_mm3", color="hemi", group='group',shape='sub') + \
 geom_point(alpha=.5) + p9.facet_grid('roi ~ lay + uni', scales='free') +\
p9.geom_line() + \
p9.theme_bw()
  

# %%
fn_id_cols = ['sub','distort','uni','lay','ver']
fs_wm_zscore = fs_stats_plot.\
    with_columns(pl.selectors.numeric().map_batches(
    lambda s: (s - s.drop_nans().mean()) / s.drop_nans().std() 
).over(['StructName']).alias('zscore')) # LOOK HERE. over would be fn_id_cols for within subj zscoring
fs_wm_zscore.group_by(fn_id_cols).agg(pl.col('zscore').drop_nans().count().alias('nroi'),
                                      pl.col('zscore').mean().alias('zmean'))
ggplot(fs_wm_zscore) + \
 aes(x='uni', y='zscore',fill='sub') + \
 p9.geom_boxplot() + \
 p9.facet_grid('~ ver + lay',scales='free_x') + \
 p9.labs(x='Per struct volume zscore') + p9.theme_bw()

# %%
fs_wm_pivot = fs_wm_zscore.\
    select(pl.exclude(['Volume_mm3','group'])).\
    pivot(on=['ver','uni','lay','distort'], values=['zscore'])
fs_wm_pivot

# %%
fs_wm_corr= fs_wm_pivot.select(pl.selectors.numeric()).to_pandas().corr()
fs_wm_corr['from']=fs_wm_corr.index
fs_wm_corr

# %%
fw_wm_corr_long = pl.DataFrame(fs_wm_corr.melt(id_vars='from', value_name='r_val'))
fw_wm_corr_long
(ggplot(fw_wm_corr_long) + 
 aes(x='from',y='variable',fill='r_val')+ 
 p9.geom_tile() +
 p9.theme_bw()+ p9.theme(axis_text_x=p9.element_text(rotation=-90, hjust=1)) +
 p9.labs(title="within-struct zscore across all run\ncorrelation between FS runs", fill="Correlation",y="",x=""))

# %%

# %%

# %%

# %%
