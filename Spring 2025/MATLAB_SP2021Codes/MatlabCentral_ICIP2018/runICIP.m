close all;
clear all;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Method Selection
%Set METHOD = 0 to only test the Segmentation Stage, 
%Set METHOD = 1 to run DEFA method, 
%else you run EMAR method  
%Set METHODSEG = 1  to run OTSU method
%Set METHODSEG = 2 to run Adaptive Thresh method, 
%Set METHODSEG = 3 to run Adaptive Thresh+extra method , 
%Set METHODSEG = 4 to run the proposed ICIP 2018 method 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
METHOD = 1; 
METHODSEG = 4;


AICBIC_SELECTION = 1; %Set AICBIC_SELECTION = 1, to use AIC is selected else BIC is used

set(0,'DefaultFigureColormap',jet);

DataDirD{1} = 'Dataset_NIH3T3//'; %NIH3T3 nucleus dataset
DataDirD{2} = 'Dataset_U20S//';  %U20S cell images
ResultsDirD{1} = 'RES_NIH3T3//';
ResultsDirD{2} = 'RES_U20S//';

filesD{1} = ['dna-0-0 dna-1-0 dna-10-0 dna-11-0 dna-12-0 dna-13-0 dna-14-0 dna-15-0 dna-16-0 dna-17-0 dna-18-0 dna-19-0 dna-2-0 dna-20-0 dna-21-0 dna-22-0 dna-23-0 dna-24-0 dna-26-0 dna-27-0 dna-28-0 dna-29-0 dna-3-0 dna-30-0 dna-31-0 dna-32-0 dna-33-0 dna-34-0 dna-35-0 dna-36-0 dna-37-0 dna-38-0 dna-39-0 dna-4-0 dna-40-0 dna-41-0 dna-42-0 dna-43-0 dna-44-0 dna-45-0 dna-46-0 dna-47-0 dna-48-0 dna-49-0 dna-5-0 dna-6-0 dna-7-0 dna-8-0 dna-9-0 '];
filesD{2} = ['dna-0-0 dna-1-0 dna-10-0 dna-11-0 dna-12-0 dna-13-0 dna-14-0 dna-15-0 dna-16-0 dna-17-0 dna-18-0 dna-19-0 dna-2-0 dna-20-0 dna-21-0 dna-22-0 dna-23-0 dna-24-0 dna-25-0 dna-26-0 dna-27-0 dna-28-0 dna-29-0 dna-3-0 dna-30-0 dna-32-0 dna-33-0 dna-34-0 dna-35-0 dna-36-0 dna-37-0 dna-38-0 dna-39-0 dna-4-0 dna-40-0 dna-41-0 dna-42-0 dna-44-0 dna-45-0 dna-46-0 dna-47-0 dna-48-0 dna-49-0 dna-5-0 dna-6-0 dna-7-0 dna-8-0 dna-9-0 '];


RUN_EXAMPLE = 1;%Run a specific example from dataset NIH3T3
fname = 'dna-0-0' 
fnameGT = 'dna-0-1'
DataDir = DataDirD{1};
ResultsDir = ResultsDirD{1};
%ALGO PARAMETERS 
NeighborhoodSize = 101;


if RUN_EXAMPLE == 1,
    [I] = imread(sprintf('%s%s.png',DataDir,fname)); %read input image
    GT = imread(sprintf('%s%s.png',DataDir,fnameGT));%read ground truth image
    [ GT ] = correctGT( GT);
    [IClustTotal,totEll,INITSEG] = runMainAlgo(I,AICBIC_SELECTION,METHOD,METHODSEG,NeighborhoodSize);
    
    %Statistics of segmentation 
    [REC, PR, F1, Overlap,BP,BDE,RECL,PRL,F1L,LGT] = getInitSegmentationStats(GT,INITSEG,IClustTotal);
    [Jaccard, MAD, Hausdorff, DiceFP,DiceFN,FP,FN,LGT] =getStats(GT,INITSEG,IClustTotal);
    
    %save result image 
    myImWriteOnRealImages(I,IClustTotal,LGT,ResultsDir,fname,1 );
    return;
end

%RUN all the images and datasets 
for DATASET=1:2, 
    if DATASET == 1,
        NeighborhoodSize = 101;
    else
        NeighborhoodSize = 151;
    end
    if exist('MFILE') == 0,
        DataDir = DataDirD{DATASET};
        files = filesD{DATASET};
        ResultsDir = ResultsDirD{DATASET};
        apo = 1;
        s = find(isspace(files)==1);
        data = cell(1,length(s));
        id = 1;
        j0 = 1;
    else
        load(MFILE);
        j0 = j+1;
    end
    
    for j=j0:length(s),
        close all;
        eos = s(j);
        fname = files(apo:eos-1);
        fnameGT = fname;
        fnameGT(length(fnameGT)) = '1';
        apo = eos+1;
        imagePerRUN = j / length(s)
        fname 
        
        [I] = imread(sprintf('%s%s.png',DataDir,fname));
        GT = imread(sprintf('%s%s.png',DataDir,fnameGT));
        [ GT ] = correctGT( GT);
       

        [IClustTotal,totEll,INITSEG] = runMainAlgo(I,AICBIC_SELECTION,METHOD,METHODSEG,NeighborhoodSize);
        [REC, PR, F1, Overlap,BP,BDE,RECL,PRL,F1L,LGT] = getInitSegmentationStats(GT,INITSEG,IClustTotal);
        [Jaccard, MAD, Hausdorff, DiceFP,DiceFN,FP,FN,LGT] =getStats(GT,INITSEG,IClustTotal);
        myImWriteOnRealImages(I,IClustTotal,LGT,ResultsDir,fname,0 );

        close all;
        statsE{id} = totEll;
        Fnames{id} = fname;
        statsPan(id,1:9) = [REC, PR, F1, Overlap,BP,BDE,RECL,PRL,F1L];
        stats(id,1:7) = [Jaccard, MAD, Hausdorff, DiceFP,DiceFN,FP,FN];
        id = id+1;
        save(sprintf('%sAIC.mat', ResultsDir),'stats','statsE','statsPan','Fnames');
    end
    gm = mean(stats(:,1));
    save(sprintf('%sRES_%2.2f.mat', ResultsDir,gm),'stats','statsE','statsPan','Fnames');
end