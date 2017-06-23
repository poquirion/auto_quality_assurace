%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% This program is to test the possibility of using a 3-D Fourier transform
% on structural imaging data to perform quality assessments. It evaluates
% the noise from outside the brain and
% builds a distribution from the brain surface away
% from the skull. It also will perform a Fourier analysis of that as it
% appears to have wave like structure present.

%   Author:     Tonya White, MD, PhD
%   Date:       21 juli 2015
%   Location:   Rotterdam, Netherlands

%   NOTE:   IMPORTANT NOTE, YOU MUST START MATLAB FROM THE FOLLOWING
%   DIRECTORY: /Volumes/rbraid/mr_data/tonya/scripts_quality_assurance_at_9

%   Modified:   

%   Functions Called ____________________________________________________
%      
%       _________________________________________________________________

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
close all
clc

% ------------------------------------------------------------------------
% SET THE VARIABLES THAT WILL BE USED IN THE PROGRAM

% ________________________________________________________________________
% THIS SECTION HAS USER DEFINED VARIABLES OR PATHS. ONLY CHANGE ITEMS
% WITHIN THE BARS BELOW.

% Set the path where all the Matlab imaging commands are
addpath('/Volumes/rbraid/matlab/tonya_MATLAB/') ;
addpath('/Volumes/rbraid/mr_data/projects/MATLAB/Structural_QA_Fourier/') ;
addpath('/Volumes/rbraid/mr_data/projects/MATLAB/subroutines') ;
addpath('/Volumes/rbraid/mr_data/tonya/scripts_quality_assurance_at_9') ;

% set FSL environment
setenv('FSLDIR','/usr/share/fsl/5.0/bin/fsl');  % this to tell where FSL folder is
setenv('FSLOUTPUTTYPE', 'NIFTI_GZ'); % this to tell wha
        end
    end
    
    % Find the posterior side of the brain
    pflag = 0 ;
    posterior = dimz ;
    while pflag == 0 
        cod = max(squeeze(midslice(:,posterior))) ;
        coe = max(squeeze(midedge(:,posterior))) ;
        if cod < thresh | coe < edgethresh
            posterior = posterior - 1 ;
        else
            pflag = 1 ;
        end
    end
    
    rightedge = 0 ;  % Set the counter for the edge gradient ;
    rightedge5 = 0 ;
    rightgrad = 0 ;
    leftedge = 0 ;  % Set the counter for the edge gradient ;
    leftedge5 = 0 ;
    leftgrad = 0 ;
    ri2count = 0 ;
    li2count = 0 ;
    
    for m = midbrain : secbrain
       for p = anterior : posterior
           imgline = squeeze(smri(:,m,p)) ;
           edgline = squeeze(edge(:,m,p)) ;
           % Approach the curve from the lower end to calculate the noise
           pflag = 0 ;
           right = 1 ;
           while pflag == 0
               if imgline(right,1) < thresh | edgline < edgethresh
                   right = right + 1 ;
               else
                   pflag = 1 ;
                   orflag = 0 ;
                   if right - 5 > 0
                        edgepoint = squeeze(imgline(right,1)) ;
                        edgepoint5 = squeeze(imgline(right-5,1)) ;
                        edgedif = edgepoint - edgepoint5 ;
                        orflag = 1 ;
                   end
                   right = right - 1 ;
               end
               if right > dimx - ftleng
                   pflag = 2 ;
               end
           end
           if pflag < 2
                icount = 1 ;
                if p > anterior + eye
                    for j = right : -1 : 1
                        rnoise(icount) = rnoise(icount) + imgline(j) ;
                        rcnt(icount) = rcnt(icount) + 1 ;
                        icount = icount + 1 ;
                    end
                    if icount > fftleng
                        ft1 = rnoise(1:fftleng,1) ;
                        ft2 = real(fft(ft1)) .^ 2 ;
                        ftrnoise = ftrnoise + ft2 ;
                        ftrcount = ftrcount + 1 ;
                    end
                else
                    for j = right : -1 : 1
                        reye(icount) = reye(icount) + imgline(j) ;
                        rcnteye(icount) = rcnteye(icount) + 1 ;
                        icount = icount + 1 ;
                    end
                end
           end
           % Now calculate the gradient decent from the edge to five voxels
           % away
           if p > (anterior + eye) && (orflag > 0)
                rightedge = rightedge + edgepoint ;
                rightedge5 = rightedge5 + edgepoint5 ;
                rightgrad = rightgrad + edgedif ;
                ri2count = ri2count + 1 ;
           end
           
           
           % Now do it for the other side of the brain
           pflag = 0 ;
           left = dimx ;
           while pflag == 0
               if imgline(left,1) < thresh | edgline < edgethresh
                   left = left - 1 ;
               else
                   pflag = 1 ;
                   olflag = 0 ;   % Make sure that it will fit in the array
                   if left + 5 <= dimx
                        edgepoint = squeeze(imgline(left,1)) ;
                        edgepoint5 = squeeze(imgline(left+5,1)) ;
                        edgedif = edgepoint - edgepoint5 ;
                        olflag = 1 ;
                   end
                   left = left + 1 ;
               end
               if left < ftleng
                   pflag = 2 ;
               end
           end
           if pflag < 2
                icount = 1 ;
                if p > anterior + eye
                    for k = left : dimx
                        lnoise(icount) = lnoise(icount) + imgline(k) ;
                        lcnt(icount) = lcnt(icount) + 1 ;
                        icount = icount + 1 ;
                    end
                    if icount > fftleng
                        ft1 = lnoise(1:fftleng,1) ;
                        ft2 = real(fft(ft1)) .^ 2 ;
                        ftlnoise = ftlnoise + ft2 ;
                        ftlcount = ftlcount + 1 ;
                    end
                else
                    for k = left : dimx 
                        leye(icount) = leye(icount) + imgline(k) ;
                        lcnteye(icount) = lcnteye(icount) + 1 ;
                        icount = icount + 1 ;
                    end
                end
                ft1 = lnoise(1:ftleng,1) ;
           end
            % Now calculate the gradient decent from the edge to five voxels
           % away
           if p > (anterior + eye) && (olflag > 0)
                leftedge = leftedge + edgepoint ;
                leftedge5 = leftedge5 + edgepoint5 ;
                leftgrad = leftgrad + edgedif ;
                li2count = li2count + 1 ;
           end
       end
    end
    righty(i,:) = rnoise ./ rcnt ;
    lefty(i,:) = lnoise ./ lcnt ;
    rightyeye(i,:) = reye ./ rcnteye ;
    leftyeye(i,:) = leye ./ lcnteye ;
    rightyfft(i,:) = ftrnoise / ftrcount ;
    leftyfft(i,:) = ftlnoise / ftlcount ;
    rightymax = rightedge / ri2count ;
    leftymax = leftedge / li2count ;
    righty5 = rightedge5 / ri2count ;
    lefty5 = leftedge5 / li2count ;
    rightygrad = rightgrad / ri2count ;
    leftygrad = leftgrad / li2count ;
    
    % You need now to zero the right and left values for the next subject
    rnoise = zeros(dimx,1) ;
    lnoise = zeros(dimx,1) ;
    ftrnoise = zeros(fftleng,1) ;
    ftlnoise = zeros(fftleng,1) ;
    ftrcount = 0 ;
    ftlcount = 0 ;
    rcnt = zeros(dimx,1) ;
    lcnt = zeros(dimx,1) ;
    rightedge = 0 ;  % Set the counter for the edge gradient ;
    rightedge5 = 0 ;
    rightgrad = 0 ;
    leftedge = 0 ;  % Set the counter for the edge gradient ;
    leftedge5 = 0 ;
    leftgrad = 0 ;
    ri2count = 0 ;
    li2count = 0 ;
    reye = zeros(dimx,1) ;
    leye = zeros(dimx,1) ;
    rcnteye = zeros(dimx,1) ;
    lcnteye = zeros(dimx,1) ;
               
    % Integrate the area under the curve starting 10 mm away from the edge and going to 100 mm
    r1 = squeeze(righty(i,10:99)) ;
    rarea = sum(r1) ;
    l1 = squeeze(lefty(i,10:99)) ;
    larea = sum(l1) ;
    
    % Integrate the area under the curve starting 2 mm away from the edge and going to 50 mm
    r12 = squeeze(righty(i,2:50)) ;
    r2area = sum(r12) ;
    l12 = squeeze(lefty(i,2:50)) ;
    l2area = sum(l12) ;
    
    % Evaluate the noise component from the eye 10 mm from the edge and going to 100 mm
    r1eye = squeeze(rightyeye(i,10:99)) ;
    reyearea = sum(r1eye) ;
    l1eye = squeeze(leftyeye(i,10:99)) ;
    leyearea = sum(l1eye) ;
    
    % Disregard the DC component of the FFT and look at the max signal over
    % the mean signal
    h10 = rightyfft(i,5:halfft) ;
    h10b = leftyfft(i,5:halfft) ;
    h11 = (h10 + h10b) / 2 ;t the output type would be

% Build a path for the sMRI imaging .nii files
path_sMRI = importdata('/Volumes/rbraid/mr_data/tonya/scripts_quality_assurance_at_9/IDC_Numbers_T1_Wave_1.txt') ;
% t1_ratings = importdata('/Volumes/rbraid/mr_data.txt') ;

% Set the output path for the image quality data
outpath_vals = '/Volumes/rbraid/mr_data/tonya/scripts_quality_assurance_at_9/IDC_Automated_ratings_T1_Wave_1.csv' ;

% These are the paths to the nii files in the xnat server. The goal will be
% to read the structural MRI images one by one, based on the script that lists the
% individual IDC values. Then, it will copy each indivual sMRI over to a
% scratch file, unzip it, and extract the data. Then it will delete that
% file and save only the data from the image along with a snapshot in order
% to assure that the correct orientation has been obtained.
path_1 = '/Volumes/rbraid/mr_data_idc/aug2013_final/t1/' ;
path_2 = '/t1_idc_' ;
path_2a = '.nii.gz ' ;
path_2b = '/t1.nii.gz' ;
path_3 = '/Volumes/rbraid/mr_data/tonya/structural_at_9_scratch_file/t1.nii' ;
path_4 = '/Volumes/rbraid/mr_data/tonya/structural_at_9_scratch_file' ;
path_7 = '/Volumes/rbraid/mr_data/tonya/structural_at_9_scratch_file/t1_brain_mask.nii' ;
path_8 = '/Volumes/rbraid/mr_data/tonya/structural_at_9_scratch_file/t1edge.nii' ;
path_9 = '/Volumes/rbraid/mr_data/tonya/structural_at_9_scratch_file/t1_iso.nii' ;
path_7a = '/Volumes/rbraid/mr_data/tonya/structural_at_9_scratch_file/t1_brain_mask_iso.nii' ;
path_8a = '/Volumes/rbraid/mr_data/tonya/structural_at_9_scratch_file/t1edge_iso.nii' ;
cmd_1 = 'cp ' ;
cmd_b = 'gunzip /Volumes/rbraid/mr_data/tonya/structural_at_9_scratch_file/t1.nii.gz' ;
cmd_c = 'rm /Volumes/rbraid/mr_data/tonya/structural_at_9_scratch_file/*' ;


% Set the threshold for the edge of the brain
thresh = 1000 ;
edgethresh = 500 ;

% Set the number of axial slices that will be used to calculate the noise
slabs = 5 ;

% Set the number of slices down from the top of the brain to do the
% calculations
topdown = 80 ;
topstart = 10 ;     % Starting down from the top of the brain
eye = 50 ;          % Number of mm to count for the noise for eye movement
% back = 50 ;         % number of mm to calculate from the back of the brain
ftleng = 25 ;       % Length of the array to do the Fourier transform on
fftleng = 60 ;

% Set the dimensions for the images
dimx = 186 ;
dimy = 512 ;
dimz = 512 ;
slcx = 93 ;
slcy = 256 ;
slcz = 256 ;


% ________________________________________________________________________

%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

% ------------------------------------------------------------------------

sz1 = size(path_sMRI) ;
n = sz1(1,1) ;

% Create arrays to make the sagital, axial, and coronal images for all the
% subjects
sag = zeros(n,dimy,dimz) ;
axi = zeros(n,dimx,dimz) ;
cor = zeros(n,dimx,dimy) ;
slb = zeros(dimx,slabs,dimz) ;

halfft = round(fftleng/2) ;   % Set the half of the FFT variable.

% Create two linear arrays, right and left and one with the counts of data
% for each cell, so that they can be averaged. 1 is for the right side and
% two is for the left side of the brain.
rnoise = zeros(dimx,1) ;
lnoise = zeros(dimx,1) ;
reye = zeros(dimx,1) ;
leye = zeros(dimx,1) ;
ftrnoise = zeros(fftleng,1) ;
ftlnoise = zeros(fftleng,1) ;
ftrcount = 0 ;
ftlcount = 0 ;
rcnt = zeros(dimx,1) ;
lcnt = zeros(dimx,1) ;
rcnteye = zeros(dimx,1) ;
lcnteye = zeros(dimx,1) ;
rightedge = 0 ;  % Set the counter for the edge gradient ;
rightedge5 = 0 ;
rightgrad = 0 ;
leftedge = 0 ;  % Set the counter for the edge gradient ;
leftedge5 = 0 ;
leftgrad = 0 ;
ri2count = 0 ;
li2count = 0 ;

% Create an array to hold the curves for the noise data.
lefty = zeros(n,dimx) ;
righty = zeros(n,dimx) ;

for i = 1 : n
    % make the path for the child's sMRI data
    idc = num2str(path_sMRI(i)) ;
    path_5 = [path_1 idc path_2 idc path_2a] ;
    path_6 = [path_4 path_2b] ;
    % Execute the command to transfer the data to the scratch file.
    cmd_a = [cmd_1 path_5 path_6] ;
    [k1,k2] = system(cmd_a) ;
    % Now unzip the file so that it can be read in into Matlab
    !./Script_sMRI_run_bet_3dedge3.sh
    % Load the imaging data into a 3-D arrary
    imgstruct = load_nifti(path_3) ;
    smri = imgstruct.vol ;
    sz2 = size(smri) ;
    if sz2(1,1) == 186 && sz2(1,2) == 512 && sz2(1,3) == 512
    idc = num2str(path_sMRI(i)) ;
    path_5 = [path_1 idc path_2 idc path_2a] ;
    path_6 = [path_4 path_2b] ;
    % Execute the command to transfer the data to the scratch file.
    cmd_a = [cmd_1 path_5 path_6] ;
    [k1,k2] = system(cmd_a) ;
    % Load the brain mask and the brain edge image
    maskstruct = load_nifti(path_7) ;
    mask = imgstruct.vol > 0 ;
    edgestruct = load_nifti(path_8) ;
    edge = imgstruct.vol ;

    % Check to make sure that the dimensions of the images are correct, and
    % if not then use a flirt script to resample the image and force it
    % into the correct space ;
    %if sz2(1,1) ~= 220 ;
    %    !./Script_sMRI_resample_to_1mm.sh
    %    imgstruct = load_nifti(path_9) ;
    %    smri = imgstruct.vol ;
    %    maskstruct = load_nifti(path_7a) ;
    %    mask = imgstruct.vol > 0 ;
    %    edgestruct = load_nifti(path_8a) ;
    %    edge = imgstruct.vol ;
    %end

    % Create the snapshots of the sagital, axial, and coronal sections.
    sag(i,:,:) = squeeze(smri(slcx,:,:)) ;
    axi(i,:,:) = squeeze(smri(:,slcy,:)) ;
    cor(i,:,:) = squeeze(smri(:,:,slcz)) ;



    % Now work down in axial sections from the top of the brain until you
    % find the very top. We are counting down in the axial, or y direction.
    pflag = 0 ;
    topbrain = dimy ;
    while pflag == 0
        axd = max(squeeze(smri(:,topbrain,:))) ;
        axg = max(squeeze(edge(:,topbrain,:))) ;
        if axd < thresh | axg < edgethresh
            topbrain = topbrain - 1 ;
        else
            pflag = 1 ;
        end
    end

    % Now check to see if there are enough slices above to calculate the
    % noise from five different coronal slabs. Choose five coronal slices
    % that are at least five slices above the top of the brain

    if topbrain < (dimy-9)
        pnt1 = topbrain + 5 ;
        pnt2 = topbrain + slabs + 4 ;
        slb = squeeze(smri(:,pnt1:pnt2,:)) ;
        noisemean = mean(slb(:)) ;
        noisestd = std(slb(:)) ;
    elseif topbrain < (dimy-1)
        slba = squeeze(smri(:,(dimy-1):dimy,:)) ;
        noisemean = mean(slba(:)) ;
        noisestd = std(slba(:)) ;
    else
        noisemean = 0 ;
        noisestd = 0 ;
    end

    % Now that you've calculated the noise, the next thing to do is to
    % calculate the curves for each figure. This will start from the top of
    % the brain, from both the right and left side of the brain in the
    % sagital section, and move in. The goal will be to do approximately 5
    % cm (50-mm) of slices on both sides of the brain, and covering the
    % whole brain.

    midbrain = topbrain - topdown ;
    secbrain = topbrain - topstart ;

    % Similar to how you found the top of the brain, find the anterior and
    % posterior aspects of the brain.

    pflag = 0 ;
    anterior = 1 ;
    % Make a coronal slice that is <topdown> slices lower than the top of
    % the brain
    midslice = squeeze(smri(:,midbrain,:)) ;
    midedge = squeeze(edge(:,midbrain,:)) ;

    while pflag == 0
        cod = max(squeeze(midslice(:,anterior))) ;
        coe = max(squeeze(midedge(:,anterior))) ;
        if cod < thresh | coe < edgethresh
            anterior = anterior + 1 ;
        else
            pflag = 1 ;
    h12 = mean(h11(:)) ;
    h13 = max(h11(:)) ;
    if h12 ~= 0
        fftmaxovermean = h13 / h12 ;
    else 
        fftmaxovermean = 0 ;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Now create a program to replicate the same method used in the other
    % paper.
    
    % Create a mask in which entail the noise voxels outside the brain
    imgoutside = zeros(dimx,dimy,dimz) ;
    
    % imgoutside(:,topbrain,:) = smri(:,topbrain,:) ;  % creating slices with the noise outside the brain
    
    % Store all the values for the automated approaches in an array to
    % write out as a csv file.
    grad = (leftygrad + rightygrad) / 2
    values(i,:) = [i path_sMRI(i) topbrain anterior posterior noisemean noisestd rarea larea r2area l2area reyearea leyearea fftmaxovermean rightymax righty5 rightygrad leftymax lefty5 leftygrad grad] ;
    Percent_done = (i / n) * 100
    else
         values(i,:) = [i path_sMRI(i) -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1 -1] ;
    Percent_done = (i / n) * 100
    end
    system(cmd_c) 
    
    
    
end

vals = values 
  
figure
hold on
for oo = 1 : n
    plot(squeeze(righty(oo,10:99))) ;
end

hold off



figure
hold on
for oo = 1 : n
    plot(squeeze(lefty(oo,10:99))) ;
end

hold off

figure
hold on
for oo = 1 : n
    plot(squeeze(rightyeye(oo,10:99))) ;
end

hold off



figure
hold on
for oo = 1 : n
    plot(squeeze(leftyeye(oo,10:99))) ;
end

hold off




figure
hold on
for oo = 1 : n
    plot(squeeze(leftyfft(oo,2:30))) ;
end

hold off



figure
hold on
for oo = 1 : n
    plot(squeeze(rightyfft(oo,2:30))) ;
end

hold off



csvwrite(outpath_vals,vals) ;


% error('I just would like to stop the program right now, really not an error!')

