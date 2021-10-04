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

%% Supplementary Figure 3A and B

% Assembled in Adobe Illustrator; ai. can be shared; Raw plots used are generated by the following

%Bar Explained Variance Across doses

WellBatches = {[13,14,15];[10,20,19];[7,8,9];[4,5,6];[1,2,3]};
ResponseStain = [18,168,3,123,153,108,33,61,91,78];%[3,123,108];

Eval = [-4:0.01:4];

for ResponseCounter = 1:size(ResponseStain,2)
    
    SameTComp = zeros(5,2);
    DifferentTComp = zeros(5,2);
    
    for CurrentWellCounter = 1:size(WellBatches,1)
        CurrentWell = WellBatches{CurrentWellCounter,1};
        WellIndex = find(ismember(LinearIndex,CurrentWell));
        CurrentResponse = ResponseStain(ResponseCounter);
        CurrentResponseData = zscore(LogResponseData(WellIndex,CurrentResponse));
        
        figure
        plot(Eval,ksdensity(CurrentResponseData,Eval))
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\OriginalDensity_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.pdf'];
%         export_fig(ExportPath,'-painters')
        
        
        
        InsertIndex = 1;
        CurrentResponse = ResponseStain(ResponseCounter);
        OtherResponse = setdiff(ResponseStain,CurrentResponse);
        CurrentIndependentData = PCFeatureData(WellIndex,:);
        CurrentResponseData = zscore(LogResponseData(WellIndex,CurrentResponse));
        MDL = fitrtree(CurrentIndependentData,CurrentResponseData,'crossval','on');
        Prediction = kfoldPredict(MDL);
        Residuals = CurrentResponseData - Prediction;
        SSE = sum(Residuals.^2);
        MSE = SSE/(numel(Residuals)-2);
        RSE = sqrt(MSE);
        
        DifferentTComp(CurrentWellCounter,2) = RSE;
  
        CurrentFeatureData = CurrentResponseData;
        
        
        
        % Quantile Normalizing....
        
        CurrentNormData = Prediction;
%         Iterations = 20;
%         
%         for CurrentIteration = 1:Iterations
%             NormedData = quantilenorm([CurrentFeatureData,CurrentNormData]);
%             CurrentNormData = NormedData(:,2);
%         end
%         
        WellPredictionData = CurrentNormData;
        
        % Sort Feature Data...
        
        [SortedFeatureData,SortIndex] = sort(CurrentFeatureData,'ascend');
        SortedPredictionData = WellPredictionData(SortIndex,:);
        
%         fitresult = fit(SortedFeatureData,SortedPredictionData,'poly1');
%         p22 = predint(fitresult, SortedFeatureData,0.95,'observation','off');
        
        figure
        S = scatter(SortedFeatureData,SortedPredictionData,4,'o','filled','MarkerFaceColor','k','MarkerEdgeColor','none');
        S.MarkerFaceAlpha = 0.05;
%         hold on
%         plot(fitresult)
%         hold on
%         plot(SortedFeatureData,p22,'m--')
%         axis equal
        xlim([-4 4])
        ylim([-4 4])
        legend off
        %h = normplot_mod(Residuals(randperm(size(Residuals,1),500)));
        
        %h(1).Color(4) = 0.15;
        %         h(1).MarkerFaceColor = 'k';
        %         h(1). MarkerSize = 2;
        axis square
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Measured_Predicted_RF_CV_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.pdf'];
%         export_fig(ExportPath,'-painters')
        InsertIndex = InsertIndex + InsertIndex + 1;
        set(gca,'YTickLabel',[]);
        set(gca,'XTickLabel',[]);
        ylabel('');
        xlabel('');
        title('')
        
        %close all
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Measured_Predicted_IM_RF_CV_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.png'];
%         export_fig(ExportPath,'-r1200')
%         close all
        
        
        
        
        
        CurrentResponse = ResponseStain(ResponseCounter);
        OtherResponse = setdiff(ResponseStain,CurrentResponse);
        CurrentIndependentData = PCFeatureData(WellIndex,:);
        CurrentResponseData = zscore(LogResponseData(WellIndex,CurrentResponse));
        MDL = fitrtree(CurrentIndependentData,CurrentResponseData);
        Prediction = predict(MDL,CurrentIndependentData);
        Residuals = CurrentResponseData - Prediction;
        SSE = sum(Residuals.^2);
        MSE = SSE/(numel(Residuals)-2);
        RSE = sqrt(MSE);
        
        SameTComp(CurrentWellCounter,2) = RSE;
        
        CurrentFeatureData = CurrentResponseData;
        
        
        % Quantile Normalizing....
        
        CurrentNormData = Prediction;
%         Iterations = 20;
%         
%         for CurrentIteration = 1:Iterations
%             NormedData = quantilenorm([CurrentFeatureData,CurrentNormData]);
%             CurrentNormData = NormedData(:,2);
%         end
        
        WellPredictionData = CurrentNormData;
        
        % Sort Feature Data...
        
        [SortedFeatureData,SortIndex] = sort(CurrentFeatureData,'ascend');
        SortedPredictionData = WellPredictionData(SortIndex,:);
        
%         fitresult = fit(SortedFeatureData,SortedPredictionData,'poly1');
%         p22 = predint(fitresult, SortedFeatureData,0.95,'observation','off');
        
        figure
        S = scatter(SortedFeatureData,SortedPredictionData,4,'o','filled','MarkerFaceColor','k','MarkerEdgeColor','none');
        S.MarkerFaceAlpha = 0.05;
%         hold on
%         plot(fitresult)
%         hold on
%         plot(SortedFeatureData,p22,'m--')
%         axis equal
        xlim([-4 4])
        ylim([-4 4])
        legend off
        %h = normplot_mod(Residuals(randperm(size(Residuals,1),500)));
        
        %h(1).Color(4) = 0.15;
        %         h(1).MarkerFaceColor = 'k';
        %         h(1). MarkerSize = 2;
        axis square
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Measured_Predicted_RF_NoCV_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.pdf'];
%         export_fig(ExportPath,'-painters')
        InsertIndex = InsertIndex + InsertIndex + 1;
        set(gca,'YTickLabel',[]);
        set(gca,'XTickLabel',[]);
        ylabel('');
        xlabel('');
        title('')
        
        %close all
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Measured_Predicted_IM_RF_NoCV_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.png'];
%         export_fig(ExportPath,'-r1200')
%         close all
        
        
               
        
        MDL = cvglmnet(CurrentIndependentData,CurrentResponseData);
        Prediction = cvglmnetPredict(MDL,CurrentIndependentData);
        Residuals = CurrentResponseData - Prediction;
        SSE = sum(Residuals.^2);
        MSE = SSE/(numel(Residuals)-2);
        RSE = sqrt(MSE);
        
        DifferentTComp(CurrentWellCounter,1) = RSE;
        
        

             
        CurrentFeatureData = CurrentResponseData;
        
        
        % Quantile Normalizing....
        
        CurrentNormData = Prediction;
%         Iterations = 20;
%         
%         for CurrentIteration = 1:Iterations
%             NormedData = quantilenorm([CurrentFeatureData,CurrentNormData]);
%             CurrentNormData = NormedData(:,2);
%         end
        
        WellPredictionData = CurrentNormData;
        
        % Sort Feature Data...
        
        [SortedFeatureData,SortIndex] = sort(CurrentFeatureData,'ascend');
        SortedPredictionData = WellPredictionData(SortIndex,:);
%         
%         fitresult = fit(SortedFeatureData,SortedPredictionData,'poly1');
%         p22 = predint(fitresult, SortedFeatureData,0.95,'observation','off');
        
        figure
        S = scatter(SortedFeatureData,SortedPredictionData,4,'o','filled','MarkerFaceColor','k','MarkerEdgeColor','none');
        S.MarkerFaceAlpha = 0.05;
%         hold on
%         plot(fitresult)
%         hold on
%         plot(SortedFeatureData,p22,'m--')
%         axis equal
        xlim([-4 4])
        ylim([-4 4])
        legend off
        %h = normplot_mod(Residuals(randperm(size(Residuals,1),500)));
        
        %h(1).Color(4) = 0.15;
        %         h(1).MarkerFaceColor = 'k';
        %         h(1). MarkerSize = 2;
        axis square
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Measured_Predicted_MLR_CV_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.pdf'];
%         export_fig(ExportPath,'-painters')
        InsertIndex = InsertIndex + InsertIndex + 1;
        set(gca,'YTickLabel',[]);
        set(gca,'XTickLabel',[]);
        ylabel('');
        xlabel('');
        title('')
        
        %close all
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Measured_Predicted_IM_MLR_CV_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.png'];
%         export_fig(ExportPath,'-r1200')
%         close all
        
        
        
        MDL = fitlm(CurrentIndependentData,CurrentResponseData);
        Prediction = predict(MDL,CurrentIndependentData);
        Residuals = CurrentResponseData - Prediction;
        SSE = sum(Residuals.^2);
        MSE = SSE/(numel(Residuals)-2);
        RSE = sqrt(MSE);
        
        SameTComp(CurrentWellCounter,1) = RSE;
        

             
        CurrentFeatureData = CurrentResponseData;
        
        
        % Quantile Normalizing....
        
        CurrentNormData = Prediction;
%         Iterations = 20;
%         
%         for CurrentIteration = 1:Iterations
%             NormedData = quantilenorm([CurrentFeatureData,CurrentNormData]);
%             CurrentNormData = NormedData(:,2);
%         end
        
        WellPredictionData = CurrentNormData;
        
        % Sort Feature Data...
        
        [SortedFeatureData,SortIndex] = sort(CurrentFeatureData,'ascend');
        SortedPredictionData = WellPredictionData(SortIndex,:);
%         
%         fitresult = fit(SortedFeatureData,SortedPredictionData,'poly1');
%         p22 = predint(fitresult, SortedFeatureData,0.95,'observation','off');
        
        figure
        S = scatter(SortedFeatureData,SortedPredictionData,4,'o','filled','MarkerFaceColor','k','MarkerEdgeColor','none');
        S.MarkerFaceAlpha = 0.05;
%         hold on
%         plot(fitresult)
%         hold on
%         plot(SortedFeatureData,p22,'m--')
%         axis equal
        xlim([-4 4])
        ylim([-4 4])
        legend off
        %h = normplot_mod(Residuals(randperm(size(Residuals,1),500)));
        
        %h(1).Color(4) = 0.15;
        %         h(1).MarkerFaceColor = 'k';
        %         h(1). MarkerSize = 2;
        axis square
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Measured_Predicted_MLR_NoCV_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.pdf'];
%         export_fig(ExportPath,'-painters')
        InsertIndex = InsertIndex + InsertIndex + 1;
        set(gca,'YTickLabel',[]);
        set(gca,'XTickLabel',[]);
        ylabel('');
        xlabel('');
        title('')
        
        %close all
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Measured_Predicted_IM_MLR_NoCV_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.png'];
%         export_fig(ExportPath,'-r1200')
%         close all
                     
    end
    %Same Training
        PlotStorage = [flipud(SameTComp);zeros(1,2)];
        PlotStorage = [PlotStorage,zeros(6,1)];
        figure
        pcolor(PlotStorage);
        caxis([0 1.5])
        axis image
        %CustomColormap = sqrt(sqrt(brewermap(500,'YlOrRd')));
        CustomColormap = hot(500);
        CustomColormap = [CustomColormap];
        colormap(flipud(CustomColormap))
        colorbar
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\ModelComparison_SameT_',num2str(ResponseCounter),'.pdf'];
%         export_fig(ExportPath,'-painters')
        
        % Same Training
        PlotStorage = [flipud(DifferentTComp);zeros(1,2)];
        PlotStorage = [PlotStorage,zeros(6,1)];
        figure
        pcolor(PlotStorage);
        caxis([0 1.5])
        axis image
        %CustomColormap = sqrt(sqrt(brewermap(500,'YlOrRd')));
        CustomColormap = hot(500);
        CustomColormap = [CustomColormap];
        colormap(flipud(CustomColormap))
        colorbar
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\ModelComparison_DifferentT_',num2str(ResponseCounter),'.pdf'];
%         export_fig(ExportPath,'-painters')
    ResponseCounter
%     close all
end


%% Supplementary Figure 3C and D

% Assembled in Adobe Illustrator; ai. can be shared; Raw plots used are generated by the following


WellBatches = {[13,14,15];[10,20,19];[7,8,9];[4,5,6];[1,2,3]};
ResponseStain = [18,168,3,123,153,108,33,61,91,78];%[3,123,108];
ExplainedVariance = zeros(5,size(ResponseStain,2));
Eval = [-4:0.025:4];

LikelihoodStorageCell = cell(5,10);
NumberObversations = zeros(5,10);

for CurrentWellCounter = 1:size(WellBatches,1)
    
    for ResponseCounter = 1:size(ResponseStain,2)
        
        
        CurrentWell = WellBatches{CurrentWellCounter,1};
        WellIndex = find(ismember(LinearIndex,CurrentWell));
        InsertIndex = 1;
        CurrentResponse = ResponseStain(ResponseCounter);
        OtherResponse = setdiff(ResponseStain,CurrentResponse);
        CurrentIndependentData = PCFeatureData(WellIndex,:);
        CurrentResponseData = zscore(LogResponseData(WellIndex,CurrentResponse));
        MDL = cvglmnet(CurrentIndependentData,CurrentResponseData);
        Prediction = cvglmnetPredict(MDL,CurrentIndependentData);
        
        % Outlierdeletion....
        IndexA = find(abs(Prediction) > 4);
        IndexB = find(abs(CurrentResponseData) > 4);
        
        DeleteIndex = unique([IndexA;IndexB]);
        
        Prediction(DeleteIndex) = [];
        CurrentResponseData(DeleteIndex) = [];
        
        % Points above or below...
        
        %IndexExclude = find(abs(CurrentResponseData) > 2);
        
        
        EvaluatePoints = [-2.7:0.05:2.7];
        
        figure
        S = scatter(CurrentResponseData,Prediction,4,'o','filled','MarkerFaceColor','k','MarkerEdgeColor','none');
        S.MarkerFaceAlpha = 0.05;
        hold on
        [SplineFit,FitGoodness,FitOutput] = fit(CurrentResponseData,Prediction,'poly4','Robust','LAR');
        GoodnessSave = FitGoodness;
        EvalPoly = SplineFit(EvaluatePoints);
        plot(EvaluatePoints,EvalPoly,'b--','LineWidth',2);
        [SplineFit,FitGoodness,FitOutput] = fit(CurrentResponseData,Prediction,'poly1','Robust','LAR');
        EvalPoly = SplineFit(EvaluatePoints);
        plot(EvaluatePoints,EvalPoly,'r--','LineWidth',2);
        ylim([-4 4])
        xlim([-4 4])
        axis square
        legend off
        
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Measured_Predicted_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.pdf'];
%         export_fig(ExportPath,'-painters')
        InsertIndex = InsertIndex + InsertIndex + 1;
        set(gca,'YTickLabel',[]);
        set(gca,'XTickLabel',[]);
        ylabel('');
        xlabel('');
        title('')
        
        %close all
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Measured_Predicted_IM_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.png'];
%         export_fig(ExportPath,'-r1200')
        close all
        
        LikelihoodStorage = zeros(4,1);
        
        [~,~,FitOutput] = fit(CurrentResponseData,Prediction,'poly4','Robust','LAR');
        Residuals = FitOutput.residuals;
        SquaredR = (Residuals.^2)*-1;
        LikelihoodStorage(4,1) = sum(SquaredR);
        
        [~,~,FitOutput] = fit(CurrentResponseData,Prediction,'poly3','Robust','LAR');
        Residuals = FitOutput.residuals;
        SquaredR = (Residuals.^2)*-1;
        LikelihoodStorage(3,1) = sum(SquaredR);
        
        [~,~,FitOutput] = fit(CurrentResponseData,Prediction,'poly2','Robust','LAR');
        Residuals = FitOutput.residuals;
        SquaredR = (Residuals.^2)*-1;
        LikelihoodStorage(2,1) = sum(SquaredR);
        
        [~,~,FitOutput] = fit(CurrentResponseData,Prediction,'poly1','Robust','LAR');
        Residuals = FitOutput.residuals;
        SquaredR = (Residuals.^2)*-1;
        LikelihoodStorage(1,1) = sum(SquaredR);
        
        LikelihoodStorageCell{CurrentWellCounter,ResponseCounter} = LikelihoodStorage;
        
        NumberObservations(CurrentWellCounter,ResponseCounter) = numel(WellIndex);
        
    end
    CurrentWellCounter
end


for CurrentResponse = 1:10
    figure
    LikelihoodRatio = zeros(5,4);
    for CurrentWell = 1:5
        CurrentLikelihood = abs(LikelihoodStorageCell{CurrentWell,CurrentResponse});
        LikelihoodRatio(CurrentWell,1) = CurrentLikelihood(1,1)/CurrentLikelihood(1,1);
        LikelihoodRatio(CurrentWell,2) = CurrentLikelihood(1,1)/CurrentLikelihood(2,1);
        LikelihoodRatio(CurrentWell,3) = CurrentLikelihood(1,1)/CurrentLikelihood(3,1);
        LikelihoodRatio(CurrentWell,4) = CurrentLikelihood(1,1)/CurrentLikelihood(4,1);
    end
    PlotStorage = [flipud(LikelihoodRatio),zeros(5,1);zeros(1,5)];
    pcolor(PlotStorage)
    axis image
    colormap(brewermap(500,'blues'))
    caxis([1 2])
    colorbar
%     ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Likelihood_LinearDependencies\MLR_LL_',num2str(CurrentResponse),'.pdf'];
%     export_fig(ExportPath,'-painters')
    
    close all
end


%% Supplementary Figure 3E

WellBatches = {[13,14,15];[10,20,19];[7,8,9];[4,5,6];[1,2,3]};
ResponseStain = [18,168,3,123,153,108,33,61,91,78];%[3,123,108];
ExplainedVariance = zeros(5,size(ResponseStain,2));
Eval = [-4:0.025:4];


for ResponseCounter = 1:size(ResponseStain,2)
    for CurrentWellCounter = 5%1:size(WellBatches,1)
        figure
        CurrentWell = WellBatches{CurrentWellCounter,1};
        WellIndex = find(ismember(LinearIndex,CurrentWell));
        InsertIndex = 1;
        CurrentResponse = ResponseStain(ResponseCounter);
        OtherResponse = setdiff(ResponseStain,CurrentResponse);
        CurrentIndependentData = PCFeatureData(WellIndex,:);
        CurrentResponseData = zscore(LogResponseData(WellIndex,CurrentResponse));
        MDL = cvglmnet(CurrentIndependentData,CurrentResponseData);
        Prediction = cvglmnetPredict(MDL,CurrentIndependentData);
        Residuals = CurrentResponseData - Prediction;
        h = normplot_mod(Residuals(randperm(size(Residuals,1),500)));
        %h = qqplot(Residuals);
%         h(1).Color(4) = 0.15;
%          h(1).MarkerFaceColor = 'k';
%          h(1). MarkerSize = 2;
        xlim([-4 4])
        axis square
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Residuals_Normality_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.pdf'];
%         export_fig(ExportPath,'-painters')
        InsertIndex = InsertIndex + InsertIndex + 1;
%         set(gca,'YTickLabel',[]);
%         set(gca,'XTickLabel',[]);
%         ylabel('');
%         xlabel('');
%         title('')
        
        %close all
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Residuals_Normality_IM_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.png'];
%         export_fig(ExportPath,'-r1200')
        %close all
        CurrentWellCounter
    end
%     legend
%     ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\NormalityResiduals_',num2str(ResponseCounter),'.pdf'];
%     export_fig(ExportPath,'-painters')
end

%% Supplementary Figure 3F

%Bar Explained Variance Across doses

WellBatches = {[13,14,15];[10,20,19];[7,8,9];[4,5,6];[1,2,3]};
%ResponseStain = [3,18,33,61,78,91,108,123,153,168];%[3,123,108];
ResponseStain = [18,168,3,123,153,108,33,61,91,78];%[3,123,108];


SampleSize = [25,50,100,150];



for ResponseCounter = 1:size(ResponseStain,2)
    
    StorageHLille = zeros(5,4);
    for CurrentWellCounter = 1:size(WellBatches,1)
        CurrentWell = WellBatches{CurrentWellCounter,1};
        WellIndex = find(ismember(LinearIndex,CurrentWell));
        CurrentResponse = ResponseStain(ResponseCounter);
        OtherResponse = setdiff(ResponseStain,CurrentResponse);
        CurrentIndependentData = PCFeatureData(WellIndex,:);
        CurrentResponseData = zscore(LogResponseData(WellIndex,CurrentResponse));
        TestData = CurrentIndependentData;
        TestResponseData = CurrentResponseData;
        MDL = cvglmnet(TestData,TestResponseData);
        Prediction = cvglmnetPredict(MDL,TestData);
        Residuals = TestResponseData - Prediction;
        %         figure
        %         scatter(Residuals,Prediction,3,'filled','MarkerFaceColor','k','MarkerFaceAlpha',0.5)
        %         InsertIndex = InsertIndex + 1;
        %         fitresult = fit(Residuals,Prediction,'poly1');
        %         p22 = predint(fitresult, Residuals,0.95,'observation','off');
        %         hold on
        %         plot(fitresult)
        % %         hold on
        % %         plot(Residuals,p22,'m--')
        %         Coefficients = coeffvalues(fitresult);
        %         Slope = Coefficients(1);
        %         text(-1.5,3,num2str(round(Slope,3)))
        %             RandomShuffle = randperm(SampleSize);
        %             TestData = [CurrentIndependentData(RandomShuffle,:),CurrentResponseData(RandomShuffle,:)];
        %             [T,P,~] = BPtest(TestData);
        
        for CurrentSampleSize = 1:size(SampleSize,2)
            MeanIteration = zeros(100,1);
            TIteration = zeros(100,1);
            HLille = zeros(100,1);
            PLille = zeros(100,1);
            for CurrentIteration = 1:100
            RandomSample = randperm(size(Residuals,1),SampleSize(CurrentSampleSize));
            aux = fitlm(TestData(RandomSample,:),Residuals(RandomSample).^2);
            n = numel(Residuals(RandomSample));
            T = aux.Rsquared.Ordinary*n;
            df = 157;
            P = 1-chi2cdf(abs(T),df);
            MeanIteration(CurrentIteration,1) = P;
            TIteration(CurrentIteration,1) = T;
            
            [HLille(CurrentIteration,1),PLille(CurrentIteration,1)] = lillietest(RandomSample,'alpha',0.01); 
            
        
            
            
            end
            StorageHLille(CurrentWellCounter,CurrentSampleSize) = mode(HLille);
            %         [SortedResiduals,SortIndex] = sort(Residuals,'ascend');
            %         SortedPrediction = Prediction(SortIndex);
            %         MovingSTD = movstd(SortedPrediction,500);
            %         hold on
            %         plot(SortedResiduals,MovingSTD);
            %         hold on
            %         plot(SortedResiduals,MovingSTD*-1)
            %         ylim([-4 4])
            %         xlim([-2.5 2.5])
            %         axis square
            %         legend off
            %         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Residuals_Prediction_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.pdf'];
            %         export_fig(ExportPath,'-painters')
            %         close all
            
        end        
    end
    PlotStorage = [flipud(StorageHLille);zeros(1,4)];
    PlotStorage = [PlotStorage,zeros(6,1)];
    figure
    pcolor(PlotStorage);
    caxis([0 1])
    axis image
    CustomColormap = brewermap(500,'reds');
    CustomColormap = [ones(20,3);CustomColormap];
    colormap(CustomColormap)
%     ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\NormalityResidualsTest_',num2str(ResponseCounter),'.pdf'];
%     export_fig(ExportPath,'-painters')
    ResponseCounter
end

%% Supplementary Figure 3G

WellBatches = {[13,14,15];[10,20,19];[7,8,9];[4,5,6];[1,2,3]};
ResponseStain = [18,168,3,123,153,108,33,61,91,78];%[3,123,108];
ExplainedVariance = zeros(5,size(ResponseStain,2));
PStorage = zeros(5,10);
TStatStorage = zeros(5,10);

for CurrentWellCounter = 1:size(WellBatches,1)
    CurrentWell = WellBatches{CurrentWellCounter,1};
    WellIndex = find(ismember(LinearIndex,CurrentWell));
    InsertIndex = 1;
    for ResponseCounter = 1:size(ResponseStain,2)
        CurrentResponse = ResponseStain(ResponseCounter);
        OtherResponse = setdiff(ResponseStain,CurrentResponse);
        CurrentIndependentData = PCFeatureData(WellIndex,:);
        CurrentResponseData = zscore(LogResponseData(WellIndex,CurrentResponse));
        MDL = cvglmnet(CurrentIndependentData,CurrentResponseData);
        Prediction = cvglmnetPredict(MDL,CurrentIndependentData);
        Residuals = CurrentResponseData - Prediction;
        figure
        scatter(Prediction,Residuals,3,'filled','MarkerFaceColor','k','MarkerFaceAlpha',0.15)
        InsertIndex = InsertIndex + 1;       
        fitresult = fit(Prediction,Residuals,'poly1');
        p22 = predint(fitresult, Prediction,0.95,'observation','off');
        hold on
        plot(fitresult);
%         hold on
%         plot(Residuals,p22,'m--')
%         Coefficients = coeffvalues(fitresult);
%         Slope = Coefficients(1);
%         text(-1.5,3,num2str(round(Slope,3)))
% %         RandomShuffle = randperm(250);
% %         [T,P,df] = BPtest([CurrentIndependentData(RandomShuffle,:),CurrentResponseData(RandomShuffle,:)]);
% %         PStorage(CurrentWellCounter,ResponseCounter) = P;
% %         TStatStorage(CurrentWellCounter,ResponseCounter) = T;
%         
%         [SortedResiduals,SortIndex] = sort(Residuals,'ascend');
%         SortedPrediction = Prediction(SortIndex);
%         MovingSTD = movstd(SortedPrediction,500);
%         hold on
%         plot(SortedResiduals,MovingSTD);
%         hold on
%         plot(SortedResiduals,MovingSTD*-1)
        xlim([-4 4])
        ylim([-4 4])
        set(gca,'YTickLabel',[]);
        set(gca,'XTickLabel',[]);
        ylabel('');
        xlabel('');
        axis square
        %axis off
        legend off
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Residuals_Prediction_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.pdf'];
%         export_fig(ExportPath,'-painters')
%         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Residuals_Prediction_IM_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.png'];
%         export_fig(ExportPath,'-r2400')
%         close all
        
    end
    CurrentWellCounter
end


%% Supplementary Figure 3H


WellBatches = {[13,14,15];[10,20,19];[7,8,9];[4,5,6];[1,2,3]};
ResponseStain = [18,168,3,123,153,108,33,61,91,78];


SampleSize = [100,200,300,400];



for ResponseCounter = 1:size(ResponseStain,2)
    
    StorageHBP = zeros(5,4);
    for CurrentWellCounter = 1:size(WellBatches,1)
        CurrentWell = WellBatches{CurrentWellCounter,1};
        WellIndex = find(ismember(LinearIndex,CurrentWell));
        CurrentResponse = ResponseStain(ResponseCounter);
        OtherResponse = setdiff(ResponseStain,CurrentResponse);
        CurrentIndependentData = PCFeatureData(WellIndex,:);
        CurrentResponseData = zscore(LogResponseData(WellIndex,CurrentResponse));
        TestData = CurrentIndependentData;
        TestResponseData = CurrentResponseData;
        MDL = cvglmnet(TestData,TestResponseData);
        Prediction = cvglmnetPredict(MDL,TestData);
        Residuals = TestResponseData - Prediction;
        %         figure
        %         scatter(Residuals,Prediction,3,'filled','MarkerFaceColor','k','MarkerFaceAlpha',0.5)
        %         InsertIndex = InsertIndex + 1;
        %         fitresult = fit(Residuals,Prediction,'poly1');
        %         p22 = predint(fitresult, Residuals,0.95,'observation','off');
        %         hold on
        %         plot(fitresult)
        % %         hold on
        % %         plot(Residuals,p22,'m--')
        %         Coefficients = coeffvalues(fitresult);
        %         Slope = Coefficients(1);
        %         text(-1.5,3,num2str(round(Slope,3)))
        %             RandomShuffle = randperm(SampleSize);
        %             TestData = [CurrentIndependentData(RandomShuffle,:),CurrentResponseData(RandomShuffle,:)];
        %             [T,P,~] = BPtest(TestData);
        
        for CurrentSampleSize = 1:size(SampleSize,2)
            MeanIteration = zeros(10,1);
            TIteration = zeros(10,1);
            HLille = zeros(10,1);
            PLille = zeros(10,1);
            for CurrentIteration = 1:10
            RandomSample = randperm(size(Residuals,1),SampleSize(CurrentSampleSize));
            aux = fitlm(TestData(RandomSample,:),Residuals(RandomSample).^2);
            n = numel(Residuals(RandomSample));
            T = aux.Rsquared.Ordinary*n;
            df = 157;
            P = 1-chi2cdf(abs(T),df);
            if P <= 0.01
              MeanIteration(CurrentIteration,1) = 1;
            else
              MeanIteration(CurrentIteration,1) = 0;
            end
            TIteration(CurrentIteration,1) = T;
            
            
        
            
            
            end
            StorageHBP(CurrentWellCounter,CurrentSampleSize) = mode(MeanIteration);
            %         [SortedResiduals,SortIndex] = sort(Residuals,'ascend');
            %         SortedPrediction = Prediction(SortIndex);
            %         MovingSTD = movstd(SortedPrediction,500);
            %         hold on
            %         plot(SortedResiduals,MovingSTD);
            %         hold on
            %         plot(SortedResiduals,MovingSTD*-1)
            %         ylim([-4 4])
            %         xlim([-2.5 2.5])
            %         axis square
            %         legend off
            %         ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Residuals_Prediction_',num2str(CurrentWellCounter),'_',num2str(ResponseCounter),'.pdf'];
            %         export_fig(ExportPath,'-painters')
            %         close all
            
        end        
    end
    PlotStorage = [flipud(StorageHBP);zeros(1,4)];
    PlotStorage = [PlotStorage,zeros(6,1)];
    figure
    pcolor(PlotStorage);
    caxis([0 1])
    axis image
    CustomColormap = brewermap(500,'reds');
    CustomColormap = [ones(20,3);CustomColormap];
    colormap(CustomColormap)
    ExportPath = ['Z:\bkramer\190218_184A1_EGF\Figures\VF\Reviewer_Figures\Heteroskedasticity_',num2str(ResponseCounter),'.pdf'];
    export_fig(ExportPath,'-painters')
    ResponseCounter
end

