%% PRACTICA VC - DETECCIÓ D'EQUIPS DE FUTBOL
%% ETAPA 0 - Selecció variables per a realitzar el tractament de imatges

clear all;
close all;

% Variables globals que permeten modificar el tractament que es realitza
% sobre les imatges
global numEquip tractColor tipusModel soccerpath path threshold segValueX segValueY;

numEquip = -1;
tractColor = -1;
tipusModel = -1;
soccerpath = 'soccer/';
path = 'soccer/barcelona/';

threshold = 1.2;
segValueX =  5;
segValueY = 5;

% Aquest bucle permet repetir el procediment sense haver de modificar els
% parametres, simplement en temps d'execucio
while numEquip ~= 9
    % Obtenim el path del grup de samarretes a tractar
    numEquip = input('\nIndica en número del equip de futbol que vols tractar:\n1 - Barcelona\n2 - Madrid\n3 - Liverpool\n4 - ACMilan\n5 - Chelsea\n6 - PSV\n7 - Juventus\n8 - Manchester City\n9 - Exit\n');
    if numEquip > 9 || numEquip < 1
        disp('Aquest valor es erroni!');
        continue;
    elseif numEquip == 9
        continue;
    end
    path = selectPath(numEquip);
    while tractColor ~= 1 && tractColor ~= 2
        % Obtenim el com tractar el color RGB o HSV
        tractColor = input('\nIndica el mode de tractament de color:\n1 - RGB\n2 - HSV\n');
        if tractColor < 1 ||  tractColor > 2
            disp('Aquest valor es erroni!');
            continue;
        end
        while tipusModel ~= 1 && tipusModel ~= 2
            % Obtenim si apliquem la execucció en un 1 sol model (etapa 1)
            % o en diversos models.
            tipusModel = input('\nIndica el tipus de model:\n1 - Imatge model individual\n2 - Conjunts de parts imatges model \n');
            if tipusModel < 1 ||  tipusModel > 2
                disp('Aquest valor es erroni!');
                continue;
            end
            %Un cop fixats els paràmetres realitzem el tractament de les
            %imatges
            tractamentImatges();

            numEquip = 9;
        end
    end
end


%% Funcions Tractament imatges

function [path] = selectPath(value)
    global soccerpath;
    switch value
        case 1
            path = strcat(soccerpath, 'barcelona/');
        case 2
            path = strcat(soccerpath, 'madrid/');
        case 3
            path = strcat(soccerpath, 'liverpool/');
        case 4
            path = strcat(soccerpath, 'acmilan/');
        case 5
            path = strcat(soccerpath, 'chelsea/');
        case 6
            path = strcat(soccerpath, 'psv/');
        case 7
            path = strcat(soccerpath, 'juventus/');
        case 8
            path = strcat(soccerpath, 'mancity/');
    end
end

% El tractament d'imatges incorpora les 4 possibles opcions: RGB-1,
% RGB-Mult, HSV-1, HSV-Mult
function tractamentImatges()
    global tipusModel tractColor
    if tipusModel == 1 && tractColor == 1
        tractamentUnModelRGB()
    elseif tipusModel == 2 && tractColor == 1
        tractamentVarisModelsRGB()
    elseif tipusModel == 1 && tractColor == 2
        tractamentUnModelHSV()
    elseif tipusModel == 2 && tractColor == 2
        tractamentVarisModelsHSV()
    end
end

function tractamentUnModelRGB()
    global path threshold segValueX segValueY;
    % ETAPA 1 - Càlcul d'un histograma de color per a una imatge del Barça
    % Carreguem la imatge model la transformem a RGB - 16 (normalitzada)
    im = imread('soccer/models/01.jpg');
    rgb16 = im2rgb16(im);

    % Obtenim el seu histograma de color
    modHisto = im2ColorHist(rgb16);

    % ETAPA 3 - Comparació d'histogrames

    % Carreguem el dataset d'imatges de l'equip seleccionat
    for i=1:40
        if i < 10
            imtest(i).im = imread(strcat(path, '0', int2str(i), '.jpg'));
        else
            imtest(i).im = imread(strcat(path, int2str(i), '.jpg'));
        end
    end

    % Per a cada imatge la transformem a RGB16 (norm) i la segmentem
    [~, cols] = size(imtest);
    for i=1:cols
        rgb2_16 = im2rgb16(imtest(i).im);
        % Segmentem la imatge
        imtest(i).seg = imgsec(rgb2_16, segValueX, segValueY);
        % Per a cada segment calculem el seu histograma de color
        for j=1:segValueX
            for k=1:segValueY
                % Per a cada segment calculem el seu histograma de color
                imtest(i).hist(j, k).hist = im2ColorHist(imtest(i).seg(j, k).im);
                % Calculem la distancia entre el model i la imatge i
                imtest(i).dist(j,k).dist = chiSqDist(imtest(i).hist(j, k).hist, modHisto);
            end
        end
    end

    % ETAPA 4 - Determinar si cada imatge es del Barça o no
    % Cada imatge es compara ara amb el valor limit threshold per a algun
    % dels valors dels seu segments, si algún es positiu hi ha samarreta del
    % barça
    for i=1:cols
        [dist_rows, dist_cols] = size(imtest(i).dist);
        j = 1;
        found = false;
        while j <= dist_rows && ~found
            k = 1;
            while k <= dist_cols && ~found
                found = checkThresh(imtest(i).dist(j,k).dist, threshold);
                k = k + 1;
            end
        j = j + 1;
        end
        % Retorem si aquella samarreta es del barça o no
        if found
            disp(strcat('Imatge ', int2str(i), ': Barcelona'));
        else
            disp(strcat('Imatge ',int2str(i), ': No'));
        end
    end
end

function tractamentVarisModelsRGB()
    global path threshold segValueX segValueY;
    % ETAPA 2 - Càlcul de diversos histogrames a partir de imatges segmentades
    % Carreguem en aquest cas els diversos models i seleccionem només el
    % fragment de la imatge que ens interessi
    im2 = imread('soccer/models/02.jpg');
    s2.im = im2(140:200,250:290, :);
    im3 = imread('soccer/models/03.jpg');
    s3.im = im3(125:175,150:220,:);
    im4 = imread('soccer/models/04.jpg');
    s4.im = im4(80:120,130:165,:);
    im5 = imread('soccer/models/05.jpg');
    s5.im = im5(300:400,80:200,:);

    %Ara obtenim la imatge en rgb16 i els seu histograma de color per a
    %cadascun dels models
    im_vec = [s2 s3 s4 s5];
    for i=1:4
        rgb2_16 = im2rgb16(im_vec(i).im);
        model_vec(i).hist = im2ColorHist(rgb2_16);
    end

    % ETAPA 3 - Comparació d'histogrames
    % Carreguem les imatges del dataset seleccionat
    for i=1:40
        if i < 10
            imtest(i).im = imread(strcat(path, '0', int2str(i), '.jpg'));
        else
            imtest(i).im = imread(strcat(path, int2str(i), '.jpg'));
        end
    end

    % Tractem ara cada imatge, conversio a rgb16 i obtencio del seu
    % histograma de color, en aquest cas per això calculem la distancia a
    % comparar amb el threshold per a cadascun dels models.
    [~, cols] = size(imtest);
    [~, model_cols] = size(model_vec);
    for i=1:cols
        rgb2_16 = im2rgb16(imtest(i).im);
        imtest(i).seg = imgsec(rgb2_16, segValueX, segValueY);
        for j=1:segValueX
            for k=1:segValueY
                imtest(i).hist(j, k).hist = im2ColorHist(imtest(i).seg(j, k).im);
                % Sobte la distancia respecte a cada model.
                for l=1:model_cols
                    imtest(i).dist(j,k).dist(l) = chiSqDist(imtest(i).hist(j, k).hist, model_vec(l).hist);
                end
            end
        end
    end
    % ETAPA 4 - Determinar si cada imatge es del Barça o no
    % En aquest cas mirarem respecte a quants models ha fet match amb el
    % threshold es a dir no supera el llindar, i nomes si la meitat o mes de
    % models retornen positiu considerarem que la samarreta es del barça
    for i=1:cols
        [dist_rows, dist_cols] = size(imtest(i).dist);
        nfounds = 0;
        for l=1:model_cols
            j = 1;
            found = false;
            while j <= dist_rows && ~found
                k = 1;
                while k <= dist_cols && ~found
                    found = checkThresh(imtest(i).dist(j,k).dist(l), threshold);
                    if found
                        nfounds = nfounds + 1;
                    end
                    k = k + 1;
                end
            j = j + 1;
            end
        end
        if nfounds >= (model_cols / 2)
            disp(strcat('Imatge ', int2str(i), ': Barça'));
        else
            disp(strcat('Imatge ',int2str(i), ': No'));
        end
    end
end

% ETAPA 5 - Repetir amb HSV
% Els compentaris per a HSV serian analogs a RGB amb la diferencia que
% s'apliquen les funcions 'im2hsv16' i 'im2ColorHistHSV'
function tractamentUnModelHSV()
    global path threshold segValueX segValueY;
    % ETAPA 1 - Càlcul d'un histograma de color per a una imatge del Barça
    im = imread('soccer/models/01.jpg');
    hsv16 = im2hsv16(im);
    modHisto = im2ColorHistHSV(hsv16);

    % ETAPA 3 - Comparació d'histogrames

    for i=1:40
        if i < 10
            imtest(i).im = imread(strcat(path, '0', int2str(i), '.jpg'));
        else
            imtest(i).im = imread(strcat(path, int2str(i), '.jpg'));
        end
    end
    [~, cols] = size(imtest);
    for i=1:cols
        hsv2_16 = im2hsv16(imtest(i).im);
        imtest(i).seg = imgsec(hsv2_16, segValueX, segValueY);
        for j=1:segValueX
            for k=1:segValueY
                imtest(i).hist(j, k).hist = im2ColorHistHSV(imtest(i).seg(j, k).im);
                imtest(i).dist(j,k).dist = chiSqDist(imtest(i).hist(j, k).hist, modHisto);
            end
        end
    end

    % ETAPA 4 - Determinar si cada imatge es del Barça o no
    for i=1:cols
        [dist_rows, dist_cols] = size(imtest(i).dist);
        j = 1;
        found = false;
        while j <= dist_rows && ~found
            k = 1;
            while k <= dist_cols && ~found
                found = checkThresh(imtest(i).dist(j,k).dist, threshold);
                k = k + 1;
            end
        j = j + 1;
        end
        if found
            disp(strcat('Imatge ', int2str(i), ': Barça'));
        else
            disp(strcat('Imatge ',int2str(i), ': No'));
        end
    end
end

function tractamentVarisModelsHSV()
    global path threshold segValueX segValueY;
    % ETAPA 2 - Càlcul de diversos histogrames a partir de imatges segmentades
    im2 = imread('soccer/models/02.jpg');
    s2.im = im2(140:200,250:290, :);
    im3 = imread('soccer/models/03.jpg');
    s3.im = im3(125:175,150:220,:);
    im4 = imread('soccer/models/04.jpg');
    s4.im = im4(80:120,130:165,:);
    im5 = imread('soccer/models/05.jpg');
    s5.im = im5(300:400,80:200,:);
    im_vec = [s2 s3 s4 s5];
    for i=1:4
        hsv2_16 = im2hsv16(im_vec(i).im);
        model_vec(i).hist = im2ColorHistHSV(hsv2_16);
    end
    % ETAPA 3 - Comparació d'histogrames
    for i=1:40
        if i < 10
            imtest(i).im = imread(strcat(path, '0', int2str(i), '.jpg'));
        else
            imtest(i).im = imread(strcat(path, int2str(i), '.jpg'));
        end
    end
    [~, cols] = size(imtest);
    [~, model_cols] = size(model_vec);
    for i=1:cols
        hsv2_16 = im2hsv16(imtest(i).im);
        imtest(i).seg = imgsec(hsv2_16, segValueX, segValueY);
        for j=1:segValueX
            for k=1:segValueY
                imtest(i).hist(j, k).hist = im2ColorHistHSV(imtest(i).seg(j, k).im);
                for l=1:model_cols
                    imtest(i).dist(j,k).dist(l) = chiSqDist(imtest(i).hist(j, k).hist, model_vec(l).hist);
                end
            end
        end
    end
    % ETAPA 4 - Determinar si cada imatge es del Barça o no
    for i=1:cols
        [dist_rows, dist_cols] = size(imtest(i).dist);
        nfounds = 0;
        for l=1:model_cols
            j = 1;
            found = false;
            while j <= dist_rows && ~found
                k = 1;
                while k <= dist_cols && ~found
                    found = checkThresh(imtest(i).dist(j,k).dist(l), threshold);
                    if found
                        nfounds = nfounds + 1;
                    end
                    k = k + 1;
                end
            j = j + 1;
            end
        end
        if nfounds >= (model_cols / 2)
            disp(strcat('Imatge ', int2str(i), ': Barça'));
        else
            disp(strcat('Imatge ',int2str(i), ': No'));
        end
    end
end

%% Funcions Auxiliars

function [rgb16] = im2rgb16(im)
    im = double(im);
    R = im(:,:,1);
    G = im(:,:,2);
    B = im(:,:,3);

    %Normalitzem components RGB
    sum = (R+G+B);
    r = R./sum;
    g = G./sum;
    b = B./sum;

    rgb01 = cat(3,r,g,b);

    rgb01(isnan(rgb01))=0;

    % pasem de [0..1]->[1..16] per a tenir 16 possibles valors nomes
    rgb16 = uint8(floor(rgb01 * 15) + 1);
end

function [rgb16] = im2hsv16(im)
im = rgb2hsv(im);
% pasem de [0..1]->[1..16] per a tenir 16 possibles valors nomes (HSV ja esta normalitzat)
rgb16 = uint8(floor(im * 15) + 1);
end

function [imgs] = imgsec(im, n, m)
    [rows, cols, ~] = size(im);
    rsize = int16(rows / n);
    csize = int16(cols / m);
    % Segmentem la imatge en nxn fragments i les emagatzemem en una matriu
    % de fragments
    for i=1:n
        for j=1:m
            if i == n && j == m
                imgs(i,j).im = im((i-1)*rsize+1:end, (j-1)*csize+1:end, :);
            elseif j == m
                imgs(i,j).im = im((i-1)*rsize+1:i*rsize, (j-1)*csize+1:end, :);
            elseif i == n
                imgs(i,j).im = im((i-1)*rsize+1:end, (j-1)*csize+1:j*csize, :);
            else
                imgs(i,j).im = im((i-1)*rsize+1:i*rsize, (j-1)*csize+1:j*csize, :);
            end
        end
    end
end

function [dist] = chiSqDist(h1, h2)
   % normalitzem els histogrames de color per a comparar valors equivalents
   % si les mides de les imatges no són iguals
   h1 = normHist(h1);
   h2 = normHist(h2);
   dist = 0;
   [files, cols, prof]=size(h1);
   for i=1:files
       for j=1:cols
           for k=1:prof
               % Per cada conj de valors (ri,gi,bi) es calcula la distancia
               % entre els 2 histogrames i s'acumula.
                dist = dist + NaN2Zero(((h1(i,j,k) - h2(i,j,k)).^2)./ (h1(i,j,k) + h2(i,j,k)));
           end
       end
   end
end

function [sum] = sum3D(A)
    % Sumem matrius 3D per a obtenir un sol valor total
    sum = 0;
    [files, cols, prof]=size(A);
    for i=1:files
        for j=1:cols
            for k=1:prof
                sum = sum + A(i,j,k);
            end
        end
    end
end

function [h1] = normHist(h1)
    % Normlitzem el histograma ( o la matriu en general) dividint pel total
    % de la suma dels seus elements.
    total = sum3D(h1);
    if total ~= 0
        h1 = NaN2Zero(h1./total);
    end
end

function [res] = NaN2Zero(x)
    %Tractament dels NaN perque retornin zero.
    res = x;
    if isnan(x)
        res = 0;
    end
end

function [res] = checkThresh(dist, thresh)
    %Compara el threshold amb un valor donat
    res = dist <= thresh;
end

function [histo] = im2ColorHist(rgb16)
    % Genera el histograma de color en 3D RGB simplement per a cada
    % combinacio rgb mira quants elements de la imatge tenen aquella
    % combinació acumulant-ho en una matriu de sortida
    [files, cols, ~]=size(rgb16);
    histo=zeros(16,16,16);
    for i=1:files
        for j=1:cols
            %Incrementem el nombre de pixels amb aquell valor de color.
            pix16col = rgb16(i, j, :);
            histo(pix16col(1),pix16col(2), pix16col(3))= histo(pix16col(1),pix16col(2), pix16col(3)) + 1;
        end
    end
end

function [histo] = im2ColorHistHSV(rgb16)
    [files, cols, ~]=size(rgb16);
    histo=zeros(16,16);
    for i=1:files
        for j=1:cols
            %Incrementem el nombre de pixels amb aquell valor de gris.
            pix16col = rgb16(i, j, 1:2);
            histo(pix16col(1),pix16col(2))= histo(pix16col(1),pix16col(2)) + 1;
        end
    end
end
