%% load data 
%load('C:\Paper_Data\WorkingData_7_2.mat');
load('Z:\bkramer\190218_184A1_EGF\Processed_Data\WorkingData_7_7.mat')
addpath(genpath('Z:\bkramer\190218_184A1_EGF\Data_Analysis\'));
javaaddpath('Z:\bkramer\190218_184A1_EGF\Data_Analysis\Functions\umapFileExchange (1.2.1)\umap\umap.jar');
load('Z:\bkramer\190218_184A1_EGF\Processed_Data\CubeHelixLong.mat');


%% Data description

% LinearIndex: Indicator to which condition each cell (i.e. row) belongs; Individual numbers denote replicates %
% 1,2,3,11,21,22,23,24,25,26,27,28,29,30 - 100ng/ml EGF
% 4,5,6 - 25ng/ml EGF
% 7,8,9 - 10ng/ml EGF
% 10,19,20 - 6.25ng/ml EGF
% 16,17,18 - 1ng/ml EGF
% 13,14,15 - 0ng/ml EGF
% 11,12,21,22,23,24,25,26,27,28,29,30 - 100ng/ml control for intensity decay and secondary antibody only controls after elution (see Gut et al. for details): 12: Cycle 01, 11: Cycle 02, 21: Cycle 03, 22: Cycle 04 etc... 30 always secondary only. Starting at 12... etc again when 29 was reached

% FeatureHeader: Descriptor of which cellular state feature (column) is represented in the corresponding double matrices %
% FeatureData: Contains raw (and transformed, see material and methods) single cell cellular state feature data; columns correspoding to cellular state features described in "FeatureHeader" %
% FeatureZData: Contains the z-scored (see material and methods) single cell cellular state feature data; columns corresponding to cellular state features described in "FeatureHeader" %

% MetaHeader: Descriptor of which MetaData (e.g. CentroidLocation in image, or which field in an image) is represented in the corresponding double matrices %
% MetaData: Contains single cell information on the Metadata; columns corresponding to information described in "MetaHeader"

% ResponseHeader: Descriptor of which response (column) is represented in the corresponding double matrices %
% ResponseData: Contains raw single cell data; columns corresponding to response features described in "ResponseHeader" %
% LogResponseData: Contains transformed (see material and methods) single cell data; columns corresponding to response features described in "ResponseHeader" %

% PCCoeff: Contains the loadings of each principal component from principal component analysis on cellular state features (FeatureZData)
% PCFeatureData: Contains single cell data of cellular state features (from FeatureZData) transformed to PCs). Only the PCs which together explain 97.5% of the variance are kept (hence only 157)

% WeightedClusterData: Data from PCFeatureData weighted as described in material and methods and used as input for fuzzy clustering. Columns correspond to the PCs used; further described in script for Figure 3; Only clustered on cells belong to LinearIndex 1,2,3,4,5,6,7,8,9,10,13,14,15 and 20 %
% ClusterCenter: Centroid locations for the individual cluster centers obtained from fuzzy clustering on cellular state features %
% MembershipData: Contains the Membership degree (Fuzzy clustering outputs degrees of membership, no clear assignement) for each single cell)

%% Supplementary Figure 2A



%% Supplementary Figure 2B

% Assembled in Adobe Illustrator; ai. can be shared; Raw plots used are generated by the following

WellGroups = {[1,2,3],[4,5,6],[7,8,9],[10,19,20],[13,14,15]};

FavoriteStains = [18,168,3,123,153,108,33,61,91,78];
Eval = 0:0.05:12;

for CurrentStain = 1:size(FavoriteStains,2)
    figure
    hold on
    for CurrentWell = 1:size(WellGroups,2)
        WellIndex = find(ismember(LinearIndex,WellGroups{1,CurrentWell}));
        Density = ksdensity(LogResponseData(WellIndex,FavoriteStains(CurrentStain)),Eval);
        plot(Eval,Density);
    end
end


%% Supplementary Figure 2I

% Assembled in Adobe Illustrator; ai. can be shared; Raw plots used are generated by the following

WellIndex = ismember(LinearIndex,[1,2,3,4,5,6,7,8,9,10,13,14,15,19,20]);
BGIndex = find([contains(FeatureHeader,'BG488');contains(FeatureHeader,'BG568');contains(FeatureHeader,'BG647')]);

MorphologyIndex = find(contains(FeatureHeader,'Morphology'));
MorphologyIndex = setdiff(MorphologyIndex,BGIndex);

IntensityRawIndex = find(contains(FeatureHeader,'Intensity'));
STDIndex = find(contains(FeatureHeader,'std'));
IntensityIndex = setdiff(IntensityRawIndex,STDIndex);
IntensityIndex = setdiff(IntensityIndex,BGIndex);

TextureIndex = find(contains(FeatureHeader,'Texture'));
TextureIndex = setdiff(TextureIndex,BGIndex);

PopulationIndex = [641:650,1291:1300];
PopulationIndex = setdiff(PopulationIndex,BGIndex);

CellularIndex = [MorphologyIndex;IntensityIndex];


PopulationPlotFeatures = [11:20];
CellularPlotFeatures = [1,14,244,150,154,158,161,164,171,174,178,182,184,188,192,193,196,206,208,214,218,222];
TexturePlotFeatures = [437,438,440,441,442,443,444,445,446,447,448,449,450,451];

PopulationFeatures = PopulationIndex(PopulationPlotFeatures)';
CellularFeatures = CellularIndex(CellularPlotFeatures);
TextureFeatures = TextureIndex(TexturePlotFeatures);
FullFeatures = [PopulationIndex(PopulationPlotFeatures)';CellularIndex(CellularPlotFeatures);TextureIndex(TexturePlotFeatures)];

% Generate UMAP - CAVEAT!!!!! EVERY UMAP RUN CAN DIFFER
WellIndex = find(ismember(LinearIndex,[1,2,3,4,5,6,7,8,9,10,19,20,13,14,15]));
% NumberNeighbors = 30;
% DistanceMetric = 'cityblock';
% [ReductionUmap,UMAPCoord] = run_umap(ReducedPCFeatureData(WellIndex,:),'n_neighbors',NumberNeighbors,'metric',DistanceMetric);
ReducedLinearIndex = LinearIndex(WellIndex);
ReducedWellIndex = find(ismember(ReducedLinearIndex,[1,2,3,4,5,6,7,8,9,10,19,20,13,14,15]));

RandShuffle = randperm(length(ReducedLinearIndex));

for CurrentFeature = FullFeatures'
           
    figure
    scatter(ReductionUmap(ReducedWellIndex(RandShuffle),1),ReductionUmap(ReducedWellIndex(RandShuffle),2),4,FeatureZData(RandShuffle,CurrentFeature),'filled','MarkerEdgeColor','none');
    %colorbar
    caxis([-2 2])
    colormap(flipud(brewermap(500,'RdBu')));
    axis off
    ylim([-4.3 6.8])
    xlim([-7.5 10.5])
    
    set(gcf,'position',[2963 -211 590.8 450])
    ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\RevisionFigures\Supplementary_Figure_2\Raw_Figures\UMAP_',FeatureHeader{CurrentFeature,1},'.jpg'];
    export_fig(ExportPath,'-r1200','-transparent')
    
    axis on
    colorbar
    
    ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\RevisionFigures\Supplementary_Figure_2\Raw_Figures\UMAP_',FeatureHeader{CurrentFeature,1},'.pdf'];
    export_fig(ExportPath,'-painters')
    
    close all
    
end


