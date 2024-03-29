%% Etapa 1. Millors resultats en la primera practica
%Constants trobades provant diferents valors i fent una cerca binaria
%per optimitzar els resultats
global bins;
global num_teams; global num_hists;
num_teams = 7;
num_hists = 3;
bins = 32;
th = 0.2;
th2 = 0.019;
%% Etapa 2: Histogrames de mostra
global models;
%a la variable models hi guardarem els 3 histogrames model de cada equip
models = zeros(num_teams, 3, 96);
loadHists();
%% Etapa 3 i 4. Comparacio dels histogrames de cada equip i distribucio de resultats
mode =  input('\nVols tractar una sola imatge o totes les de un equip?:\n1 - Sola\n2 - Equip\n');
if(mode == 1)
    team = input('\nIndica lequip de la imatge a tractar:\nbarcelona\nacmilan\nmadrid\n', 's');
    num = input('\nIndica el numero de la imatge a tractar:\n01 .. 37\n', 's');
    res = readImg(team, num);
    disp('La imatge pertany al equip: ');
    disp(res);
else
% LLegim totes les imatges de cada equip i calculem el resultat
% Per cada foto ens sera retornat un nombre del 1 al 7 indicant l'equip
% amb mes presencia a la foto
    team = input('\nIndica lequip a tractar:\nbarcelona\nacmilan\nmadrid\n', 's');
    results = readImgs(team);
    %Fem un grafic per veure quin valor li ha sigut assignat a cada foto
    %Segons el valor de la barra sabem a quin equip pertany
    figure(), bar(results, 'BarWidth', 1),  title(strcat('resultats_ ',team));
end
%% Funcions auxiliars
%llegeix una sola imatge i en calcula l'equip al que pertany
function res=readImg(team, num)
        name = strcat(team, '/', num,'.jpg');
        im = imread(name);
        res = compareImg(im);
end

function arr=readImgs(team)
%llegeix les imatges d'un equip i calcula l'equip al que pertany cadascuna
    arr = zeros(37:1);
    for k = 1:9
        name = sprintf(strcat(team,'/0%d.jpg'), k);
        im = imread(name);
        arr(k) = compareImg(im);
    end
    for k = 10:37
        name = sprintf(strcat(team,'/%d.jpg'), k);
        im = imread(name);
        arr(k) = compareImg(im);
    end
end

function index=compareImg(im)
%retorna l'index del equip que suposadament apareix mes a la imatge
    global bins; global models; global num_teams; global num_hists;
    [rows, cols, ~] = size(im);
    w = 100; h = 100;
    index = 0;
    minD = 999999;
    step = 60;
    %equalitzem la imatge a testejar
    im = equalize(im);
    %Per cada equip
    for k = 1 : num_teams
        %agafem l'histograma model
        modelTeam = zeros(3, 96);
        %total es el recompte de subimatges que s'han analitzat de la foto
        %a testejar
        total = 0;
        %d es un acumulador per la distancia de la imatge al model
        d = 0;
        for i = 1 : step : rows-h
            for j = 1: step : cols-w
                %Comparem un conjunt de sub-finestres amb els histogrames
                %model de cada equip
                total = total + 1;
                %calculem l'histograma de la part de imatge que estem
                %avaluant
                part = im(i:i+w, j:j+h,:);
                Hpart = histograma(part,bins);
                for l = 1 : num_hists
                    modelTeam(1, :) = models(k, l, :);
                    %en calculem la distancia entre l'histograma model i
                    %els histogrames de mostra
                    d = d + compareHists(Hpart, modelTeam(1, :));
                end
            end
        end
        %Normalitzem d segons el nombre de subimatges que s'han contrastat
        d = d/total;
        if(d < minD)
            %Guardem l'index de l'equip que ha coincidit millor amb la
            %imatge de test
            minD = d;
            index = k;
        end
    end
end

function H=histograma(im,bins)
%per a calcular l'histograma utilitzem la funcio HistCounts
        R = im(:,:,1);
        G = im(:,:,2);
        B = im(:,:,3);
        %Separem la imatge per canals R, G i B i guardem 32 valors per cada
        %canal
        H = [histcounts(R, bins, 'Normalization', 'probability'), ...
             histcounts(G, bins, 'Normalization', 'probability'), ...
             histcounts(B, bins, 'Normalization', 'probability')];
end

function EQ=equalize(im)
%per equalitzar la imatge i ferla invariant a la iluminacio eliminem el
%canal V de la imatge convertida a HSV i la tornem a passar a rgb
        imh = rgb2hsv(im);
        imh(:,:,3)=1;
        EQ = hsv2rgb(imh);
end

function D=compareHists(H1, H2)
%funcio per calcular la distancia entre 2 histogrames
    global bins;
    L = bins*3;
    Dreds = pdist2(H1(1:bins-1),H2(1:bins-1));
    Dgreens = pdist2(H1(bins:2*bins-1),H2(bins:2*bins-1));
    Dblues = pdist2(H1(2*bins:L),H2(2*bins:L));
    %calculem la distancia entre 2 histogrames com la mitja aritmetica de
    %la distancia pitagorica entre ells
    D = (Dblues+Dreds+Dgreens)/3;
end

function loadHists()
global models; global bins;
    %1 Imatges i histogrames BCN
    modelBcn = zeros(3, 96);
    im = imread('models/bcn1.jpg');
    s = im(170:270,60:160,:);
    mostra1 = equalize(s);
    modelBcn(1, :)= histograma(mostra1,bins);
    im = imread('models/bcn2.jpg');
    s2 = im(120:220,65:165,:);
    mostra2 = equalize(s2);
    modelBcn(2, :) = histograma(mostra2,bins);
    im = imread('models/bcn3.jpg');
    s3 = im(300:400,80:180,:);
    mostra3 = equalize(s3);    
    modelBcn(3, :) = histograma(mostra3,bins);
    models(1, :, :) = modelBcn;
    
    %2 Imatges i histogrames AcMilan
    modelAcm = zeros(3, 96);
    im = imread('models/acm1.jpg');
    s = im(110:210,80:180,:);
    mostra1 = equalize(s);
    modelAcm(1, :)= histograma(mostra1,bins);
    im = imread('models/acm2.jpg');
    s2 = im(150:250, 180:280, :);
    mostra2 = equalize(s2);
    modelAcm(2, :) = histograma(mostra2,bins);
    im = imread('models/acm3.jpg');
    s3 = im(200:300, 229:329, :);
    mostra3 = equalize(s3);
    modelAcm(3, :) = histograma(mostra3,bins);
    models(2, :, :) = modelAcm;

    %3 Imatges i histogrames Chelsea
    modelChe = zeros(3, 96);
    im = imread('models/che1.jpg');
    s = im(90:190, 50:150, :);
    mostra1 = equalize(s);
    modelChe(1, :)= histograma(mostra1,bins);
    im = imread('models/che2.jpg');
    s2 = im(115:215, 100:200, :);
    mostra2 = equalize(s2);
    modelChe(2, :) = histograma(mostra2,bins);
    im = imread('models/che3.jpg');
    s3 = im(70:160, 40:110, :);
    mostra3 = equalize(s3);
    modelChe(3, :) = histograma(mostra3,bins);
    models(3, :, :) = modelChe;
    
    %4 Imatges i histogrames del Madrid
    modelRM = zeros(3, 96);
    im = imread('models/rm1.jpg');
    s = im(120:220,150:250,:);
    mostra1 = equalize(s);
    modelRM(1, :)= histograma(mostra1,bins);
    im = imread('models/rm2.jpg');
    s2 = im(090:190, 120:220, :);
    mostra2 = equalize(s2);
    modelRM(2, :) = histograma(mostra2,bins);
    im = imread('models/rm3.jpg');
    s3 = im(090:190, 150:220, :);
    mostra3 = equalize(s3);
    modelRM(3, :) = histograma(mostra3,bins);
    models(4, :, :) = modelRM;
    
    %5 Imatges i histogrames de la Juventus
    modelJuv = zeros(3, 96);
    im = imread('models/juv1.jpg');
    s = im(55:120, 135:200, :);
    mostra1 = equalize(s);
    modelJuv(1, :)= histograma(mostra1,bins);
    im = imread('models/juv2.jpg');
    s2 = im(70:150, 75:135, :);
    mostra2 = equalize(s2);
    modelJuv(2, :) = histograma(mostra2,bins);
    im = imread('models/juv3.jpg');
    s3 = im(127:242, 15:130, :);
    mostra3 = equalize(s3);
    modelJuv(3, :) = histograma(mostra3,bins);
    models(5, :, :) = modelJuv;
    
    %6 Imatges i histogrames del Liverpool
    modelLiv = zeros(3, 96);
    im = imread('models/liv1.jpg');
    s = im(70:140, 276:324, :);
    mostra1 = equalize(s);
    modelLiv(1, :)= histograma(mostra1,bins);
    im = imread('models/liv2.jpg');
    s2 = im(166:256, 50:150, :);
    mostra2 = equalize(s2);
    modelLiv(2, :) = histograma(mostra2,bins);
    im = imread('models/liv3.jpg');
    s3 = im(43:100, 265:295, :);
    mostra3 = equalize(s3);
    modelLiv(3, :) = histograma(mostra3,bins);
    models(6, :, :) = modelLiv;
    
     %7 Imatges i histogrames del Psv
    modelPsv = zeros(3, 96);
    im = imread('models/psv1.jpg');
    s = im(50:107, 110:165, :);
    mostra1 = equalize(s);
    modelPsv(1, :)= histograma(mostra1,bins);
    im = imread('models/psv2.jpg');
    s2 = im(85:145, 245:285, :);
    mostra2 = equalize(s2);
    modelPsv(2, :) = histograma(mostra2,bins);
    im = imread('models/psv3.jpg');
    s3 = im(90:170, 90:150, :);
    mostra3 = equalize(s3);
    modelPsv(3, :) = histograma(mostra3,bins);
    models(7, :, :) = modelPsv;
end