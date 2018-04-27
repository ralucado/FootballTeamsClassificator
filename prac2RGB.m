%% Etapa 1. Millors resultats en la primera practica
%Constants trobades provant diferents valors i fent una cerca binaria
%per optimitzar els resultats
global bins;
global num_teams; global num_hists;
num_teams = 1; %TO DO: idealment 7...
num_hists = 3;
bins = 32;
th = 0.2;
th2 = 0.019;
%% Etapa 2: Histogrames de mostra
%carreguem les imatges de mostra de cada equip
im = imread('models/bcn1.jpg');
s = im(170:270,60:160,:);
mostra1 = equalize(s);
im = imread('models/bcn2.jpg');
s2 = im(120:220,65:165,:);
mostra2 = equalize(s2);
im = imread('models/bcn3.jpg');
s3 = im(300:400,80:180,:);
mostra3 = equalize(s3);


%Creem els histogrames de les mostres
global models; %global modelBcn;
%a la variable models hi guardarem els 3 histogrames model de cada equip
models = zeros(1, 3, 96);
modelBcn = zeros(3, 96);
modelBcn(1, :)= histograma(mostra1,bins);
modelBcn(2, :) = histograma(mostra2,bins);
modelBcn(3, :) = histograma(mostra3,bins);
models(1, :, :) = modelBcn;

figure(),subplot(1,3,1), imshow(mostra1), title('bcn model 1');
subplot(1,3,2), imshow(mostra2), title('bcn model 2');
subplot(1,3,3), imshow(mostra3), title('bcn model 3');
% TO DO: Carregar models d'altres equips

%% Etapa 3. Comparacio dels histogrames de cada equip
% LLegim totes les imatges de cada equip i calculem el resultat
% Per cada foto ens sera retornat un nombre del 1 al 7 indicant l'equip
% amb mes presencia a la foto
bcn = readImgs('barcelona', th);
%madrid = readImgs('madrid', H1, H2, H3, th);
%acmilan = readImgs('acmilan', H1, H2, H3, th);
%chelsea = readImgs('chelsea', H1, H2, H3, th);
%juventus = readImgs('juventus', H1, H2, H3, th);
%liverpool = readImgs('liverpool', H1, H2, H3, th);
%psv = readImgs('psv', H1, H2, H3, th);

falsNeg = sum(bcn<=th2)/37;
disp('% falsos negatius: ');
disp(falsNeg);
falsPos = sum([madrid,acmilan,chelsea,juventus,liverpool,psv]>th2)/(6*37);
disp('% falsos positius: ');
disp(falsPos);

%% Distribucio dels resultats
c = categorical({'barcelona','madrid','milan', 'chelsea', 'juventus', 'liverpool', 'psv'});
%figure(), bar(c, [bcn;madrid;acmilan;chelsea;juventus;liverpool;psv], 'BarWidth', 1),  title('RGB 32 bins');
figure(), bar(bcn, 'BarWidth', 1),  title('RGB 32 bins');


%% Funcions auxiliars
function arr=readImgs(team, th)
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

function H=histograma(im,bins)
        R = im(:,:,1);
        G = im(:,:,2);
        B = im(:,:,3);
        H = [histcounts(R, bins, 'Normalization', 'probability'), ...
             histcounts(G, bins, 'Normalization', 'probability'), ...
             histcounts(B, bins, 'Normalization', 'probability')];
end

function EQ=equalize(im)
        imh = rgb2hsv(im);
        imh(:,:,3)=1;
        EQ = hsv2rgb(imh);
end

function index=compareImg(im, w, h, threshold)
    global bins; global models; global num_teams; global num_hists;
    [rows, cols, ~] = size(im);
    index = 0;
    maxCount = 0;
    step = 20;
    im = equalize(im);
    %Per cada equip
    for k = 1 : num_teams
        modelTeam = zeros(3, 96);
        total = 0;
        count = 0;
        for i = 1 : step : rows-h
            for j = 1: step : cols-w
                %Comparem un conjunt de sub-finestres amb els histogrames
                %model de cada equip
                d = 0;
                total = total + 1;
                for l = 1 : num_hists
                    modelTeam(1, :) = models(k, l, :);
                    part = im(i:i+w, j:j+h,:);
                    Hpart = histograma(part,bins);
                    d = d + compareHists(Hpart, modelTeam(1, :));
                end
                dT = d/3;
                if dT < threshold 
                    count = count + 1;
                end
            end
        end
        %Normalize count between 0 and 1 depending on the total samples taken
        count = count/total;
        if(count > maxCount)
            maxCount = count;
            index = k;
        end
    end
end

function D=compareHists(H1, H2)
    global bins;
    L = bins*3;
    Dreds = pdist2(H1(1:bins-1),H2(1:bins-1));
    Dgreens = pdist2(H1(bins:2*bins-1),H2(bins:2*bins-1));
    Dblues = pdist2(H1(2*bins:L),H2(2*bins:L));
    D = (Dblues+Dreds+Dgreens)/3;
end