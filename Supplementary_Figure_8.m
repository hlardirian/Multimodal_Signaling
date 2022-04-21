%% load data 
% Adjust path to wherever data and function folder is located
load('Z:\bkramer\190218_184A1_EGF\Data_Analysis\CleanCode\Data_1.mat')
addpath(genpath('Z:\bkramer\190218_184A1_EGF\Data_Analysis\'));
javaaddpath('Z:\bkramer\190218_184A1_EGF\Data_Analysis\Functions\umapFileExchange (1.2.1)\umap\umap.jar');
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

%% Supplementary Figure 8A

% Assembled in Adobe Illustrator; ai. can be shared - Raw plots used are generated by the following

WellGroups = {[13,14,15],[10,19,20],[9,8,7],[6,5,4],[3,2,1]};
FavoriteStains = [18,168,3,123,153,108,33,91,61,78];

NonCorrMatrix = cell(5,1);
CorrMatrix = cell(5,1);

for CurrentWellGroup = 1:5
    CurrentWells = WellGroups{1,CurrentWellGroup};
    WellIndex = find(ismember(LinearIndex,CurrentWells));
    WellResponseData = LogResponseData(WellIndex,FavoriteStains);
    CorrelationStructure = 1 - corr(WellResponseData);
    NonCorrMatrix{CurrentWellGroup,1} = CorrelationStructure;
    CorrMatrix{CurrentWellGroup,1} = corr(WellResponseData);
end

for CurrentWellGroup = 1:5

    figure
    imagesc(CorrMatrix{CurrentWellGroup,1});
    caxis([0 1])
    axis square
    colormap(brewermap(500,'Greys'))

    figure
    imagesc(NonCorrMatrix{CurrentWellGroup,1});
    caxis([0 1])
    axis square
    colormap(brewermap(500,'Reds'))

end


%% Supplementary Figure 8B

% Assembled in Adobe Illustrator; ai. can be shared - Raw plots used are generated by the following


FeatureIndex = [1291:1300,1,14,15,20,87,91,95,98,101,108,111,115,119,121,125,129,130,133,146,148,154,158,625,626,628,629,630,631,632,633,634,635,636,637,638,639];

FeatureNames = cell(size(FeatureIndex,1),1);

for CurrentName = 1:size(FeatureIndex,1)
    FeatureNames{CurrentName,1} = FeatureHeader{FeatureIndex(CurrentName,1),1};   
end

WellCell = {[3,2,1],[4,5,6],[7,8,9],[10,19,20],[13,14,15]};
ResponseStain = [18,168,3,123,153,108,33,91,61,78];

ManualFeatureNames = {'# Neighbors','% Touching','LCD1','LCD2','LCD3','LCD4','LCC','SingleCellInd','EdgeIndicator','DistanceToEdge','Area Nucleus','Area Cell','Perimeter Cell','Cell Roundness','Int. Paxillin','Int. GM130','Int. Actin','Int. EEA1','Int. ERGIC53',...
    'Int. Calreticulin','Int. Sec13','Int. ABCD3','Int. Dynamin','Int. Yap1','Int. HSP60', 'Int. CyclinB','Int. PCNA','Int. pPolII','Int. VPS35','Int. pRB','Int. Tubulin',...
    'Int. DDX6','Tex. PCNA','Tex. pPolII','Tex. Paxillin','Tex. GM130','Tex. Actin','Tex. EEA1','Tex. ERGIC53','Tex. Calreticulin','Tex. Sec13',...
    'Tex. ABCD3','Tex. HSP60','Tex. VPS35','Tex. Tubulin','Tex. DDX6'};

TextMatrix = {'pEGFR','pMEK','pERK','pRSK','pGSK3B','pMTOR','pAKT','FoxO1','FoxO3a','pS6'};
ConcentrationCell = {'100ng','25ng','10ng','6.25ng','0ng'};

FullCorrelationStorageCoef = zeros(size(FeatureIndex,2),size(ResponseStain,2),size(WellCell,2));
FullCorrelationStoragePartial = zeros(size(FeatureIndex,2),size(ResponseStain,2),size(WellCell,2));
for CurrentWellCell = 1:size(WellCell,2)
    
    
    CurrentWell = WellCell{1,CurrentWellCell};
    WellIndex = find(ismember(LinearIndex,CurrentWell));
    
    CurrentFeatures = FeatureZData(WellIndex,FeatureIndex);
    CurrentResponses = zscore(LogResponseData(WellIndex,ResponseStain));
    
    CorrelationStorage = zeros(size(CurrentFeatures,2),size(CurrentResponses,2));
    
    for CurrentStain = 1:size(CurrentResponses,2)
    
    WellResponseData = CurrentResponses(:,CurrentStain);
    MDL1 = cvglmnet(CurrentFeatures,WellResponseData);
    Coefficients = cvglmnetCoef(MDL1);
    Coefficients(1) = [];
    CorrelationStorage(:,CurrentStain) = Coefficients;
    
    end
    
    FullCorrelationStorageCoef(:,:,CurrentWellCell) = CorrelationStorage;
    
    CorrelationStorage = zeros(size(CurrentFeatures,2),size(CurrentResponses,2));
    for CurrentStain = 1:size(CurrentResponses,2)
        DifferenceResponse = setdiff(1:size(CurrentResponses,2),CurrentStain);
        PartialCorrelation = partialcorr(CurrentFeatures,CurrentResponses(:,CurrentStain),CurrentResponses(:,DifferenceResponse));
        CorrelationStorage(:,CurrentStain) = PartialCorrelation;
    end
    
    FullCorrelationStoragePartial(:,:,CurrentWellCell) = CorrelationStorage;
    
end

CorrelationStorageCoef = mean(FullCorrelationStorageCoef,3);
CorrelationStoragePartial = mean(FullCorrelationStoragePartial,3);

%Pcolor

for CurrentWell = 1:5
    
    CurrentCorr = FullCorrelationStoragePartial(:,:,CurrentWell);
    FlippedCorr = flipud(CurrentCorr');
    PlotCorr = [FlippedCorr;zeros(1,46)];
    PlotCorr = [PlotCorr,zeros(11,1,1)];
    MaxRow = max(PlotCorr,[],2);
    MinRow = min(PlotCorr,[],2);
    
    for CurrentStain = 1:11
        CurrentCorr = PlotCorr(CurrentStain,:);
        Positive = find(CurrentCorr > 0);
        CurrentCorr(Positive) = CurrentCorr(Positive)./MaxRow(CurrentStain);
        Negative = find(CurrentCorr < 0);
        CurrentCorr(Negative) = CurrentCorr(Negative)./abs(MinRow(CurrentStain));
        PlotCorr(CurrentStain,:) = CurrentCorr;
        
    end
    
    
    figure
    pcolor(PlotCorr)
    axis image
    caxis([-1 1])
    colormap(flipud(brewermap(500,'RdBu')))
    yticks([1.5:10.5]);
    yticklabels(fliplr(TextMatrix));
    xticks([1.5:47.5])
    xticklabels(ManualFeatureNames);
    xtickangle(90)
    title(['Partial Max Normed per Sign ',ConcentrationCell{1,CurrentWell}])
    colorbar
    
    
end

%% Supplementary Figure 8C

% Assembled in Adobe Illustrator; ai. can be shared - Raw plots used are generated by the following

load('Z:\bkramer\190218_184A1_EGF\Data_Analysis\CleanCode\Data_2.mat')

% pERK/pS6

FeatureSet = [1,7,14,26,19,31,35,37,69,74,80];
%FeatureSet = 1:85;
ResponseStain = [26,29];

ReducedFeatureData = real(log2(CleanFeatureData(:,FeatureSet)));
ReducedResponseData = CleanResponseDataLog(:,ResponseStain);

DiscretizedLogResponse = zeros(size(ReducedResponseData));

for CurrentWell = 1:36
    for CurrentResponse = 1:size(ReducedResponseData,2)
        WellIndex = find(ismember(C_linx_clean,CurrentWell));
        CurrentData = ReducedResponseData(WellIndex,CurrentResponse);
        LowerBound = prctile(CurrentData,0.25);
        UpperBound = prctile(CurrentData,99.75);
        Edges = linspace(LowerBound,UpperBound,101);
        [Y,~] = discretize(CurrentData,Edges);
        NaNValues = find(isnan(Y));
        NaNResponseValues = CurrentData(NaNValues,:);
        LowerValues = find(NaNResponseValues < LowerBound);
        UpperValues = find(NaNResponseValues > UpperBound);
        NaNResponseValues(LowerValues,:) = 1;
        NaNResponseValues(UpperValues,:) = 100;
        Y(NaNValues,:) = NaNResponseValues;
        DiscretizedLogResponse(WellIndex,CurrentResponse) = Y;
           
    
    end
end


% Discretize Feature Data Individually....

DiscretizedFeatureData = zeros(size(ReducedFeatureData));

for CurrentWell = 1:36
    for CurrentResponse = 1:size(ReducedFeatureData,2)
        try
        WellIndex = find(ismember(C_linx_clean,CurrentWell));
        CurrentData = ReducedFeatureData(WellIndex,CurrentResponse);
        CurrentData(isinf(CurrentData)) = nanmedian(CurrentData);
        LowerBound = prctile(CurrentData,0.25);
        UpperBound = prctile(CurrentData,99.75);
        Edges = linspace(LowerBound,UpperBound,101);
        [Y,~] = discretize(CurrentData,Edges);
        NaNValues = find(isnan(Y));
        NaNResponseValues = CurrentData(NaNValues,:);
        LowerValues = find(NaNResponseValues < LowerBound);
        UpperValues = find(NaNResponseValues > UpperBound);
        NaNResponseValues(LowerValues,:) = 1;
        NaNResponseValues(UpperValues,:) = 100;
        Y(NaNValues,:) = NaNResponseValues;
        DiscretizedFeatureData(WellIndex,CurrentResponse) = Y;
        catch
        end
    end
end


WellGroup = {32,29,30};

RedundantInformation = zeros(3,size(DiscretizedFeatureData,2));
UniqueInformation = zeros(3,size(DiscretizedFeatureData,2));
SynergyInformation = zeros(3,size(DiscretizedFeatureData,2));

for CurrentWell = 1:size(WellGroup,2)
    WellIndex = find(ismember(C_linx_clean,WellGroup{1,CurrentWell}));
    for CurrentFeature = 1:size(DiscretizedFeatureData,2)
        CalculationMatrix = quickPID(DiscretizedFeatureData(WellIndex,CurrentFeature)',DiscretizedLogResponse(WellIndex,1)',DiscretizedLogResponse(WellIndex,2)','nBins',10);        
        %RedundantInformation(CurrentWell,CurrentFeature) = CalculationMatrix(1)./sum([CalculationMatrix(2),CalculationMatrix(3)]);
        %RedundantInformation(CurrentWell,CurrentFeature) = CalculationMatrix(1)./CalculationMatrix(2);
        RedundantInformation(CurrentWell,CurrentFeature) = CalculationMatrix(1);
        UniqueInformation(CurrentWell,CurrentFeature) = sum(CalculationMatrix(2:3));
        SynergyInformation(CurrentWell,CurrentFeature) = CalculationMatrix(4);
    end
end


% FoxO3a/pAKT

FeatureSet = [1,7,14,26,19,31,35,37,69,74,80];
%FeatureSet = 1:85;
ResponseStain = [1,27];

ReducedFeatureData = real(log2(CleanFeatureData(:,FeatureSet)));
ReducedResponseData = CleanResponseDataLog(:,ResponseStain);

DiscretizedLogResponse = zeros(size(ReducedResponseData));

for CurrentWell = 1:36
    for CurrentResponse = 1:size(ReducedResponseData,2)
        WellIndex = find(ismember(C_linx_clean,CurrentWell));
        CurrentData = ReducedResponseData(WellIndex,CurrentResponse);
        LowerBound = prctile(CurrentData,0.25);
        UpperBound = prctile(CurrentData,99.75);
        Edges = linspace(LowerBound,UpperBound,101);
        [Y,~] = discretize(CurrentData,Edges);
        NaNValues = find(isnan(Y));
        NaNResponseValues = CurrentData(NaNValues,:);
        LowerValues = find(NaNResponseValues < LowerBound);
        UpperValues = find(NaNResponseValues > UpperBound);
        NaNResponseValues(LowerValues,:) = 1;
        NaNResponseValues(UpperValues,:) = 100;
        Y(NaNValues,:) = NaNResponseValues;
        DiscretizedLogResponse(WellIndex,CurrentResponse) = Y;
           
    
    end
end


% Discretize Feature Data Individually....

DiscretizedFeatureData = zeros(size(ReducedFeatureData));

for CurrentWell = 1:36
    for CurrentResponse = 1:size(ReducedFeatureData,2)
        try
        WellIndex = find(ismember(C_linx_clean,CurrentWell));
        CurrentData = ReducedFeatureData(WellIndex,CurrentResponse);
        CurrentData(isinf(CurrentData)) = nanmedian(CurrentData);
        LowerBound = prctile(CurrentData,0.25);
        UpperBound = prctile(CurrentData,99.75);
        Edges = linspace(LowerBound,UpperBound,101);
        [Y,~] = discretize(CurrentData,Edges);
        NaNValues = find(isnan(Y));
        NaNResponseValues = CurrentData(NaNValues,:);
        LowerValues = find(NaNResponseValues < LowerBound);
        UpperValues = find(NaNResponseValues > UpperBound);
        NaNResponseValues(LowerValues,:) = 1;
        NaNResponseValues(UpperValues,:) = 100;
        Y(NaNValues,:) = NaNResponseValues;
        DiscretizedFeatureData(WellIndex,CurrentResponse) = Y;
        catch
        end
    end
end



WellGroup = {32,29,30};

RedundantInformation = zeros(3,size(DiscretizedFeatureData,2));
UniqueInformation = zeros(3,size(DiscretizedFeatureData,2));

for CurrentWell = 1:size(WellGroup,2)
    WellIndex = find(ismember(C_linx_clean,WellGroup{1,CurrentWell}));
    for CurrentFeature = 1:size(DiscretizedFeatureData,2)
        CalculationMatrix = quickPID(DiscretizedFeatureData(WellIndex,CurrentFeature)',DiscretizedLogResponse(WellIndex,1)',DiscretizedLogResponse(WellIndex,2)','nBins',10);        
        %RedundantInformation(CurrentWell,CurrentFeature) = CalculationMatrix(1)./sum([CalculationMatrix(2),CalculationMatrix(3)]);
        %RedundantInformation(CurrentWell,CurrentFeature) = CalculationMatrix(1)./CalculationMatrix(2);
        RedundantInformation(CurrentWell,CurrentFeature) = CalculationMatrix(1);
        UniqueInformation(CurrentWell,CurrentFeature) = sum(CalculationMatrix(2:3));
    end
end

%% Supplementary Figure 8D

% Assembled in Adobe Illustrator; ai. can be shared - Raw plots used are generated by the following

load('Z:\bkramer\190218_184A1_EGF\Data_Analysis\CleanCode\Data_2.mat')

ColorSet = brewermap(9,'Set1');
LoopIndex = 1;
figure
hold on
EVAL = [0:0.05:8];
for CurrentWell = [32,30]
    
    WellIndex = find(ismember(C_linx_clean,CurrentWell));
    Density = ksdensity(CleanResponseDataLog(WellIndex,1),EVAL);
    plot(EVAL,Density)
    
    LoopIndex = LoopIndex + 1;
end

%% Supplementary Figure 8E

% Assembled in Adobe Illustrator; ai. can be shared - Raw plots used are generated by the following

load('Z:\bkramer\190218_184A1_EGF\Data_Analysis\CleanCode\Data_2.mat')

CorrelationStorage = zeros(4,4);
InsertIndex = 1;
for CurrentWell = [10,14,19,23,28,32]
    WellIndex = find(ismember(C_linx_clean,CurrentWell));
    CorrelationStorage(InsertIndex,3) = corr(CleanResponseDataLog(WellIndex,1),CleanResponseDataLog(WellIndex,11));
    CorrelationStorage(InsertIndex,1) = corr(CleanResponseDataLog(WellIndex,1),CleanFeatureDataZ(WellIndex,14));
    WellIndex = find(ismember(C_linx_clean,CurrentWell+2));
    CorrelationStorage(InsertIndex,4) = corr(CleanResponseDataLog(WellIndex,1),CleanResponseDataLog(WellIndex,11));
    CorrelationStorage(InsertIndex,2) = corr(CleanResponseDataLog(WellIndex,1),CleanFeatureDataZ(WellIndex,14));
    InsertIndex = InsertIndex + 1;
end

BoxPosition = [1,2,4,5];
figure
boxplot(CorrelationStorage,'widths',0.65,'positions',BoxPosition);
ylim([0 0.5])




CorrelationStorage = zeros(4,2);
InsertIndex = 1;
for CurrentWell = [10,14,19,23,28,32];
    WellIndex = find(ismember(C_linx_clean,CurrentWell));
    CorrelationStorage(InsertIndex,1) = abs(partialcorr(CleanResponseDataLog(WellIndex,23),CleanResponseDataLog(WellIndex,29),CleanResponseDataLog(WellIndex,27)));
    CorrelationStorage(InsertIndex,2) = abs(partialcorr(CleanResponseDataLog(WellIndex,23),CleanResponseDataLog(WellIndex,27),CleanResponseDataLog(WellIndex,29)));
    
    InsertIndex = InsertIndex + 1;
end

figure
boxplot(CorrelationStorage);
xticklabels({'pERK','pAKT'});
ylabel('Partial Correlation FoxO3a')



% Correlation FOxO3a cell Cycle


PartialCorrStorageFoxO3 = zeros(2,1);


WellStorage = [32,30];

for CurrentWell = 1:size(WellStorage,2)
    WellIndex = find(ismember(C_linx_clean,WellStorage(CurrentWell)));
    for CurrentFeature = 14
        PartialCorr = corr(CleanResponseDataLog(WellIndex,1),CleanFeatureDataZ(WellIndex,CurrentFeature));
        PartialCorrStorageFoxO3(CurrentWell,1) = PartialCorr;    
    end
end


figure
imagesc(PartialCorrStorageFoxO3)
caxis([0 0.4])
colormap(sqrt(brewermap(500,'reds')))
axis image
colorbar



PartialCorrStorageFoxO3 = zeros(2,1);


WellStorage = [32,30];

for CurrentWell = 1:size(WellStorage,2)
    WellIndex = find(ismember(C_linx_clean,WellStorage(CurrentWell)));
    for CurrentFeature = 14
        PartialCorr = corr(CleanResponseDataLog(WellIndex,1),CleanResponseDataLog(WellIndex,11));
        PartialCorrStorageFoxO3(CurrentWell,1) = PartialCorr;    
    end
end


figure
imagesc(PartialCorrStorageFoxO3)
caxis([0 0.4])
colormap(sqrt(brewermap(500,'reds')))
axis image
colorbar
