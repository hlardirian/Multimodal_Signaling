%% load data 
% Adjust path to wherever data and function folder is located
load('Z:\bkramer\190218_184A1_EGF\Data_Analysis\CleanCode\Data_1.mat')
addpath(genpath('Z:\bkramer\190218_184A1_EGF\Data_Analysis\'));
javaaddpath('Z:\bkramer\190218_184A1_EGF\Data_Analysis\Functions\umapFileExchange (1.2.1)\umap\umap.jar');
load('Z:\bkramer\190218_184A1_EGF\Processed_Data\CubeHelixLong.mat');
load('Z:\bkramer\190218_184A1_EGF\Data_Analysis\SingleCellDR_Normed.mat');

%% Data description

% LinearIndex: Indicator to which condition each cell (i.e. row) belongs; Individual numbers denote replicates %
% 1,2,3,11,21,22,23,24,25,26,27,28,29,30 - 100ng/ml EGF
% 4,5,6 - 25ng/ml EGF
% 7,8,9 - 10ng/ml EGF
% 10,19,20 - 6.25ng/ml EGF
% 16,17,18 - 1ng/ml EGF
% 13,14,15 - 0ng/ml EGF
% 11,12,21,22,23,24,25,26,27,28,29,30 - 100ng/ml control for intensity decay and secondary antibody only controls after elution (see Gut et al. for details): 11: Cycle 1, 12: Cycle 2 etc... 30 always secondary only. Starting at 11... etc again when 29 was reached

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

% MSTData: Relic from the past; not used in the paper %
% MSTHeader: Relic from the past; not used in the paper %

% WeightedClusterData: Data from PCFeatureData weighted as described in material and methods and used as input for fuzzy clustering. Columns correspond to the PCs used; further described in script for Figure 3; Only clustered on cells belong to LinearIndex 1,2,3,4,5,6,7,8,9,10,13,14,15 and 20 %
% ClusterCentor: Centroid locations for the individual cluster centers obtained from fuzzy clustering on cellular state features %
% MembershipData: Contains the Membership degree (Fuzzy clustering outputs degrees of membership, no clear assignement) for each single cell)

%% Supplementary Figure 6A

% Assembled in Adobe Illustrator; ai. can be shared - Raw plots used are generated by the following


WellBatches = {[13,14,15];[10,20,19];[7,8,9];[4,5,6];[1,2,3]};
ResponseStain = [18,168,3,123,153,108,33,61,91,78];
IndicatorStorage = cell(1,size(ResponseStain,2)*5);
ZPCData = zscore(PCFeatureData);

OtherIndex = 1;
for CurrentWellCounter = 1:size(WellBatches,1)   
    CurrentWell = WellBatches{CurrentWellCounter,1};
    WellIndex = find(ismember(LinearIndex,CurrentWell));
    InsertIndex = 1;
    for ResponseCounter = 1:size(ResponseStain,2)
        CurrentResponse = ResponseStain(ResponseCounter);
                
        CurrentIndependentData = ZPCData(WellIndex,:);
        CurrentResponseData = zscore(LogResponseData(WellIndex,CurrentResponse));
        
        CurrentCoefficients = zeros(size(CurrentIndependentData,2),1);
        IndicatorMatrix = ones(size(CurrentIndependentData,2),1);
        CoefficientIndicator = 1:size(CurrentIndependentData,2);        
        
        while all(CurrentCoefficients) == 0
            
            MDL = cvglmnet(CurrentIndependentData(:,CoefficientIndicator),CurrentResponseData);
            ModelCoefficients = cvglmnetCoef(MDL,'lambda_1se');
            ModelCoefficients(1) = [];
            
            
            ZeroElements = find(ModelCoefficients == 0);
            TrueZero = CoefficientIndicator(ZeroElements);
            CoefficientIndicator = setdiff(CoefficientIndicator,TrueZero);
            IndicatorMatrix(TrueZero,1) = 0;
            
            CurrentCoefficients = ModelCoefficients;
        end 
        
        IndicatorStorage{1,OtherIndex} = IndicatorMatrix;
        InsertIndex = InsertIndex + 1;
        OtherIndex = OtherIndex + 1;
    end   
end


IndicatorSummary = cell2mat(IndicatorStorage);
SumMatrix = sum(IndicatorSummary,2);

IndicatorThresh = find(SumMatrix >= 40);

% Now p-Value...

WellBatches = {[13,14,15];[10,20,19];[7,8,9];[4,5,6];[1,2,3]};
ResponseStain = [18,168,3,123,153,108,33,61,91,78];

IndicatorPStorage = cell(1,size(ResponseStain,2)*5);

OtherIndex = 1;
for CurrentWellCounter = 1:size(WellBatches,1)   
    CurrentWell = WellBatches{CurrentWellCounter,1};
    WellIndex = find(ismember(LinearIndex,CurrentWell));
    InsertIndex = 1;
    for ResponseCounter = 1:size(ResponseStain,2)
        CurrentResponse = ResponseStain(ResponseCounter);
                
        CurrentIndependentData = ZPCData(WellIndex,:);
        CurrentResponseData = zscore(LogResponseData(WellIndex,CurrentResponse));
        
        CoefficientIndicator = IndicatorThresh;
        IndicatorMatrix = ones(size(CurrentIndependentData,2),1);
        
        PValues = ones(size(CoefficientIndicator,1),1);
        LoopCounter = 1;
        while any(PValues >= 0.01) == 1
            
            MDL = fitlm(CurrentIndependentData(:,CoefficientIndicator),CurrentResponseData);
            
            PValuesTable = MDL.Coefficients;
            PValuesMat = table2array(PValuesTable);
            PValuesMat(1,:) = [];
            PValues = PValuesMat(:,4);
            
            AboveSignificant =find(PValues >= 0.01);
            TrueAbove = CoefficientIndicator(AboveSignificant);
            
            CoefficientIndicator = setdiff(CoefficientIndicator,TrueAbove);
             
            IndicatorMatrix(TrueAbove,1) = 0;
            LoopCounter
            LoopCounter = LoopCounter + 1;
        end 
        
        IndicatorPStorage{1,OtherIndex} = IndicatorMatrix;
        InsertIndex = InsertIndex + 1;
        OtherIndex = OtherIndex + 1;
    end   
end


IndicatorPSummary = cell2mat(IndicatorPStorage);
SumPMatrix = sum(IndicatorPSummary,2);
SumPMatrix(setdiff(1:size(PCFeatureData,2),IndicatorThresh),1) = 0;

IndicatorPThresh = find(SumPMatrix >= 40);

% Now Get the Actual Coefficients....

WellBatches = {[13,14,15];[10,20,19];[7,8,9];[4,5,6];[1,2,3]};
ResponseStain = [18,168,3,123,153,108,33,61,91,78];
CoefficientStorage = cell(1,size(ResponseStain,2)*5);

OtherIndex = 1;
for CurrentWellCounter = 1:size(WellBatches,1)
    CurrentWell = WellBatches{CurrentWellCounter,1};
    WellIndex = find(ismember(LinearIndex,CurrentWell));
    for ResponseCounter = 1:size(ResponseStain,2)
        CurrentResponse = ResponseStain(ResponseCounter);
        
        CurrentIndependentData = ZPCData(WellIndex,:);
        CurrentResponseData = zscore(LogResponseData(WellIndex,CurrentResponse));
        
        CurrentCoefficients = zeros(size(CurrentIndependentData,2),1);
            
        MDL = cvglmnet(CurrentIndependentData(:,IndicatorPThresh),CurrentResponseData);
        ModelCoefficients = cvglmnetCoef(MDL,'lambda_1se');
        ModelCoefficients(1) = [];
           
        CurrentCoefficients(IndicatorPThresh,1) = ModelCoefficients;
                   
        CoefficientStorage{1,OtherIndex} = CurrentCoefficients;
        OtherIndex = OtherIndex + 1;
    end
end

CoefficientMatrix = cell2mat(CoefficientStorage);


SumCoefficients = sum(abs(CoefficientMatrix),2);
MaxNormed = SumCoefficients./max(SumCoefficients);


JustWeights = MaxNormed(IndicatorPThresh);

% Write to CSV

WellIndex = find(ismember(LinearIndex,[1,2,3,4,5,6,7,8,9,10,13,14,15,19,20]));
ClusterData = ZPCData(WellIndex,IndicatorPThresh);

WeightedClusterData = ClusterData.*JustWeights';

ResponseCell = [10,19,20];
CurrentStain = 5;
WellIndex = find(ismember(LinearIndex,ResponseCell));
WellResponseData = LogResponseData(WellIndex,CurrentStain);

LowCells = intersect(find(WellResponseData  >= 0),find(WellResponseData < 5.33));
HighCells = intersect(find(WellResponseData  >= 7.9),find(WellResponseData <= 14));

LowIndex = WellIndex(LowCells);
HighIndex = WellIndex(HighCells);

GroupIndex = [ones(size(LowIndex,1),1);repmat(2,size(HighIndex,1),1)];
FeatureDataModel = [PCFeatureData(LowIndex,:);PCFeatureData(HighIndex,:)];

MDL = cvglmnet(FeatureDataModel,GroupIndex,'binomial');

WellIndex = ismember(LinearIndex,[1,2,3,4,5,6,7,8,9,10,13,14,15,19,20]);
TestData = PCFeatureData(WellIndex,:);

FitIndex = cvglmnetPredict(MDL,TestData,'lambda_1se','class');

FitIndex(FitIndex == 1) = -1;
FitIndex(FitIndex == 2) = 1;

ScaleIndex = FitIndex.*0.25;
WeightedClusterData(:,end+1) = ScaleIndex;

Iterations = 98;
%parpool(30);

StorageFunction = cell(Iterations,1);
StorageCenter = cell(Iterations,1);
StorageMembership = cell(Iterations,1);

parfor CurrentIteration = 1:Iterations
    [ClusterCenter,Membership,Function] = fcmMan(WeightedClusterData,18,[1.125 400 NaN 0]);
    StorageMembership{CurrentIteration,1} = Membership';
    StorageCenter{CurrentIteration,1} = ClusterCenter;
    StorageFunction{CurrentIteration,1} = Function(end);
    CurrentIteration
end

FunctionMat = cell2mat(StorageFunction);

% Find Mininal Objective function value...

[~,MinIndex] = min(FunctionMat);

ClusterCenter = StorageCenter{MinIndex,1};
MembershipData = StorageMembership{MinIndex,1};



%% Supplementary Figure 6B

load('Z:\bkramer\190218_184A1_EGF\Data_Analysis\CleanCode\Data_1_5.mat');

WellIndex = find(ismember(LinearIndex,[1,2,3,4,5,6,7,8,9,10,13,14,15,19,20]));
DataMatrix = PCFeatureData(WellIndex,:);

ClusterIdentity = cell(90,1);
NumCluster = zeros(90,1);

InsertIndex = 1;
for CurrentX = 1:10
    for CurrentY = 2:10
        TableString = ['Z:\bkramer\190218_184A1_EGF\Processed_Data\SOM_Data\SOMCluster_',num2str(CurrentX),'_',num2str(CurrentY),'.csv'];
        ClusterTable = readtable(TableString);
        TableMat = ClusterTable(:,2);
        TableMat = TableMat{:,:};
        ClusterIdentity{InsertIndex,1} = TableMat;
        NumCluster(InsertIndex,1) = CurrentX*CurrentY;
        InsertIndex = InsertIndex + 1;
    end
end

% Calculate BIC/AIC

BICStorage = zeros(90,1);
AICStorage = zeros(90,1);

for CurrentCluster = 1:90
    CurrentIdentity = ClusterIdentity{CurrentCluster,1};
    CurrentNumber = NumCluster(CurrentCluster,1);
    [BIC,AIC] = ClusterBICAIC(DataMatrix,CurrentIdentity,CurrentNumber,5.2);
    BICStorage(CurrentCluster,1) = BIC;
    AICStorage(CurrentCluster,1) = AIC;
end

figure
scatter(NumCluster,BICStorage);

% Assembled in Adobe Illustrator; ai. can be shared - Raw plots used are generated by the following

PhenoGraphCluster = readtable('Z:\bkramer\190218_184A1_EGF\Processed_Data\PhenoGraphClusterNum.csv');
PhenoGraphSampleSpace = readtable('Z:\bkramer\190218_184A1_EGF\Processed_Data\PhenoGraphSampleSpace.csv');

ClusterNum = PhenoGraphCluster(:,2);
SampleSpace = PhenoGraphSampleSpace(:,2);

ClusterNum = ClusterNum{:,:};
SampleSpace = SampleSpace{:,:};

figure
plot(SampleSpace(2:end),ClusterNum(2:end))
ylim([0 40])
line([0 200],[20 20])
line([0 200],[15 15])
line([0 105],[18 18])
line([105 105], [0 18])

%% Supplementary Figure 6C

% Assembled in Adobe Illustrator; ai. can be shared - Raw plots used are generated by the following


ExponentTest = linspace(1,2,201);
StorageGiniMean = zeros(size(ExponentTest,2),1);
StorageGiniStd = zeros(size(ExponentTest,2),1);

ExponentTest(1,1) = 1.0025;

%parpool(16)

parfor CurrentExponentIndex = 1:size(ExponentTest,2)
    
    CurrentExponent = ExponentTest(1,CurrentExponentIndex);
    [ClusterCenter,Membership,Function] = fcmMan(WeightedClusterData,20,[CurrentExponent 400 NaN 0]);
    
    StorageGini = zeros(1,20);
    
    for CurrentCluster = 1:20
        StorageGini(1,CurrentCluster) = ginicoeff(Membership(CurrentCluster,:));
    end
    
    MeanGini = mean(StorageGini);
    StdGini = std(StorageGini);
    
    StorageGiniMean(CurrentExponentIndex,1) = MeanGini;
    StorageGiniStd(CurrentExponentIndex,1) = StdGini;
    
end

%% Supplementary Figure 6D

% Assembled in Adobe Illustrator; ai. can be shared - Raw plots used are generated by the following

% Minor differences are due to randomness in Fuzzy clustering

WellGroups = {[13,14,15],[10,19,20],[9,8,7],[6,5,4],[3,2,1]};

ClusterPerGroup = zeros(5,18);

for CurrentWellIndex = 1:size(WellGroups,2)
    CurrentWells = WellGroups{1,CurrentWellIndex};
    WellIndex = find(ismember(LinearIndex,CurrentWells));
    for CurrentCluster = 1:18
        ClusterPerGroup(CurrentWellIndex,CurrentCluster) = nansum(MembershipData(WellIndex,CurrentCluster));     
    end
end

figure
bar(ClusterPerGroup','stacked')

%% Supplementary Figure 6E

% Assembled in Adobe Illustrator; ai. can be shared - Raw plots used are generated by the following

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

% Population Scale

PopulationScaleMeans = zeros(18,size(PopulationIndex,2));
PopulationHeader = cell(size(PopulationIndex,2),1);

for CurrentCluster = 1:18
    for CurrentFeature = 1:size(PopulationIndex,2)
        PopulationScaleMeans(CurrentCluster,CurrentFeature) = nansum(FeatureZData(WellIndex,PopulationIndex(CurrentFeature)).*MembershipData(WellIndex,CurrentCluster))/nansum(MembershipData(WellIndex,CurrentCluster));
        PopulationHeader{CurrentFeature,1} = FeatureHeader{PopulationIndex(CurrentFeature),1};
    end
end


% Cellular Scale

CellularScaleMeans = zeros(18,size(CellularIndex,1));
CellularHeader = cell(size(CellularIndex,1),1);

for CurrentCluster = 1:18
    for CurrentFeature = 1:size(CellularIndex,1)
        CellularScaleMeans(CurrentCluster,CurrentFeature) = nansum(FeatureZData(WellIndex,CellularIndex(CurrentFeature)).*MembershipData(WellIndex,CurrentCluster))/nansum(MembershipData(WellIndex,CurrentCluster));
        CellularHeader{CurrentFeature,1} = FeatureHeader{CellularIndex(CurrentFeature),1};
    end
end

% Subcellular Scale

TextureScaleMeans = zeros(18,size(TextureIndex,1));
TextureHeader = cell(size(TextureIndex,1),1);

for CurrentCluster = 1:18
    for CurrentFeature = 1:size(TextureIndex,1)
        TextureScaleMeans(CurrentCluster,CurrentFeature) = nansum(FeatureZData(WellIndex,TextureIndex(CurrentFeature)).*MembershipData(WellIndex,CurrentCluster))/nansum(MembershipData(WellIndex,CurrentCluster));
        TextureHeader{CurrentFeature,1} = FeatureHeader{TextureIndex(CurrentFeature),1};
    end
end



PopulationPlotFeatures = [11:20];
CellularPlotFeatures = [1,14,244,150,154,158,161,164,171,174,178,182,184,188,192,193,196,206,208,214,218,222];
TexturePlotFeatures = [437,438,440,441,442,443,444,445,446,447,448,449,450,451];

ScaleColorMap = flipud(brewermap(500,'RdBu'));

PlotMatrix = PopulationScaleMeans(:,PopulationPlotFeatures);
PlotMatrix = [flipud(PlotMatrix),zeros(18,1);zeros(1,11)];

figure
pcolor(PlotMatrix);
axis equal
axis off
caxis([-1 1])
colormap(ScaleColorMap);
colorbar


PlotMatrix = CellularScaleMeans(:,CellularPlotFeatures);
PlotMatrix = [flipud(PlotMatrix),zeros(18,1);zeros(1,23)];

figure
pcolor(PlotMatrix);
axis equal
axis off
caxis([-1 1])
colormap(ScaleColorMap);
colorbar



PlotMatrix = TextureScaleMeans(:,TexturePlotFeatures);
PlotMatrix = [flipud(PlotMatrix),zeros(18,1);zeros(1,15)];

figure
pcolor(PlotMatrix);
axis equal
axis off
caxis([-1 1])
colormap(ScaleColorMap);
colorbar



figure
PlotMatrix = [PopulationScaleMeans(:,PopulationPlotFeatures),CellularScaleMeans(:,CellularPlotFeatures),TextureScaleMeans(:,TexturePlotFeatures)];
PlotMatrix = [flipud(PlotMatrix),zeros(18,1);zeros(1,47)];
pcolor(PlotMatrix)
caxis([-1 1])
colormap(ScaleColorMap);
colorbar
axis image



%% Supplementary Figure 6F

% Assembled in Adobe Illustrator; ai. can be shared - Raw plots used are generated by the following


WellIndex = find(ismember(LinearIndex,[1,2,3,4,5,6,7,8,9,10,19,20,13,14,15]));
ReducedMembershipData = MembershipData(WellIndex,:);

[NaNRows,~] = find(isnan(ReducedMembershipData));
UniqueRows = unique(NaNRows);

ReductionUmap(UniqueRows,:) = [];
ReducedMembershipData(UniqueRows,:) = [];


CurrentEC50 = StorageEC50{4,1};
CurrentEC50(UniqueRows,:) = [];

figure
scatter(ReductionUmap(:,1),ReductionUmap(:,2),4,CurrentEC50,'filled','MarkerEdgeColor','none')
caxis([2.5 7.5]);
%colormap(getPyPlot_cMap('rainbow',500))
colormap(gistColorMap(:,1:3))

ylim([-4.3 6.8])
xlim([-7.5 10.5])

set(gcf,'position',[2963 -211 590.8 450])
axis off




CurrentEC50 = StorageEC50{5,1};
CurrentEC50(UniqueRows,:) = [];

figure
scatter(ReductionUmap(:,1),ReductionUmap(:,2),4,CurrentEC50,'filled','MarkerEdgeColor','none')
caxis([2.5 7.5]);
%colormap(getPyPlot_cMap('rainbow',500))
colormap(gistColorMap(:,1:3))

ylim([-4.3 6.8])
xlim([-7.5 10.5])

set(gcf,'position',[2963 -211 590.8 450])
axis off




CurrentEC50 = StorageEC50{7,1};
CurrentEC50(UniqueRows,:) = [];

figure
scatter(ReductionUmap(:,1),ReductionUmap(:,2),4,CurrentEC50,'filled','MarkerEdgeColor','none')
caxis([2.5 7.5]);
%colormap(getPyPlot_cMap('rainbow',500))
colormap(gistColorMap(:,1:3))

ylim([-4.3 6.8])
xlim([-7.5 10.5])

set(gcf,'position',[2963 -211 590.8 450])
axis off



CurrentEC50 = StorageEC50{8,1};
CurrentEC50(UniqueRows,:) = [];

figure
scatter(ReductionUmap(:,1),ReductionUmap(:,2),4,CurrentEC50,'filled','MarkerEdgeColor','none')
caxis([2.5 7.5]);
%colormap(getPyPlot_cMap('rainbow',500))
colormap(gistColorMap(:,1:3))

ylim([-4.3 6.8])
xlim([-7.5 10.5])

set(gcf,'position',[2963 -211 590.8 450])
axis off





CurrentEC50 = StorageEC50{9,1};
CurrentEC50(UniqueRows,:) = [];

figure
scatter(ReductionUmap(:,1),ReductionUmap(:,2),4,CurrentEC50,'filled','MarkerEdgeColor','none')
caxis([2.5 7.5]);
%colormap(getPyPlot_cMap('rainbow',500))
colormap(gistColorMap(:,1:3))

ylim([-4.3 6.8])
xlim([-7.5 10.5])

set(gcf,'position',[2963 -211 590.8 450])
axis off




CurrentEC50 = StorageEC50{10,1};
CurrentEC50(UniqueRows,:) = [];

figure
scatter(ReductionUmap(:,1),ReductionUmap(:,2),4,CurrentEC50,'filled','MarkerEdgeColor','none')
caxis([2.5 7.5]);
%colormap(getPyPlot_cMap('rainbow',500))
colormap(gistColorMap(:,1:3))

ylim([-4.3 6.8])
xlim([-7.5 10.5])

set(gcf,'position',[2963 -211 590.8 450])
axis off



