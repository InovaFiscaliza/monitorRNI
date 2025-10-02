# monitorRNI  

O monitorRNI é uma ferramenta de pós-processamento de dados gerados em campanhas de medição da exposição humana a campos elétricos, no âmbito do Plano de Monitoração de Radiação Não Ionizante (PM-RNI).  

A ferramenta foi desenvolvida em **MATLAB** e possui:  
- uma versão *desktop*, que pode ser utilizada em ambiente offline;  
- uma versão *webapp*, acessível na intranet.  

#### FUNCIONALIDADES  
- Leitura de arquivos brutos de medidas gerados pelas sondas WaveControl MonitEM e Narda 8059.  
- Identificação de medições no entorno de pontos de interesse, com geração de plots georreferenciados da rota.
- Geração de relatórios e exportação de arquivos de resultados em vários formatos (.html, .xlsx e .kml). 

#### COMPATIBILIDADE  
O monitorRNI é compatível com as versões mais recentes do MATLAB (ex.: *R2024a* e *R2025a*).  
A versão compilada — seja *desktop* ou *webapp* — é executada sobre a máquina virtual do MATLAB, o MATLAB Runtime.  

#### EXECUÇÃO NO AMBIENTE DO MATLAB  
Caso o aplicativo seja executado diretamente no MATLAB, é necessário:  
1. Clonar o presente repositório.
2. Clonar também o repositório [SupportPackages](https://github.com/InovaFiscaliza/SupportPackages), adicionando ao *path* do MATLAB as seguintes pastas deste repositório:  
```
.\src\Anatel
.\src\General
```

3. Abrir o projeto **monitorRNI.prj**.
4. Executar **winMonitorRNI.mlapp**.  

#### OUTRAS INFORMAÇÕES
🔗 [InovaFiscaliza/monitorRNI](https://anatel365.sharepoint.com/sites/InovaFiscaliza/SitePages/monitorRNI.aspx)  
