function mlapp2m(MLAPPFiles)
    arguments
        MLAPPFiles cell = {'winRNI'}
    end

    % Essa função manipula alguns dos arquivos .MLAPP do projeto, gerando
    % versões .M.
    % - "winRNI.mlapp"
    %   A versão .M facilita acompanhamento da evolução do projeto por meio 
    %   do GitHub Desktop (ao invés de executar a comparação linha a linha 
    %   no próprio Matlab).
     
    fileFolder = fileparts(mfilename('fullpath'));    
    
    for ii = 1:numel(MLAPPFiles)
        try
            oldClassName = MLAPPFiles{ii};
            newClassName = [oldClassName '_exported'];

            fileBaseName = fullfile(fileFolder, oldClassName);
            matlabCode   = getMFileContent(fileBaseName);

            % SUBSTITUIÇÃO: ClassName
            oldTags = {sprintf('classdef %s < matlab.apps.AppBase', oldClassName), ...
                       sprintf('function app = %s',                 oldClassName)};

            % VALIDAÇÃO
            if any(cellfun(@(x) ~contains(matlabCode, x), oldTags))
                error('Não identificado uma das tags! :(')
            end

            newTags = {sprintf('classdef %s < matlab.apps.AppBase', newClassName), ...
                       sprintf('function app = %s',                 newClassName)};

            matlabCode   = replace(matlabCode, oldTags, newTags);
            writematrix(matlabCode, [fileBaseName '_exported.m'], 'FileType', 'text', 'WriteMode', 'overwrite', 'QuoteStrings', 'none')

            fprintf('Criado o arquivo %s\n', [fileBaseName '_exported.m'])

        catch ME
            fprintf('ERRO ao processar o arquivo %s. %s\n', [fileBaseName '.mlapp'], ME.message)
        end
    end
end

%-------------------------------------------------------------------------%
function matlabCode = getMFileContent(fileBaseName)
    readerObj  = appdesigner.internal.serialization.FileReader([fileBaseName '.mlapp']);
    matlabCode = readerObj.readMATLABCodeText();
end