function Data_Loc_Serv = ReadFile_Loc_Serv(rootFolder, Arq_Loc_Serv)

    switch Arq_Loc_Serv
        case 'Serv'
            % Obter o caminho absoluto
            Path_Data_Loc_Serv = fullfile(rootFolder, 'DataBase', 'PA_RNI', 'TServico.csv');
        
            opts = detectImportOptions(Path_Data_Loc_Serv);
            
            % Defini os tipos de variáveis de cada coluna do arquivo do PA_RNI
            opts.VariableTypes = {'string', 'string'};
            
            %Preserva os nomes da colunas da tabela do PA_RNI
            opts.PreserveVariableNames = true;
        
            %Lê para Data_PA_RNI os dados da tabela do PA_RNI
            Data_Loc_Serv = readtable(Path_Data_Loc_Serv, opts);
    
        case 'Local'
            % Obter o caminho absoluto
            Path_Data_Loc_Serv = fullfile(rootFolder, 'DataBase', 'PA_RNI', 'UF_Localidades_Brasil.csv');
        
            opts = detectImportOptions(Path_Data_Loc_Serv);
            
            % Defini os tipos de variáveis de cada coluna do arquivo do PA_RNI
            opts.VariableTypes = {'string', 'string'};
            
            %Preserva os nomes da colunas da tabela do PA_RNI
            opts.PreserveVariableNames = true;
        
            %Lê para Data_PA_RNI os dados da tabela do PA_RNI
            Data_Loc_Serv = readtable(Path_Data_Loc_Serv, opts);
    end
end