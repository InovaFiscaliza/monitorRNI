function Files_Meas_Probes = FilesMeasProbes(app)

            % Especificar o caminho do diretório
            path = 'C:\P&D\AppRNI\DataBase\Meas_Sondas';
            
            % Obter informações sobre os arquivos no diretório
            fileInfo = dir(path);
            
            % Filtrar apenas os arquivos (excluindo diretórios)
            isFile = ~[fileInfo.isdir];
            
            % Obter os nomes dos arquivos
            fileNames = {fileInfo(isFile).name}';
            
            % Converter para vetor de strings (opcional)
            fileNames         = string(fileNames);
            Files_Meas_Probes = fileNames;