function [anomalyScores, YTest, labels] = detectWithCML(options, Mdl, XTest, YTest, labels)
%DETECTWITHCML
%
% Runs the detection for classic ML models and returns anomaly Scores

% Fraction of outliers
if ~isempty(labels)
    numOfAnoms = sum(labels == 1);
    contaminationFraction = numOfAnoms / size(labels, 1);
else
    contaminationFraction = 0;
end

switch options.model
    case 'iForest'
        [~, anomalyScores] = isanomaly(Mdl, XTest);
    case 'OC-SVM'
        [~, anomalyScores] = predict(Mdl, XTest);
        anomalyScores = gnegate(anomalyScores);
        minScore = min(anomalyScores);
        anomalyScores = (anomalyScores - minScore) / (max(anomalyScores) - minScore);
    case 'ABOD'
        [~, anomalyScores] = ABOD(XTest);
    case 'LOF'
        [~, anomalyScores] = LOF(XTest, options.hyperparameters.model.k.value);        
    case 'Merlin'
        numAnoms = 0;
        i = 1;
        while i <= length(labels)
            if labels(i) == 1
                k = 0;
                while labels(k + i) == 1
                    k = k + 1;
                    if (k + i) > length(labels)
                        break;
                    end
                end
                i = i + k;
                numAnoms = numAnoms + 1;
            end
            i = i + 1;
        end
        if numAnoms == 0
            numAnoms = 1;
        end

        if options.hyperparameters.model.minL.value < options.hyperparameters.model.maxL.value
            anomalyScores = run_MERLIN(XTest,  options.hyperparameters.model.minL.value, ...
                options.hyperparameters.model.maxL.value, numAnoms);
        else
            anomalyScores = zeros(size(XTest, 1), 1);
        end
        anomalyScores = double(anomalyScores);
        return;
    case 'LDOF'
        anomalyScores = LDOF(XTest, options.hyperparameters.model.k.value);
end

anomalyScores = repmat(anomalyScores, 1, options.hyperparameters.data.windowSize.value);
anomalyScores = reshapeReconstructivePrediction(anomalyScores, options.hyperparameters.data.windowSize.value);
labels = labels(1:(end - options.hyperparameters.data.windowSize.value), 1);
YTest = YTest(1:(end - options.hyperparameters.data.windowSize.value), 1);
end
