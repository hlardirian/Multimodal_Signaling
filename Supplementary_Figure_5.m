%% load data 
%load('C:\Paper_Data\WorkingData_7_2.mat');
load('Z:\bkramer\190218_184A1_EGF\Data_Analysis\CleanCode\Data_1.mat')
addpath(genpath('Z:\bkramer\190218_184A1_EGF\Data_Analysis\CleanCode\'));
javaaddpath('Z:\bkramer\190218_184A1_EGF\Data_Analysis\CleanCode\Functions\umapFileExchange (1.2.1)\umap\umap.jar');
load('Z:\bkramer\190218_184A1_EGF\Processed_Data\CubeHelixLong.mat');
load('Z:\bkramer\190218_184A1_EGF\Processed_Data\gistColorMap.mat');

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


%% Supplementary Figure 5A

% Assembled in Adobe Illustrar; ai. can be shared - Raw plots used are generated by the following

WellGroups = {[13,14,15],[10,19,20],[9,8,7],[6,5,4],[3,2,1]};
FavoriteStains = [18,168,3,123,153,108,33,91,61,78];

StorageModelCoeff = zeros(50,143);
InsertIndex = 1;
for CurrentStainIndex = 1:size(FavoriteStains,2)    
    for CurrentWellIndex = 1:size(WellGroups,2)
        WellIndex = find(ismember(LinearIndex,WellGroups{1,CurrentWellIndex}));
        WellResponseData = LogResponseData(WellIndex,FavoriteStains(1,CurrentStainIndex));
        WellFeatureData = zscore(PCFeatureData(WellIndex,:));
        MDL = cvglmnet(WellFeatureData,WellResponseData);
        ModelCoeffs = cvglmnetCoef(MDL);
        ModelCoeffs(1) = [];
        StorageModelCoeff(InsertIndex,:) = ModelCoeffs;
        InsertIndex = InsertIndex + 1;
    end
end


% Similarity matrix

FeatureCorrelation = zeros(size(StorageModelCoeff,1),size(StorageModelCoeff,1));

for CurrentFeature = 1:size(StorageModelCoeff,1)
    for CurrentCounterFeature = 1:size(StorageModelCoeff,1)
        FeatureCorrelation(CurrentFeature,CurrentCounterFeature) = getCosineSimilarity(StorageModelCoeff(CurrentFeature,:),StorageModelCoeff(CurrentCounterFeature,:));
    end
end

PlotMatrix = [flipud(FeatureCorrelation),zeros(50,1)];
PlotMatrix = [PlotMatrix;zeros(1,51)];

figure
pcolor(PlotMatrix)
caxis([0 1])
axis square


% TSNE GRAPH %

% EVERY TSNE RUN WILL DIFFER!!!! %

SNE = tsne(StorageModelCoeff',[],2,[],5);

figure
hold on


% FeatureCorrelation = zeros(size(StorageModelCoeff,2),size(StorageModelCoeff,2));
% 
% for CurrentFeature = 1:size(StorageModelCoeff,2)
%     for CurrentCounterFeature = 1:size(StorageModelCoeff,2)
%         FeatureCorrelation(CurrentFeature,CurrentCounterFeature) = getCosineSimilarity(StorageModelCoeff(:,CurrentFeature),StorageModelCoeff(:,CurrentCounterFeature));
%     end
% end

%FeatureCorrelation = zeros(size(StorageModelCoeff,2),size(StorageModelCoeff,2));

%FeatureCorrelation = corr(StorageModelCoeff,'Type','Spearman');
FeatureCorrelation = pdist2(StorageModelCoeff',StorageModelCoeff');


UpperTri = triu(FeatureCorrelation);

[row,column] = find(UpperTri);

for CurrentLine = 1:size(row,1)
    CurrentValue = UpperTri(row(CurrentLine),(column(CurrentLine)));
    if CurrentValue <0.25
        line([TSNE(row(CurrentLine),1),TSNE(column(CurrentLine),1)],[TSNE(row(CurrentLine),2),TSNE(column(CurrentLine),2)],'Color','k','LineWidth',0.2)
%      else
%          line([TSNE(row(CurrentLine),1),TSNE(column(CurrentLine),1)],[TSNE(row(CurrentLine),2),TSNE(column(CurrentLine),2)],'Color',[0.9 0.9 0.9],'LineWidth',0.2)
    end
end

scatter(TSNE(:,1),TSNE(:,2),130,repmat([1:5]',10,1),'filled','MarkerEdgeColor','k')
ColorMap = flipud([hex2rgb('984EA3');hex2rgb('E41A1C');hex2rgb('FF7F00');hex2rgb('4DAF4A');hex2rgb('377EB8')]);
colormap(ColorMap);
axis square

TakeIndex = 1;
for CurrentStain = 1:10
    CurrentSNE = TSNE(TakeIndex:TakeIndex+4,:);
    for CurrentPoint = 1:5
        text(CurrentSNE(CurrentPoint,1),CurrentSNE(CurrentPoint,2),num2str(CurrentStain),'HorizontalAlignment','center');
    
    
    end
    TakeIndex = TakeIndex + 5;
end

axis square


%% Supplementary Figure 5B

% Assembled in Adobe Illustrar; ai. can be shared - Raw plots used are generated by the following

WellGroups = {[13,14,15],[10,19,20],[9,8,7],[6,5,4],[3,2,1]};
FavoriteStains = [18,168,3,123,153,108,33,91,61,78];

StorageStain = cell(10,1);

for CurrentStainIndex = 1:size(FavoriteStains,2)
    StorageCross = zeros(5,5);
    for CurrentWellIndex = 1:size(WellGroups,2)
        WellIndex = find(ismember(LinearIndex,WellGroups{1,CurrentWellIndex}));
        WellResponseData = LogResponseData(WellIndex,FavoriteStains(1,CurrentStainIndex));
        WellFeatureData = PCFeatureData(WellIndex,:);
        MDL = cvglmnet(WellFeatureData,WellResponseData);
        for CurrentCounterWell = 1:size(WellGroups,2)
            CounterWellIndex = find(ismember(LinearIndex,WellGroups{1,CurrentCounterWell}));
            CounterFeatureData = PCFeatureData(CounterWellIndex,:);
            CounterResponseData = LogResponseData(CounterWellIndex,FavoriteStains(1,CurrentStainIndex));
            Prediction = cvglmnetPredict(MDL,CounterFeatureData);
            StorageCross(CurrentWellIndex,CurrentCounterWell) = corr(Prediction,CounterResponseData).^2;
        end
    end
    StorageStain{CurrentStainIndex,1} = StorageCross;
end


figure
hold on

for CurrentStain = 1:10
    CurrentR2 = StorageStain{CurrentStain,1};
    Diagonal = diag(CurrentR2);
    scatter(Diagonal,CurrentR2(5,1:5),60,1:5,'filled','MarkerEdgeColor','none');
end

xlim([0 1])
ylim([0 1])
line([0 1],[0 1],'Color','k')
axis square

ColorMap = flipud([hex2rgb('984EA3');hex2rgb('E41A1C');hex2rgb('FF7F00');hex2rgb('4DAF4A');hex2rgb('377EB8')]);
colormap(ColorMap);

figure
hold on

for CurrentStain = 1:10
    CurrentR2 = StorageStain{CurrentStain,1};
    Diagonal = diag(CurrentR2);
    scatter(Diagonal,CurrentR2(1,1:5),60,1:5,'filled','MarkerEdgeColor','none'); 
end

xlim([0 1])
ylim([0 1])
line([0 1],[0 1],'Color','k')
axis square

ColorMap = flipud([hex2rgb('984EA3');hex2rgb('E41A1C');hex2rgb('FF7F00');hex2rgb('4DAF4A');hex2rgb('377EB8')]);
colormap(ColorMap);
