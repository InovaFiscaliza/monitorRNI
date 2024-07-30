function Data_PA_RNI = ReadFile_PA_RNI(app)

            % Caminho relativo
            relativePath_Data_PA_RNI = '\DataBase\PA_RNI\Dados_PA_RNI.csv';
            DirApp = 'C:\P&D\AppRNI';
            
            % Obter o caminho absoluto
            Path_Data_PA_RNI = fullfile(DirApp, relativePath_Data_PA_RNI);

            opts = detectImportOptions(Path_Data_PA_RNI);
            opts.VariableTypes = {'double', 'char', 'char', 'char', 'char', 'char', 'char', 'char', 'char', 'char', 'char', 'char', 'char', 'char', 'char', 'char', 'char'};
            Data_PA_RNI = readtable(Path_Data_PA_RNI, opts);

%     arguments
%         fileFullPath
%         cacheColumns = {'Homologação', 'Solicitante | Fabricante', 'Modelo | Nome Comercial'}
%     end
% 
%     cacheData    = [];
%     matFullFile  = '';
%     saveMATFile  = false;
% 
%     [filePath, fileName, fileExt] = fileparts(fileFullPath);
% 
%     switch lower(fileExt)
%         case '.mat'
%             load(fileFullPath, 'rawDataTable', 'releasedData', 'cacheData')
% 
%         case '.csv'
%             % rawTable
%             opts = delimitedTextImportOptions('NumVariables',       21,         ...
%                                               'Encoding',           'UTF-8',    ...
%                                               'Delimiter',          ';',        ...
%                                               'VariableNamingRule', 'preserve', ...
%                                               'VariableNamesLine',  1,          ...
%                                               'DataLines',          2,          ...
%                                               'VariableTypes',      {'datetime', 'char', 'char', 'categorical', 'char', 'datetime', 'datetime', 'double', 'categorical', 'double', 'categorical', 'categorical', 'char', 'char', 'double', 'categorical', 'categorical', 'categorical', 'categorical', 'categorical', 'categorical'});
% 
%             opts = setvaropts(opts, 1, 'InputFormat', 'dd/MM/yyyy');
%             opts = setvaropts(opts, 6, 'InputFormat', 'dd/MM/yyyy');
%             opts = setvaropts(opts, 7, 'InputFormat', 'dd/MM/yyyy HH:mm:ss', 'DatetimeFormat', 'dd/MM/yyyy');
% 
%             % Simplificação dos nomes de algumas das colunas que serão apresentadas 
%             % na interface gráfica do usuário.
%             rawColumnNames    = {'Número de Homologação', 'Nome do Solicitante', 'CNPJ do Solicitante', 'Nome do Fabricante', 'Situação do Requerimento', 'Tipo do Produto'};
%             editedColumnNames = {'Homologação', 'Solicitante', 'CNPJ', 'Fabricante', 'Situação', 'Tipo'};
% 
%             rawDataTable = readtable(fileFullPath, opts);
%             rawDataTable = renamevars(rawDataTable, rawColumnNames, editedColumnNames);
% 
%             % Exclusão de registros cujo campo de "Homologação" não possui
%             % 12 caracteres, formatando-o posteriormente.
%             dataIndex = find(cellfun(@(x) numel(x)~=12, rawDataTable.("Homologação")));
%             if ~isempty(dataIndex)
%                 rawDataTable(dataIndex,:) = [];
%             end
%             rawDataTable.("Homologação") = cellfun(@(x) sprintf('%s-%s-%s', x(1:5), x(6:7), x(8:12)), rawDataTable.("Homologação"), 'UniformOutput', false);
% 
%             % releasedData
%             fileInfo     = dir(fileFullPath);
%             releasedData = datestr(fileInfo.date, 'dd/mm/yyyy');
% 
%         otherwise
%             error('Unexpected file format')
%     end
% 
%     if isempty(cacheData) || any(~ismember(cacheColumns, {cacheData.Column}))
%         saveMATFile  = true;
%         [rawDataTable, cacheData] = CacheDataCreation(rawDataTable, cacheColumns);
%     end
% 
%     if saveMATFile
%         matFullFile = fullfile(filePath, [fileName '.mat']);
%         save(matFullFile, 'rawDataTable', 'releasedData', 'cacheData')
%     end
% 
% end
% 
% 
% %-------------------------------------------------------------------------%
% function [rawTable, cacheData] = CacheDataCreation(rawTable, cacheColumns)
% 
%     cacheData = repmat(struct('Column', '', 'uniqueValues', {{}}, 'uniqueTokens', {{}}), numel(cacheColumns), 1);
% 
%     for ii = 1:numel(cacheColumns)
%         listOfColumns = strsplit(cacheColumns{ii}, ' | ');
% 
%         uniqueValues  = {};
%         uniqueTokens  = {};
% 
%         for jj = 1:numel(listOfColumns)
%             cacheColumn        = listOfColumns{jj};
%             [uniqueTempValues, ...
%                 referenceData] = fcn.PreProcessedData(rawTable.(cacheColumn));
%             tokenizedDoc       = tokenizedDocument(uniqueTempValues);
% 
%             uniqueValues       = [uniqueValues; uniqueTempValues];
%             uniqueTokens       = [uniqueTokens; cellstr(tokenizedDoc.tokenDetails.Token)];
% 
%             rawTable.(sprintf('_%s', cacheColumn)) = referenceData;
%         end
%         uniqueValues  = unique(uniqueValues);
% 
%         cacheData(ii) = struct('Column',       cacheColumns{ii},  ...
%                                'uniqueValues', {uniqueValues},    ...
%                                'uniqueTokens', {unique([uniqueValues; uniqueTokens])});
%     end
% 
end