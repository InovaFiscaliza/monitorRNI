function Data_Monitem_Narda  = ReadFile_Meas_Sondas(app, TypeFileMeas,File_Sondas)

            % Abrir o arquivo para leitura
            fileID = fopen(File_Sondas, 'r');
            
            if TypeFileMeas == "Narda"
            
                % Verificar se o arquivo foi aberto com sucesso
                if fileID == -1
                    error('Erro ao abrir o arquivo.');
                end

                % Inicializar variáveis
                lineNumber = 0;
                % foundLine = -1;
                % searchString = 'MES='; % A string que você está procurando
                pattern = '^..........................................................S............W'; % Padrão de exemplo: 'A' na 1ª posição, 'B' na 4ª posição, 'C' na 7ª posição
               
                % Ler e processar o conteúdo a partir da linha desejada
                dataArray = {};
                Data_Monitem_Narda = {};
                % Ler o arquivo linha por linha
                while ~feof(fileID)
                    % Ler a linha atual
                    currentLine = fgetl(fileID);

                    if ~isempty(currentLine)
                        % Incrementar o contador de linhas
                        lineNumber = lineNumber + 1;
                    end
                    
                    % Verificar se a linha corresponde ao padrão
                    if ~isempty(regexp(currentLine, pattern, 'once'))
                        % foundLine = lineNumber;
                        E_Narda = extractBetween(currentLine, 'MES=', ';');
                        Latitude_Narda = extractBetween(currentLine, ',A,', ',S,');
                        Longitude_Narda = extractBetween(currentLine, ',S,', ',W,');
                        DataTime_Narda = extractBetween(currentLine, '-->', '*;');
                        dataRow = [DataTime_Narda Latitude_Narda Longitude_Narda E_Narda];
                        dataArray = [dataArray; dataRow];                        
                    end
                end
                % dataArray = cell2table(dataArray, 'VariableNames', {'DataTime', 'Latitude', 'Longitude', 'E_VM'});

                 % Encontrar a posição do caractere específico
                 Latitude_Narda = string(dataArray(:,2));
                 pos_matches_Lat = str2double(string(strfind(Latitude_Narda, '.')));
                 % Extrair a substring até o caractere específico
                 Lat_Part1 = extractBetween(Latitude_Narda, 1, pos_matches_Lat-3);
                 Lat_Part2 = extractBetween(Latitude_Narda, pos_matches_Lat-2, pos_matches_Lat+4);
                 % Lat_Part3 = extractBetween(Latitude_Narda, pos_matches_Lat+1, pos_matches_Lat+4);
                 Lat_Decimal_Total = str2double(Lat_Part1)+(str2double(Lat_Part2)/60);

                 % Encontrar a posição do caractere específico
                 Longitude_Narda = string(dataArray(:,3));
                 pos_matches_Long = str2double(string(strfind(Longitude_Narda, '.')));
                 % Extrair a substring até o caractere específico
                 Long_Part1 = extractBetween(Longitude_Narda, 1, pos_matches_Long-3);
                 Long_Part2 = extractBetween(Longitude_Narda, pos_matches_Long-2, pos_matches_Long+4);
                 % Long_Part3 = extractBetween(Longitude_Narda, pos_matches_Long+1, pos_matches_Long+4);
                 Long_Decimal_Total = str2double(Long_Part1)+(str2double(Long_Part2)/60);
                 format long;
                 dataArray(:,2) = num2cell(Lat_Decimal_Total);
                 dataArray(:,3) = num2cell(Long_Decimal_Total);
            else
          
                % Verificar se o arquivo foi aberto com sucesso
                if fileID == -1
                    error('Erro ao abrir o arquivo.');
                end

                % Inicializar variáveis
                lineNumber = 0;
                % foundLine = -1;
                % searchString = 'MES='; % A string que você está procurando
                pattern = '^.....................................................S..............W'; % Padrão de exemplo: 'A' na 1ª posição, 'B' na 4ª posição, 'C' na 7ª posição
               
                % Ler e processar o conteúdo a partir da linha desejada
                dataArray = {};
                Data_Monitem_Narda = {};
                % Ler o arquivo linha por linha
                while ~feof(fileID)
                    
                    % Ler a linha atual
                    currentLine = fgetl(fileID);

                    if ~isempty(currentLine)
                        % Incrementar o contador de linhas
                        lineNumber = lineNumber + 1;
                    end
                    
                    % Verificar se a linha corresponde ao padrão
                    if ~isempty(regexp(currentLine, pattern, 'once'))
                        % foundLine = lineNumber;
                        Latitude_Monitem = extractBetween(currentLine, 42, ',S,');
                        Longitude_Monitem = extractBetween(currentLine, ',S,', ',W,');
                        E_Monitem = extractBetween(currentLine, 21, ',$GPGGA');
                        DataTime_Monitem = extractBetween(currentLine, 1, 19);
                        dataRow = [DataTime_Monitem Latitude_Monitem Longitude_Monitem E_Monitem];
                        dataArray = [dataArray; dataRow];                                      
                    end
                end
                % dataArray = cell2table(dataArray, 'VariableNames', {'DataTime', 'Latitude', 'Longitude', 'E_VM'});   
                % dataArray = cell2table(dataArray, 'VariableNames', {'DataTime', 'Latitude', 'Longitude', 'E_VM'});
                 % dataArray(:,2) = replace(dataArray(:,2),".","");
                 % dataArray(:,3) = replace(dataArray(:,3),".","");
                 
                % Latitude_Monitem = string(dataArray(:,2));
           
                 % Encontrar a posição do caractere específico
                 Latitude_Monitem = string(dataArray(:,2));
                 pos_matches_Lat = str2double(string(strfind(Latitude_Monitem, '.')));
                 % Extrair a substring até o caractere específico
                 Lat_Part1 = extractBetween(Latitude_Monitem, 1, pos_matches_Lat-3);
                 Lat_Part2 = extractBetween(Latitude_Monitem, pos_matches_Lat-2, pos_matches_Lat+6);
                 % Lat_Part3 = extractBetween(Latitude_Monitem, pos_matches_Lat+1, pos_matches_Lat+5);
                 Lat_Decimal_Total = str2double(Lat_Part1)+str2double(Lat_Part2)/60;

                 % Encontrar a posição do caractere específico
                 Longitude_Monitem = string(dataArray(:,3));
                 pos_matches_Long = str2double(string(strfind(Longitude_Monitem, '.')));
                 % Extrair a substring até o caractere específico
                 Long_Part1 = extractBetween(Longitude_Monitem, 1, pos_matches_Long-3);
                 Long_Part2 = extractBetween(Longitude_Monitem, pos_matches_Long-2, pos_matches_Long+6);
                 % Long_Part3 = extractBetween(Longitude_Monitem, pos_matches_Long+1, pos_matches_Long+4);
                 Long_Decimal_Total = str2double(Long_Part1)+str2double(Long_Part2)/60;
                 format long;
                 dataArray(:,2) = num2cell(Lat_Decimal_Total);
                 dataArray(:,3) = num2cell(Long_Decimal_Total);
            end
            Data_Monitem_Narda  = dataArray;
end