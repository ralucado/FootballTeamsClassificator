%% Classificador Samarretes RGB
scanimgs('barcelona');
function[] = scanimgs(team)
    model = imread('barcelona/01.jpg');
    model = normalizeRGB(model);
    model = genHist(model);


    for i=1:40
        if i < 10 
            imCheck(imread(strcat(team,'/0', int2str(i), '.jpg')), model, i);
            if i == 1
                imshow(strcat(team,'/0', int2str(i), '.jpg'));
            end
        else
            imCheck(imread(strcat(team,'/',int2str(i), '.jpg')), model, i);
        end
    end


end

%% Funcions Auxiliars

function[] = imCheck(imT, imM, i)
    imT = normalizeRGB(imT);
    imT = seg(imT);
    found = false;
    j = 1;
    while j < 6 && ~found
        k = 1;
        while k < 6 && ~found
            
            imT(j,k).hist = genHist(imT(j,k).im);
            thres = chiq2dist(imT(j, k).hist, imM);
            disp(thres);
            if thres < 0.2
                found = true;
            end
            k = k +1;
        end
        j = j+1;
    end
    
    
    
    if found
            disp(strcat('Imatge ', int2str(i), ': Barcelona'));
    else
            disp(strcat('Imatge ',int2str(i), ': No'));
    end
end

function[hist] = genHist(im)

    [rows, cols, ~] = size(im);
    hist = zeros(16,16,16);
    
    for i=1:rows
        for j=1:cols
            %Incrementem el nombre de pixels amb aquell valor de color.
            val = im(i,j,:);
            hist(val(1),val(2),val(3))= hist(val(1),val(2),val(3))+1;
        end
    end

end

function[dist] = chiq2dist(frag, imM)
    frag = normalizeHist(frag);
    imM = normalizeHist(imM);
    [files, cols, pages]=size(frag);
    dist = 0;
    for i=1:files
       for j=1:cols
           for k=1:pages
                dist = dist + smooth(((frag(i,j,k) - imM(i,j,k)).^2)./ (frag(i,j,k) + imM(i,j,k)));
           end
       end
   end
end

function[norm] = normalizeHist(hist)
    total = sumHist(hist);
    if total ~= 0
        norm = smooth(hist./total);
    end
end

function[sm] = smooth(hist)
    hist(isnan(hist)) = 0;
    sm = hist;
end


function[segments] = seg(im)
    n = 5; m = 5;
    [rows, cols, ~] = size(im);
    rows = int16(rows/n);
    cols = int16(cols/m);
    % Segmentem la imatge en nxn fragments i les emagatzemem en una matriu
    % de fragments
    for i=1:5
        for j=1:5
            if i == n && j == m
                segments(i,j).im = im((i-1)*rows+1:end, (j-1)*cols+1:end, :);
            elseif i == n
                segments(i,j).im = im((i-1)*rows+1:end, (j-1)*cols+1:j*cols, :);
            elseif j == m
                segments(i,j).im = im((i-1)*rows+1:i*rows, (j-1)*cols+1:end, :);
            else
                segments(i,j).im = im((i-1)*rows+1:i*rows, (j-1)*cols+1:j*cols, :);
            end
        end
    end
end

function[rgb] = normalizeRGB(im)
    im = double(im);
    r = im(:,:,1);
    g = im(:,:,2);
    b = im(:,:,3);
    
    sum = r + g + b;
    r2 = double(r)./double(sum);

    g2 = double(g)./double(sum);
    

    b2 = double(b)./double(sum);

    
    rgbaux = cat(3, r2, g2, b2);
    rgb = uint8(floor(rgbaux)*15)+1;
    
end

function[sum] = sumHist(hist)
sum = 0;
    [files, cols, pages]=size(hist);
    for i=1:files
        for j=1:cols
            for k=1:pages
                sum = sum + hist(i,j,k);
            end
        end
    end
end