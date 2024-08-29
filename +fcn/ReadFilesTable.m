function Data_PA_RNI = ReadFile_PA_RNI(app)

            % Caminho relativo
            relativePath_Data_PA_RNI = '\DataBase\PA_RNI\Dados_PA_RNI.csv';
            
            % Obter o caminho absoluto
            Path_Data_PA_RNI = fullfile(pwd, relativePath_Data_PA_RNI);

            opts = detectImportOptions(Path_Data_PA_RNI);
            opts.VariableTypes = {'double', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string', 'string'};
            Data_PA_RNI = readtable(Path_Data_PA_RNI, opts);
end