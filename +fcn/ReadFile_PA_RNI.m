function [Data_PA_RNI, Path_Data_PA_RNI_Out] = ReadFile_PA_RNI(rootFolder, userPath)    
    % Obter o caminho absoluto
    Path_Data_PA_RNI = fullfile(rootFolder, 'DataBase', 'PA_RNI', 'Dados_PA_RNI.csv');
    
    opts = detectImportOptions(Path_Data_PA_RNI);
    
    % Defini os tipos de variáveis de cada coluna do arquivo do PA_RNI
    opts.VariableTypes = {'string', 'string', 'string', 'string', 'int64', 'int32', 'string', 'string'};
    
    %Preserva os nomes da colunas da tabela do PA_RNI
    opts.PreserveVariableNames = true;
    
    %Lê para Data_PA_RNI os dados da tabela do PA_RNI
    Data_PA_RNI = readtable(Path_Data_PA_RNI, opts);
    
    % Subtui as virgulas das coordendas por pontos e tranforma Lat. e Long. para Double
    Data_PA_RNI.('Latitude da Estação')  = double(replace(Data_PA_RNI.('Latitude da Estação'),",","."));
    Data_PA_RNI.('Longitude da Estação') = double(replace(Data_PA_RNI.('Longitude da Estação'),",","."));
    
    format long;
    
    % Identificar os valor Data_PA_RNI ausentes (NaN ou vazio)
    missingIdx = cellfun(@(x) isempty(x) || (ischar(x) && strcmpi(x, 'NaN')), Data_PA_RNI {:,1:8});
    
    % Substituir valores ausentes do arquivo do PA_RNI por ''
    Data_PA_RNI {:,1:4}(missingIdx) = {''};
    
    % Supondo que a quantidade de linhas é a mesma da tabela original
    numRows = height(Data_PA_RNI);
    
    % Inicializar colunas com valores em branco
    Colum_1 = NaT(numRows, 1, "InputFormat", "yy/MM/dd HH:mm:ss", "Format", "dd/MM/yy HH:mm:ss"); % Coluna de datetime com valores NaT (Not-a-Time)
    Colum_2 = NaN(numRows, 1);         % Coluna de double com valores NaN (Not-a-Number)
    Colum_3 = NaN(numRows, 1);         % Outra coluna de double com valores NaN
    Colum_4 = NaN(numRows, 1);         % Outra coluna de double com valores NaN
    Colum_5 = int32(zeros(numRows, 1));% Coluna de inteiros inicializada com zeros (pode ser substituído por valores em branco)
    Colum_6 = strings(numRows, 1);     % Coluna de strings vazias
    Colum_7 = strings(numRows, 1);     % Outra coluna de strings vazias
    
    % Criar a tabela com valores em branco (valores padrão inseridos acima)
    mixedTable = table(Colum_1, Colum_2, Colum_3, Colum_4, Colum_5, Colum_6, Colum_7);
    
    % Definir novos nomes de colunas
    NewNames = {'Data da Medição', 'Emáx (V/m)', 'Latitude Emáx', 'Longitude Emáx', '> 14 V/M', 'Justificativa (apenas NV)', 'Observações importantes'};
    
    % Aplicar novos nomes às colunas
    mixedTable.Properties.VariableNames = NewNames;
    
    % Concatenar a nova tabela com a tabela existente do PA_RNI
    Data_PA_RNI = [Data_PA_RNI mixedTable];
    
    % Obter o caminho absoluto do Arquivo de saida gerado
    Path_Data_PA_RNI_Out = [class.Constants.DefaultFileName(userPath, 'Dados_PA_RNI_Calculados') '.xlsx'];
    writetable(Data_PA_RNI, Path_Data_PA_RNI_Out)
end