function Data_Loc_Serv = ReadFile_Loc_Serv(app, Arq_Loc_Serv)

            if Arq_Loc_Serv == "Serv"

                relativePath_Data_Loc_Serv = '\DataBase\PA_RNI\TServico.csv';
                DirApp = 'C:\P&D\AppRNI';

                % Obter o caminho absoluto
                Path_Data_Loc_Serv = fullfile(DirApp, relativePath_Data_Loc_Serv);
    
                opts = detectImportOptions(Path_Data_Loc_Serv);
                
                % Defini os tipos de variáveis de cada coluna do arquivo do PA_RNI
                opts.VariableTypes = {'string', 'string'};
                
                %Preserva os nomes da colunas da tabela do PA_RNI
                opts.PreserveVariableNames = true;
    
                %Lê para Data_PA_RNI os dados da tabela do PA_RNI
                Data_Loc_Serv = readtable(Path_Data_Loc_Serv, opts);

            elseif Arq_Loc_Serv == "Local"
                
                relativePath_Data_Loc_Serv = '\DataBase\PA_RNI\UF_Localidades_Brasil.csv';
                DirApp = 'C:\P&D\AppRNI';  

                % Obter o caminho absoluto
                Path_Data_Loc_Serv = fullfile(DirApp, relativePath_Data_Loc_Serv);
    
                opts = detectImportOptions(Path_Data_Loc_Serv);
                
                % Defini os tipos de variáveis de cada coluna do arquivo do PA_RNI
                opts.VariableTypes = {'string', 'string'};
                
                %Preserva os nomes da colunas da tabela do PA_RNI
                opts.PreserveVariableNames = true;
    
                %Lê para Data_PA_RNI os dados da tabela do PA_RNI
                Data_Loc_Serv = readtable(Path_Data_Loc_Serv, opts);
            end           
end