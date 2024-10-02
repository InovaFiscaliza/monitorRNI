function Data_Probe  = ReadFile_Meas_Probes(app, TypeFileMeas, fileFullName, Arq_Num, All_Files)

            %Cria a barra de progresso e calcula os Steps
            numOccurrences = fcn.Progressbar_Files(app, fileFullName);
     
            numOccurrences{2}.Message = sprintf('Lendo %dº de %d Arquivo(s)...', Arq_Num, All_Files);

            %Executa o case de acordo com o Tipo da sonda que gerou o Arquivo txt
            switch TypeFileMeas
                case 'Narda'
                    % Procura pelas linhas onde há o padrão tipo pattern
                    pattern_SW = '^..........................................................S............W';
                    pattern_NE = '^..........................................................N............E';
                   
                    % Ler o conteúdo do arquivo como uma string
                    files = fileread(fileFullName);
                    
                    % Dividir o conteúdo em linhas
                    fileContentall = string(splitlines(files));

                    % Excluir linhas vazias
                    filenonEmptyLines = fileContentall(~cellfun('isempty', fileContentall));

                    %Metadata: "Narda"
                    Metadata_Probe = struct('Wavecontrol',    filenonEmptyLines{6}(24:35),  ...
                                            'Date',           'NaN',                         ...
                                            'MonitEM_Serial', filenonEmptyLines{6}(8:22),   ...
                                            'Probe_Serial',   'NaN',                         ...
                                            'Frecuencies',    'NaN',                         ...
                                            'Units',          'NaN');

                    % Encontrar todas as linhas que correspondem ao padrão
                    validLines_S_W = ~cellfun(@isempty, regexp(filenonEmptyLines, pattern_SW, 'once'));
                    validLines_N_E = ~cellfun(@isempty, regexp(filenonEmptyLines, pattern_NE, 'once'));
                    validLines = (validLines_S_W + validLines_N_E)~= 0;

                    fileValidRNI  = filenonEmptyLines(validLines);

                    format long;
                    
                    %Lê as informações de Campo Elétrico
                    FieldValue = str2double(extractBetween(fileValidRNI, 'MES=', ';'));
                                           
                    %Lê as informações de Latitude
                    Latitude_Narda_int_S_W = str2double(extractBetween(fileValidRNI, ',A,', ',S,'));
                    Latitude_Narda_S_W = -1*(floor(Latitude_Narda_int_S_W/100) + (((Latitude_Narda_int_S_W/100) - floor(Latitude_Narda_int_S_W/100))/0.6));
                    Latitude_Narda_int_N_E = str2double(extractBetween(fileValidRNI, ',A,', ',N,'));
                    Latitude_Narda_N_E = floor(Latitude_Narda_int_N_E/100) + (((Latitude_Narda_int_N_E/100) - floor(Latitude_Narda_int_N_E/100))/0.6);
                    Latitude = [Latitude_Narda_S_W Latitude_Narda_N_E];
         
                    %Lê as informações de Longitude
                    Longitude_Narda_int_S_W = str2double(extractBetween(fileValidRNI, ',S,', ',W,'));
                    Longitude_Narda_S_W = -1*(floor(Longitude_Narda_int_S_W/100) + (((Longitude_Narda_int_S_W/100) - floor(Longitude_Narda_int_S_W/100))/0.6));
                    Longitude_Narda_int_N_E = str2double(extractBetween(fileValidRNI, ',N,', ',E,'));
                    Longitude_Narda_N_E = floor(Longitude_Narda_int_N_E/100) + (((Longitude_Narda_int_N_E/100) - floor(Longitude_Narda_int_N_E/100))/0.6);
                    Longitude = [Longitude_Narda_S_W Longitude_Narda_N_E];

                    %Lê as informações de Datatime
                    Timestamp = datetime(extractBetween(fileValidRNI, '-->', '*;'), "InputFormat", "yy/MM/dd HH:mm:ss", "Format", "dd/MM/yy HH:mm:ss");

                    %Cria a matriz dos dados dos arquivos de medições de RNI
                    dataTable = timetable(Timestamp, Latitude, Longitude, FieldValue);

                    %Resposta = fileReader.NardaCSV(fileID);               
                
                case 'Monitem'
                    % Procura pelas linhas onde há o padrão tipo pattern
                    pattern_SW = '^.....................................................S..............W';
                    pattern_NE = '^.....................................................N..............E';
                   
                    %Ler o conteúdo do arquivo como uma string
                    files = fileread(fileFullName);
                    
                    % Dividir o conteúdo em linhas
                    fileContentall = string(splitlines(files));

                    % Excluir linhas vazias
                    filenonEmptyLines = fileContentall(~cellfun('isempty', fileContentall));

                    %Metadata: "MonitEM"
                    Metadata_Probe = struct('Wavecontrol',    filenonEmptyLines{1}(12:end),  ...
                                            'Date',           filenonEmptyLines{2}(6:end),  ...
                                            'MonitEM_Serial', filenonEmptyLines{3}(16:end),  ...
                                            'Probe_Serial',   filenonEmptyLines{4}(14:end),  ...
                                            'Frecuencies',    filenonEmptyLines{5}(13:end),  ...
                                            'Units',          filenonEmptyLines{6}(7:end));

                    % Encontrar todas as linhas que correspondem ao padrão
                    validLines_S_W = ~cellfun(@isempty, regexp(filenonEmptyLines, pattern_SW, 'once'));
                    validLines_N_E = ~cellfun(@isempty, regexp(filenonEmptyLines, pattern_NE, 'once'));
                    validLines = (validLines_S_W + validLines_N_E)~= 0;

                    fileValidRNI  = filenonEmptyLines(validLines);

                    format long;

                    %Lê as informações de Campo Elétrico
                    FieldValue = str2double(extractBetween(fileValidRNI, 21, ',$GPGGA'));    

                    %Lê as informações de Latitude
                    Latitude_Monitem_int_S_W = str2double(extractBetween(fileValidRNI, 42, ',S,'));
                    Latitude_Monitem_S_W = -1*(floor(Latitude_Monitem_int_S_W/100) + (((Latitude_Monitem_int_S_W/100) - floor(Latitude_Monitem_int_S_W/100))/0.6));
                    Latitude_Monitem_int_N_E = str2double(extractBetween(fileValidRNI, ',A,', ',N,'));
                    Latitude_Monitem_N_E = floor(Latitude_Monitem_int_N_E/100) + (((Latitude_Monitem_int_N_E/100) - floor(Latitude_Monitem_int_N_E/100))/0.6);
                    Latitude = [Latitude_Monitem_S_W Latitude_Monitem_N_E];
                     
                    %Lê as informações de Longitude
                    Longitude_Monitem_int_S_W = str2double(extractBetween(fileValidRNI, ',S,', ',W,'));
                    Longitude_Monitem_S_W = -1*(floor(Longitude_Monitem_int_S_W/100) + (((Longitude_Monitem_int_S_W/100) - floor(Longitude_Monitem_int_S_W/100))/0.6));
                    Longitude_Monitem_int_N_E = str2double(extractBetween(fileValidRNI, ',N,', ',E,'));
                    Longitude_Monitem_N_E = floor(Longitude_Monitem_int_N_E/100) + (((Longitude_Monitem_int_N_E/100) - floor(Longitude_Monitem_int_N_E/100))/0.6);
                    Longitude = [Longitude_Monitem_S_W Longitude_Monitem_N_E];                                                    

                    %Lê as informações de Datatime
                    Timestamp = datetime(extractBetween(fileValidRNI, 1, 19), "InputFormat", "yyyy/MM/dd,HH:mm:ss", "Format", "dd/MM/yyyy HH:mm:ss");

                    dataTable = timetable(Timestamp, Latitude, Longitude, FieldValue);

                % Resposta = fileReader.MonitemCSV(fileID);
                otherwise
                    error('UnexpectedFileFormat')
            end

        [minLatitude,  maxLatitude]  = bounds(dataTable.Latitude);
        [minLongitude, maxLongitude] = bounds(dataTable.Longitude);
        
        Data_Probe = struct('Filename',        fileFullName,                 ...
                            'Measures',        height(dataTable),            ...
                            'Sensor',          TypeFileMeas,                 ...
                            'Data',            dataTable,                    ...
                            'LatitudeLimits',  [minLatitude;  maxLatitude],  ...
                            'LongitudeLimits', [minLongitude; maxLongitude],...
                            'MetaDataProbe',   {Metadata_Probe});

        app.MaioresnveisButton.Enable = true;
end