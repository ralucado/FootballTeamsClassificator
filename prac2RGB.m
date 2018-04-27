%% Etapa 1. Millors resultats en la primera practica
%Constants trobades provant diferents valors i fent una cerca binaria
%per optimitzar els resultats
global bins;
global num_teams; global num_hists;
num_teams = 3; %TO DO: idealment 7...
num_hists = 3;
bins = 32;
th = 0.2;
th2 = 0.019;
%% Etapa 2: Histogrames de mostra
global models;
%a la variable models hi guardarem els 3 histogrames model de cada equip
models = zeros(num_teams, 3, 96);
loadHists();
%% Etapa 3. Comparacio dels histogrames de cada equip
% LLegim totes les imatges de cada equip i calculem el resultat
% Per cada foto ens sera retornat un nombre del 1 al 7 indicant l'equip
% amb mes presencia a la foto
bcn = readImgs('barcelona', th);
%madrid = readImgs('madrid', th);
acmilan = readImgs('acmilan', th);
chelsea = readImgs('chelsea', th);
%juventus = readImgs('juventus', th);
%liverpool = readImgs('liverpool', th);
%psv = readImgs('psv', th);

falsNeg = sum(bcn<=th2)/37;
disp('% falsos negatius: ');
disp(falsNeg);
falsPos = sum([acmilan,chelsea]>th2)/(2*37);
disp('% falsos positius: ');
disp(falsPos);

%% Etapa 4: Distribucio dels resultats
%c = categorical({'barcelona','madrid','milan', 'chelsea', 'juventus', 'liverpool', 'psv'});
%figure(), bar(c, [bcn;madrid;acmilan;chelsea;juventus;liverpool;psv], 'BarWidth', 1),  title('RGB 32 bins');
%Fem un grafic per veure quin valor li ha sigut assignat a cada foto
%Segons el valor de la barra sabem a quin equip pertany
%1: bcn, 2:acmilan, ... TO DO: fer que aixo es vegi maco? nose com
figure(), bar([bcn, acmilan, chelsea], 'BarWidth', 1),  title('RGB 32 bins');


%% Funcions auxiliars

function arr=readImgs(team, th)
%llegeix les imatges d'un equip i calcula l'equip al que pertany cadascuna
    arr = zeros(37:1);
    for k = 1:9
        name = sprintf(strcat(team,'/0%d.jpg'), k);
        im = imread(name);
        arr(k) = compareImg(im, 100, 100, th);
    end
    for k = 10:37
        name = sprintf(strcat(team,'/%d.jpg'), k);
        im = imread(name);
        arr(k) = compareImg(im, 100, 100, th);
    end
end

function index=compareImg(im, w, h, threshold)
%retorna l'index del equip que suposadament apareix mes a la imatge
    global bins; global models; global num_teams; global num_hists;
    [rows, cols, ~] = size(im);
    index = 0;
    maxCount = 0;
    step = 20;
    %equalitzem la imatge a testejar
    im = equalize(im);
    %Per cada equip
    for k = 1 : num_teams
        %agafem l'histograma model
        modelTeam = zeros(3, 96);
        %total es el recompte de subimatges que s'han analitzat de la foto
        %a testejar
        total = 0;
        %count es el nombre de subimatges que tenen una presencia
        %significativa del equip que s'esta avaluant
        count = 0;
        for i = 1 : step : rows-h
            for j = 1: step : cols-w
                %Comparem un conjunt de sub-finestres amb els histogrames
                %model de cada equip
                %d es un acumulador per la distancia
                %als histogrames model
                d = 0;
                total = total + 1;
                %calculem l'histograma de la part de imatge que estem
                %avaluant
                part = im(i:i+w, j:j+h,:);
                Hpart = histograma(part,bins);
                for l = 1 : num_hists
                    modelTeam(1, :) = models(k, l, :);
                    %en calculem la distancia i la sumem al acumulador
                    d = d + compareHists(Hpart, modelTeam(1, :));
                end
                %suposem que la distancia total entre l'histograma parcial
                %de test i els models es la mitja aritmetica entre els 3
                dT = d/3;
                %si aquesta distancia mitjana supera cert treshold,
                %determinem que la subimatge avaluada es prou semblant a
                %les subimatges de mostra
                if dT < threshold 
                    count = count + 1;
                end
            end
        end
        %Normalitzem el recompte fet en funcio del total de subimatges
        %avaluades.
        count = count/total;
        if(count > maxCount)
            %Guardem l'index de l'equip que ha tingut mes percentatge de
            %coincidencies amb els histogrames de mostra
            maxCount = count;
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
% TO DO: Falten models
global models; global bins;
    %1 Imatges i histogrames BCN
    im = imread('models/bcn1.jpg');
    s = im(170:270,60:160,:);
    mostra1 = equalize(s);
    im = imread('models/bcn2.jpg');
    s2 = im(120:220,65:165,:);
    mostra2 = equalize(s2);
    im = imread('models/bcn3.jpg');
    s3 = im(300:400,80:180,:);
    mostra3 = equalize(s3);
    modelBcn = zeros(3, 96);
    modelBcn(1, :)= histograma(mostra1,bins);
    modelBcn(2, :) = histograma(mostra2,bins);
    modelBcn(3, :) = histograma(mostra3,bins);
    models(1, :, :) = modelBcn;
    
    %2 Imatges i histogrames AcMilan
    modelAcm = zeros(3, 96);
    im = imread('models/acm1.jpg');
    s = im(110:210,80:180,:);
    mostra1 = equalize(s);
    modelAcm(1, :)= histograma(mostra1,bins);
    im = imread('models/acm1.jpg');
    s2 = im(110:210,80:180,:);
    mostra2 = equalize(s2);
    modelAcm(2, :) = histograma(mostra2,bins);
    im = imread('models/acm1.jpg');
    s3 = im(110:210,80:180,:);
    mostra3 = equalize(s3);
    modelAcm(3, :) = histograma(mostra3,bins);
    models(2, :, :) = modelAcm;
    
    %3 Imatges i histogrames Chelsea
    modelChe = zeros(3, 96);
    im = imread('models/che1.jpg');
    s = im(125:170, 200:250, :);
    mostra1 = equalize(s);
    modelChe(1, :)= histograma(mostra1,bins);
    im = imread('models/che2.jpg');
    s2 = im(60:120,115:170,:);
    mostra2 = equalize(s2);
    modelChe(2, :) = histograma(mostra2,bins);
    im = imread('models/che3.jpg');
    s3 = im(75:160,60:140,:);
    mostra3 = equalize(s3);
    modelChe(3, :) = histograma(mostra3,bins);
    models(3, :, :) = modelChe;
    
end