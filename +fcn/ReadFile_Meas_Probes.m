function measData  = ReadFile_Meas_Probes(app, TypeFileMeas, fileFullName, Arq_Num, Get_Files)
    % Cria a barra de progresso e imprimi os Steps
    numOccurrences            = fcn.Progressbar_Files(app);    
    numOccurrences{2}.Message = sprintf('Lendo %dº de %d Arquivo(s)...', Arq_Num, Get_Files);
    
    % Le o conteúdo do arquivo como uma string
    files = fileread(fileFullName);
    
    % Dividir o conteúdo em linhas
    fileContentall = string(splitlines(files));
    
    % Excluir linhas vazias
    filenonEmptyLines = fileContentall(~cellfun('isempty', fileContentall));
    
    % Executa o case de acordo com o Tipo da sonda que gerou o Arquivo txt
    switch TypeFileMeas
        case 'Narda'
            % Procura pelas linhas onde há o padrão tipo pattern
            pattern_SW = '^..........................................................S............W';
            pattern_NE = '^..........................................................N............E';
    
            %Metadata: "Narda"
            Metadata_Probe = struct('field_monitor',       filenonEmptyLines{6}(20:23), ...
                                    'model',               filenonEmptyLines{6}(25:35), ...
                                    'serial_number',       filenonEmptyLines{6}(49:58), ...
                                    'Field_probe',         filenonEmptyLines{11}(9:13), ...
                                    'Units',               filenonEmptyLines{11}(28:30), ...
                                    'Range_frequency',     '100 kHz – 3 GHz', ...
                                    'Range_EletricField',  '0.2 – 200 V/m');
    
            % Encontrar todas as linhas que correspondem ao padrão e selecionar apenas as linhas válidas
            validLines_S_W = ~cellfun(@isempty, regexp(filenonEmptyLines, pattern_SW, 'once'));
            validLines_N_E = ~cellfun(@isempty, regexp(filenonEmptyLines, pattern_NE, 'once'));
            validLines     = (validLines_S_W + validLines_N_E)~= 0;
    
            fileValidRNI  = filenonEmptyLines(validLines);
    
            format long;
            
            % Lê as informações de Campo Elétrico
            FieldValue = str2double(extractBetween(fileValidRNI, 'MES=', ';'));
                                   
            % Lê as informações de Latitude
            Latitude_Narda_int_S_W = str2double(extractBetween(fileValidRNI, 'A,', ',S'));
            Latitude_Narda_S_W     = -1*(floor(Latitude_Narda_int_S_W/100) + (((Latitude_Narda_int_S_W/100) - floor(Latitude_Narda_int_S_W/100))/0.6));
            Latitude_Narda_int_N_E = str2double(extractBetween(fileValidRNI, 'A,', ',N'));
            Latitude_Narda_N_E     = floor(Latitude_Narda_int_N_E/100) + (((Latitude_Narda_int_N_E/100) - floor(Latitude_Narda_int_N_E/100))/0.6);
            Latitude               = [Latitude_Narda_S_W Latitude_Narda_N_E];
    
            %Lê as informações de Longitude
            Longitude_Narda_int_S_W = str2double(extractBetween(fileValidRNI, 'S,', ',W'));
            Longitude_Narda_S_W     = -1*(floor(Longitude_Narda_int_S_W/100) + (((Longitude_Narda_int_S_W/100) - floor(Longitude_Narda_int_S_W/100))/0.6));
            Longitude_Narda_int_N_E = str2double(extractBetween(fileValidRNI, 'N,', ',E'));
            Longitude_Narda_N_E     = floor(Longitude_Narda_int_N_E/100) + (((Longitude_Narda_int_N_E/100) - floor(Longitude_Narda_int_N_E/100))/0.6);
            Longitude               = [Longitude_Narda_S_W Longitude_Narda_N_E];
    
            % Lê as informações de Datatime
            Timestamp = datetime(extractBetween(fileValidRNI, '-->', '*;'), "InputFormat", "yy/MM/dd HH:mm:ss");
    
            % Resposta = fileReader.NardaCSV(fileID);               
        
        case 'Monitem'
            % Procura pelas linhas onde há o padrão tipo pattern
            pattern_SW = '^.....................................................S..............W';
            pattern_NE = '^.....................................................N..............E';
           
            %Metadata: "MonitEM"
            Metadata_Probe = struct('Wavecontrol',    filenonEmptyLines{1}(13:end),  ...
                                    'Date',           filenonEmptyLines{2}(7:end),   ...
                                    'MonitEM_Serial', filenonEmptyLines{3}(17:end),  ...
                                    'Probe_Serial',   filenonEmptyLines{4}(15:end),  ...
                                    'Frecuencies',    filenonEmptyLines{5}(14:end),  ...
                                    'Units',          filenonEmptyLines{6}(8:end));
    
            % Encontrar todas as linhas que correspondem ao padrão
            validLines_S_W = ~cellfun(@isempty, regexp(filenonEmptyLines, pattern_SW, 'once'));
            validLines_N_E = ~cellfun(@isempty, regexp(filenonEmptyLines, pattern_NE, 'once'));
            validLines     = (validLines_S_W + validLines_N_E)~= 0;
    
            fileValidRNI  = filenonEmptyLines(validLines);
    
            format long;
    
            %Lê as informações de Campo Elétrico
            FieldValue = str2double(extractBetween(fileValidRNI, 21, ',$GPGGA'));    
    
            %Lê as informações de Latitude
            Latitude_Monitem_int_S_W = str2double(extractBetween(fileValidRNI, 42, ',S'));
            Latitude_Monitem_S_W     = -1*(floor(Latitude_Monitem_int_S_W/100) + (((Latitude_Monitem_int_S_W/100) - floor(Latitude_Monitem_int_S_W/100))/0.6));
            Latitude_Monitem_int_N_E = str2double(extractBetween(fileValidRNI, 'A,', ',N'));
            Latitude_Monitem_N_E     = floor(Latitude_Monitem_int_N_E/100) + (((Latitude_Monitem_int_N_E/100) - floor(Latitude_Monitem_int_N_E/100))/0.6);
            Latitude                 = [Latitude_Monitem_S_W Latitude_Monitem_N_E];
             
            %Lê as informações de Longitude
            Longitude_Monitem_int_S_W = str2double(extractBetween(fileValidRNI, 'S,', ',W'));
            Longitude_Monitem_S_W     = -1*(floor(Longitude_Monitem_int_S_W/100) + (((Longitude_Monitem_int_S_W/100) - floor(Longitude_Monitem_int_S_W/100))/0.6));
            Longitude_Monitem_int_N_E = str2double(extractBetween(fileValidRNI, 'N,', ',E'));
            Longitude_Monitem_N_E     = floor(Longitude_Monitem_int_N_E/100) + (((Longitude_Monitem_int_N_E/100) - floor(Longitude_Monitem_int_N_E/100))/0.6);
            Longitude                 = [Longitude_Monitem_S_W Longitude_Monitem_N_E];                                                    
    
            %Lê as informações de Datatime
            Timestamp = datetime(extractBetween(fileValidRNI, 1, 19), "InputFormat", "yyyy/MM/dd,HH:mm:ss");
    
        % Resposta = fileReader.MonitemCSV(fileID);
        otherwise
            error('UnexpectedFileFormat')
    end

        % Cria a matriz dos dados dos arquivos de medições de RNI
        dataTable = timetable(Timestamp, Latitude, Longitude, FieldValue);
        dataTable.Timestamp.Format = 'dd/MM/yyyy HH:mm:ss';

        [minLatitude,  maxLatitude]  = bounds(dataTable.Latitude);
        [minLongitude, maxLongitude] = bounds(dataTable.Longitude);
        
        measData = class.measData;

        measData.Filename = fileFullName;
        
        measData.Sensor   = TypeFileMeas;
        measData.MetaData = Metadata_Probe;
        
        measData.Measures = height(dataTable);
        measData.Data     = dataTable;
        
        measData.LatitudeLimits  = [minLatitude;  maxLatitude];
        measData.LongitudeLimits = [minLongitude; maxLongitude];
        measData.Location        = fcn.gpsFindCity(struct('Latitude', mean([minLatitude;  maxLatitude]), 'Longitude', mean([minLongitude; maxLongitude])));       
end