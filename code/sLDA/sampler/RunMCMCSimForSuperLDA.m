% RunMCMCSimForSuperLDA
%  Generic harness for running many iterations of MCMC for standard LDA,
%   allows sensible reporting/saving of samples and diagnostics.
% USAGE
%  call implicitly from "user-facing" runLDA.m (recommended)
%    allows flexible customization of parameters, automatic data loading,
%    custom initialization, and more.
%  call directly
%    RunMCMCSimForSuperLDA(...
%        Data, Psi, algParams, outParams, model, TestData, testP)
function [ChainHist] = RunMCMCSimForSuperLDA( Data, Psi, algParams, outParams, model, TestData, testP)
tic;

% Stating chain from scratch
n = 0;
logPr = calcJointLogPr_sLDA( Psi, Data, model );
ChainHist = recordMCMCHistory_LDA( 0, outParams, [], Psi, logPr  );

fprintf( 'Initial Config: \n' );
printMCMCSummary_LDA( 0, Psi, logPr, algParams);


fprintf( 'Running MCMC Sampler %d : %d ... \n', outParams.jobID, outParams.taskID );
for n=n+1:algParams.Niter
    
    % Perform 1 iteration of MCMC, moving to next Markov state!
    [Psi] = sLDAsample( Data, Psi, model, algParams );
    
    % Diagnose convergence by calculating joint log pr. of all sampled vars
    if n == 1 || rem(n, outParams.logPrEvery)==0
        logPr = calcJointLogPr_sLDA( Psi, Data, model );
    end
    
    %Record current sampler state
    %  NB: internally only records at preset frequency
    ChainHist = recordMCMCHistory_LDA(n, outParams, ChainHist, Psi, logPr);
    
    doSaveToDisk = n==1 || rem(n, outParams.saveEvery)==0 ...
                        || n == algParams.Niter;
    if doSaveToDisk
        filename = fullfile( outParams.saveDir,  'SamplerOutput.mat' );
        save(filename, '-struct', 'ChainHist');
    end
    
    if n == 1 || rem(n, outParams.printEvery)==0
       printMCMCSummary_LDA( n, Psi, logPr, algParams); 
    end
    
    if exist( 'testP', 'var') && ~isempty( testP )
        if n == 1 || rem(n, testP.predictEvery)==0
            if n==1 pc =0; end
            pc = pc+1;
            Predict.train = predict_sLDA( Psi, Data, model, testP ); 
            Predict.test  = predict_sLDA( Psi, TestData, model, testP ); 
            
            PredictHist.iters(pc) = n;
            PredictHist.train(pc) = Predict.train;
            PredictHist.test(pc)  = Predict.test;
            
            filename = fullfile( outParams.saveDir,  'Predictions.mat' );
            save( filename, '-struct', 'PredictHist' );
            
            printPredictionSummary_sLDA( n, Predict, model, algParams );
        end
    end
    
end % loop over sampler iterations

fprintf( '<<<<< --------------------------------------------------- \n');

end % main function

