%% =========================================================
%  PRÁCTICA HSI: Identificación composicional en industria cárnica
%  M2026 – Técnicas para el Monitorizado y Control de Procesos Industriales
%  Universidad de Cantabria
% =========================================================
%  ESTRUCTURA DE ARCHIVOS ESPERADA:
%    /ph_carne/VISNIR/carne.mat       -> cubo HSI de la cubeta de carne
%    /ph_carne/VISNIR/carne_b.mat     -> blanco de la cubeta de carne
%    /cal/VISNIR/spect_cal.mat        -> cubo HSI de discos de calibración
%    /cal/VISNIR/spect_cal_b.mat      -> blanco de los discos de calibración
%    /cal/pinkref.mat                 -> espectro de referencia WCS-MC-020
% =========================================================

clc; clear; close all;

%% =========================================================
%  PASO 1: CARGAR DATOS
% =========================================================
fprintf('=== PASO 1: Cargando datos ===\n');

% --- Cubeta de carne (VISNIR) ---
data_carne   = load('carne.mat');
data_carne_b = load('carne_b.mat');

% --- Imágenes de calibración (VISNIR) ---
data_cal   = load('spect_cal.mat');
data_cal_b = load('spect_cal_b.mat');

% --- Referencia espectral WCS-MC-020 ---
data_pinkref = load('pinkref.mat');

% Extraer los cubos (se asume que el cubo 3D es el primer campo de la estructura)
campos_carne   = fieldnames(data_carne);
campos_carne_b = fieldnames(data_carne_b);
campos_cal     = fieldnames(data_cal);
campos_cal_b   = fieldnames(data_cal_b);
campos_pink    = fieldnames(data_pinkref);

Smp_carne   = double(data_carne.(campos_carne{1}));      % (X, Y, L)
W_carne     = double(data_carne_b.(campos_carne_b{1}));  % blanco carne
Smp_cal     = double(data_cal.(campos_cal{1}));          % (X, Y, L) cal
W_cal       = double(data_cal_b.(campos_cal_b{1}));      % blanco cal
pinkref     = double(data_pinkref.(campos_pink{1}));     % referencia WCS

fprintf('Cubo carne     -> Tamaño: %d x %d x %d (X x Y x L)\n', size(Smp_carne));
fprintf('Cubo cal       -> Tamaño: %d x %d x %d (X x Y x L)\n', size(Smp_cal));

% Número de bandas espectrales (eje L)
nBands_carne = size(Smp_carne, 3);
nBands_cal   = size(Smp_cal,   3);

% Vector de índices de banda (provisional, se calibrará en el paso 5)
lambda_idx_carne = 1:nBands_carne;
lambda_idx_cal   = 1:nBands_cal;


%% =========================================================
%  PASO 2: VISUALIZAR LA CUBETA DE CARNE (imagen 2D promedio espectral)
% =========================================================
fprintf('\n=== PASO 2: Visualizando cubeta de carne ===\n');

img2D_carne = mean(Smp_carne, 3);   % promedio a lo largo del eje espectral L

figure('Name','Paso 2 – Cubeta de carne (promedio espectral)','NumberTitle','off');
imagesc(img2D_carne);
colormap(gray); colorbar;
title('Cubeta de carne – promedio espectral (VISNIR)', 'FontSize', 13);
xlabel('Eje Y (píxeles)'); ylabel('Eje X (píxeles)');
axis image;

fprintf('Dimensiones imagen carne: X=%d, Y=%d, L=%d\n', ...
    size(Smp_carne,1), size(Smp_carne,2), size(Smp_carne,3));
fprintf('Identifica visualmente la orientación de la cubeta y las celdas A1-C8.\n');


%% =========================================================
%  PASO 3: VISUALIZAR EL MATERIAL DE CALIBRACIÓN
% =========================================================
fprintf('\n=== PASO 3: Material de calibración ===\n');

img2D_cal = mean(Smp_cal, 3);

figure('Name','Paso 3 – Material de calibración (promedio espectral)','NumberTitle','off');
imagesc(img2D_cal);
colormap(gray); colorbar;
title('Discos de calibración – promedio espectral (VISNIR)', 'FontSize', 13);
xlabel('Eje Y (píxeles)'); ylabel('Eje X (píxeles)');
axis image;

% ----- 3a: Seleccionar ROIs en los dos discos y graficar espectros -----
fprintf('\nPASO 3a: Selecciona ROI en el disco SRS-99 (blanco) – dibuja un rectángulo\n');
figure('Name','Paso 3a – Selección ROIs calibración','NumberTitle','off');
imagesc(img2D_cal); colormap(gray); colorbar; axis image;
title('Selecciona ROI en disco SRS-99 (blanco, ~99% reflectancia)', 'FontSize', 11);

roi1 = drawrectangle('Color','b','Label','SRS-99');
wait(roi1);
pos1 = round(roi1.Position);   
r1 = pos1(2) : pos1(2)+pos1(4)-1;
c1 = pos1(1) : pos1(1)+pos1(3)-1;
r1 = max(1,r1(1)) : min(size(Smp_cal,1), r1(end));
c1 = max(1,c1(1)) : min(size(Smp_cal,2), c1(end));

fprintf('Selecciona ROI en el disco WCS-MC-020 (referencia espectral) – dibuja un rectángulo\n');
title('Selecciona ROI en disco WCS-MC-020 (referencia espectral)', 'FontSize', 11);
roi2 = drawrectangle('Color','r','Label','WCS-MC-020');
wait(roi2);
pos2 = round(roi2.Position);
r2 = pos2(2) : pos2(2)+pos2(4)-1;
c2 = pos2(1) : pos2(1)+pos2(3)-1;
r2 = max(1,r2(1)) : min(size(Smp_cal,1), r2(end));
c2 = max(1,c2(1)) : min(size(Smp_cal,2), c2(end));

% Espectros promedio sin corrección
spec_srs99_raw = squeeze(mean(mean(Smp_cal(r1, c1, :), 1), 2));
spec_wcs_raw   = squeeze(mean(mean(Smp_cal(r2, c2, :), 1), 2));

figure('Name','Paso 3a – Espectros crudos de calibración','NumberTitle','off');
plot(lambda_idx_cal, spec_srs99_raw, 'b-', 'LineWidth', 1.5); hold on;
plot(lambda_idx_cal, spec_wcs_raw,   'r-', 'LineWidth', 1.5);
legend('SRS-99-020 (99% reflectancia)', 'WCS-MC-020 (ref. espectral)', ...
       'Location', 'best');
xlabel('Índice de banda'); ylabel('Nivel digital (DN)');
title('Paso 3a – Espectros crudos de los discos de calibración', 'FontSize', 12);
grid on;

% ----- 3b: Corrección en reflectancia del material de calibración -----
%  R(x,y,λ) = (Smp(x,y,λ) - B(x,y,λ)) / (W(x,y,λ) - B(x,y,λ))
%  B = 0 en esta práctica
fprintf('\nPASO 3b: Corrección en reflectancia del material de calibración\n');

% Ajustar dimensiones si es necesario
if ~isequal(size(Smp_cal), size(W_cal))
    fprintf('  Las dimensiones de spect_cal y spect_cal_b difieren. Aplicando resize...\n');
    W_cal_r = imresize(W_cal, [size(Smp_cal,1), size(Smp_cal,2)]);
    % resize en dimensión espectral si es necesario
    if size(W_cal_r,3) ~= size(Smp_cal,3)
        W_cal_r = interpn(W_cal_r, ...
            linspace(1,size(W_cal_r,1),size(Smp_cal,1)), ...
            linspace(1,size(W_cal_r,2),size(Smp_cal,2)), ...
            linspace(1,size(W_cal_r,3),size(Smp_cal,3)));
    end
else
    W_cal_r = W_cal;
end

% Corrección: B = 0 => R = Smp / W
R_cal = Smp_cal ./ (W_cal_r + eps);   % eps evita división por cero
R_cal = max(0, min(1, R_cal));         % recortar a [0, 1]

% ----- 3c: Espectros corregidos -----
fprintf('PASO 3c: Espectros corregidos en reflectancia\n');
spec_srs99_corr = squeeze(mean(mean(R_cal(r1, c1, :), 1), 2));
spec_wcs_corr   = squeeze(mean(mean(R_cal(r2, c2, :), 1), 2));

figure('Name','Paso 3c – Espectros corregidos de calibración','NumberTitle','off');
plot(lambda_idx_cal, spec_srs99_corr, 'b-', 'LineWidth', 1.5); hold on;
plot(lambda_idx_cal, spec_wcs_corr,   'r-', 'LineWidth', 1.5);
legend('SRS-99-020 (99% reflectancia)', 'WCS-MC-020 (ref. espectral)', ...
       'Location', 'best');
xlabel('Índice de banda'); ylabel('Reflectancia (0-1)');
title('Paso 3c – Espectros corregidos en reflectancia', 'FontSize', 12);
grid on;


%% =========================================================
%  PASO 4: ESPECTRO DE REFERENCIA WCS-MC-020 (pinkref.mat)
% =========================================================
fprintf('\n=== PASO 4: Espectro referencia WCS-MC-020 ===\n');

spec_pinkref = pinkref(:,2);
lambda_pink  = pinkref(:,1);   % longitudes de onda REALES del datasheet (nm)

figure('Name','Paso 4 – Referencia WCS-MC-020','NumberTitle','off');
plot(lambda_pink, spec_pinkref, 'm-', 'LineWidth', 1.5);
xlabel('Longitud de onda (nm)'); ylabel('Reflectancia / Intensidad');
title('Paso 4 – Espectro referencia WCS-MC-020 (pinkref)', 'FontSize', 12);
grid on;

% Detectar picos y valles en el espectro de referencia
[pks_val, pks_loc] = findpeaks(spec_pinkref,  'MinPeakProminence', 0.02);
[val_val, val_loc] = findpeaks(-spec_pinkref, 'MinPeakProminence', 0.02);
val_val = -val_val;

hold on;
plot(lambda_pink(pks_loc), pks_val, 'rv', 'MarkerSize', 8, 'DisplayName', 'Picos');
plot(lambda_pink(val_loc), val_val, 'b^', 'MarkerSize', 8, 'DisplayName', 'Valles');
legend('Espectro WCS','Picos','Valles','Location','best');

fprintf('Picos detectados en lambda (nm): %s\n', num2str(lambda_pink(pks_loc)'));
fprintf('Valles detectados en lambda (nm): %s\n', num2str(lambda_pink(val_loc)'));


%% =========================================================
%  PASO 5: CALIBRACIÓN DEL EJE ESPECTRAL (ajuste por mínimos cuadrados)
% =========================================================
fprintf('\n=== PASO 5: Calibración del eje espectral ===\n');
fprintf('Introduce las correspondencias entre índices de banda y longitudes\n');
fprintf('de onda conocidas del WCS-MC-020 (valores del datasheet de Labsphere).\n\n');

% --- Puntos de calibración ---
cal_points = [    % [índice_banda,  lambda_nm]
    96,   423.217;    
    201,  478.932;    
    251,  502.810;    
    284,  537.373;    
    528,  650.216;    
    712,  748.964;    
    796,  797.834;    
    962,  881.225;    
    988,  911.206;    
];

idx_cal_pts    = cal_points(:, 1);
lambda_cal_pts = cal_points(:, 2);

% Ajuste polinomial de grado 1 (lineal) o grado 2 por mínimos cuadrados
grado = 2;   
p = polyfit(idx_cal_pts, lambda_cal_pts, grado);

fprintf('Coeficientes del ajuste polinomial (grado %d):\n', grado);
disp(p);

% Generar ejes de longitud de onda calibrados
lambda_cal_cal  = polyval(p, lambda_idx_cal);   % para imágenes de calibración
lambda_cal_carne = polyval(p, (1:nBands_carne)'); % para imagen de carne (si mismo sensor)

figure('Name','Paso 5 – Calibración eje espectral','NumberTitle','off');
plot(lambda_cal_cal, spec_wcs_corr, 'r-', 'LineWidth', 1.5); hold on;
plot(lambda_cal_pts, ones(size(lambda_cal_pts))*max(spec_wcs_corr)*0.9, ...
     'kv', 'MarkerSize', 10, 'DisplayName', 'Puntos de calibración');
xlabel('Longitud de onda (nm)'); ylabel('Reflectancia (0-1)');
title('Paso 5 – Espectro WCS con eje calibrado en nm', 'FontSize', 12);
legend('WCS-MC-020 corregido','Puntos cal.','Location','best');
grid on;

% --- Verificación post-calibración ---

% 1. Comprobar que el rango espectral resultante es coherente con VISNIR (400-1000 nm)
fprintf('Rango espectral calibrado: %.1f nm  a  %.1f nm\n', ...
    lambda_cal_carne(1), lambda_cal_carne(end));

% 2. Comprobar que la dispersión espectral (nm/banda) es uniforme y razonable
dispersion = diff(lambda_cal_carne);
fprintf('Dispersión espectral: %.3f ± %.4f nm/banda\n', ...
    mean(dispersion), std(dispersion));

% 3. Superposición del espectro calibrado sobre el de referencia para inspección visual
figure('Name','Verificación calibración final','NumberTitle','off');
yyaxis left
plot(lambda_cal_cal, spec_wcs_corr, 'r-', 'LineWidth', 1.5);
ylabel('Reflectancia medida (0-1)');
yyaxis right
plot(lambda_pink, spec_pinkref, 'm--', 'LineWidth', 1.2);
ylabel('Reflectancia datasheet');
xlabel('Longitud de onda (nm)');
title('Verificación: espectro medido vs datasheet (mismo eje nm)', 'FontSize', 12);
legend('WCS medido (calibrado)', 'WCS datasheet', 'Location', 'best');
grid on;

%% =========================================================
%  PASO 6: CORRECCIÓN EN REFLECTANCIA DE LA CUBETA DE CARNE
% =========================================================
fprintf('\n=== PASO 6: Corrección en reflectancia de la cubeta de carne ===\n');

% Ajustar dimensiones si es necesario
if ~isequal(size(Smp_carne), size(W_carne))
    fprintf('  Dimensiones diferentes entre carne y blanco. Aplicando resize...\n');
    W_carne_r = imresize(W_carne, [size(Smp_carne,1), size(Smp_carne,2)]);
    if size(W_carne_r,3) ~= size(Smp_carne,3)
        W_carne_r = interpn(W_carne_r, ...
            linspace(1,size(W_carne_r,1),size(Smp_carne,1)), ...
            linspace(1,size(W_carne_r,2),size(Smp_carne,2)), ...
            linspace(1,size(W_carne_r,3),size(Smp_carne,3)));
    end
else
    W_carne_r = W_carne;
end

% Corrección: B = 0 => R = Smp / W
R_carne = Smp_carne ./ (W_carne_r + eps);
R_carne = max(0, min(1, R_carne));

% Visualización de la imagen corregida
img2D_carne_corr = mean(R_carne, 3);

figure('Name','Paso 6 – Cubeta de carne corregida en reflectancia','NumberTitle','off');
imagesc(img2D_carne_corr);
colormap(gray); colorbar;
title('Cubeta de carne – reflectancia corregida (VISNIR)', 'FontSize', 13);
xlabel('Eje Y (píxeles)'); ylabel('Eje X (píxeles)');
axis image;

% =========================================================
%  PASO 6b: RECORTE (CROP) DE LA IMAGEN YA CORREGIDA
% =========================================================
fprintf('\n=== PASO 6b: Recorte de la paleta de muestras ===\n');
fprintf('Dibuja un rectángulo alrededor de las 24 cubetas y haz DOBLE CLIC.\n');

% Usamos la imagen ya corregida en reflectancia para guiarnos
figure('Name', 'Paso 6b - Recorte de Paleta', 'NumberTitle', 'off');
[~, rect_crop] = imcrop(img2D_carne_corr / max(img2D_carne_corr(:)));
close;

% Coordenadas del recorte
x = max(1, round(rect_crop(1))); 
y = max(1, round(rect_crop(2)));
w = round(rect_crop(3)); 
h = round(rect_crop(4));

% Recortamos el cubo de reflectancia final (que es el que importa para el modelo)
R_carne = R_carne(y:y+h, x:x+w, :);

% Actualizamos la imagen 2D para el Paso 7
img2D_carne_corr = mean(R_carne, 3);

% Borramos los datos crudos originales para liberar memoria RAM
clear Smp_carne W_carne W_carne_r data_carne;
fprintf('Cubo corregido y recortado a: %dx%d píxeles. Memoria liberada.\n', size(R_carne, 1), size(R_carne, 2));

%% =========================================================
%  PASO 7: EXTRACCIÓN DE LA PALETA COMPLETA (24 MUESTRAS)
% =========================================================
fprintf('\n=== PASO 7: Extracción de firmas para entrenamiento ===\n');
filas = {'A', 'B', 'C'};
spectra_all = zeros(24, nBands_carne); % 3 filas * 8 columnas
count = 1;

for f = 1:3
    figure('Name',['Selección Fila ', filas{f}],'NumberTitle','off');
    imagesc(img2D_carne_corr); colormap(gray); axis image; hold on;
    
    for k = 1:8
        msg = sprintf('Selecciona ROI %s%d (Recuerda: Col 1 está a la DERECHA)', filas{f}, k);
        title(msg);
        roi_tmp = drawrectangle('Color', 'y', 'Label', [filas{f}, num2str(k)]);
        wait(roi_tmp);
        
        pos_tmp = round(roi_tmp.Position);
        rr = max(1,pos_tmp(2)) : min(size(R_carne,1), pos_tmp(2)+pos_tmp(4)-1);
        cc = max(1,pos_tmp(1)) : min(size(R_carne,2), pos_tmp(1)+pos_tmp(3)-1);
        
        spectra_all(count,:) = squeeze(mean(mean(R_carne(rr, cc, :), 1), 2));
        count = count + 1;
    end
    close; % Cerrar para no saturar de ventanas
end

%% =========================================================
%  PASO 8: MÉTRICAS DE CONTRASTE (Referencia Automática A1)
% =========================================================
fprintf('\n=== PASO 8: Calculando métricas de contraste respecto a A1 (Tocino) ===\n');

% Se usa la primera fila de spectra_all que corresponde a A1 (seleccionada en el Paso 7)
y_ref = spectra_all(1, :); 

[Nx, Ny, NL] = size(R_carne);
X_flat = reshape(R_carne, Nx*Ny, NL);

% --- (1) Distancia Euclídea (ED) ---
diff_ED  = X_flat - y_ref;
ED_flat  = sqrt(sum(diff_ED.^2, 2));
img_ED   = reshape(ED_flat, Nx, Ny);

% --- (2) Spectral Angle Mapper (SAM) ---
dot_prod   = X_flat * y_ref';
norm_x     = sqrt(sum(X_flat.^2, 2));
norm_y     = sqrt(sum(y_ref.^2));
cos_angle  = dot_prod ./ (norm_x * norm_y + eps);
cos_angle  = max(-1, min(1, cos_angle)); 
img_SAM    = reshape(acos(cos_angle), Nx, Ny);

% Visualización
figure('Name','Paso 8 – Comparativa de Similitud (Referencia A1)','NumberTitle','off');
subplot(1,2,1);
imagesc(img_ED); axis image; colorbar; colormap(hot);
title('Distancia Euclídea (Menor es más parecido)');

subplot(1,2,2);
imagesc(img_SAM); axis image; colorbar; colormap(jet);
title('Ángulo Espectral (SAM)');

%% =========================================================
%  PASO 9: ENTRENAMIENTO CON DATOS CONOCIDOS (con validación y selección óptima de componentes)
% =========================================================
% Crea una matriz de 24 filas y 3 columnas [Novilla, Cerdo, Tocino]
% Debe mantener el orden de la selección de ROIs (A1..A8, B1..B8, C1..C8)
 
% --- RELLENA AQUÍ TUS DATOS REALES ---
Y_train = [
    % Fila A (A1 a A8)
    0,   0,   100; % A1 (Tocino puro)
    75,  35,  0;   % A2
    50,  50,  0;   % A3
    25,  75,  0;   % A4
    47.5,   47.5,   5;  % A5
    45,     45,     10; % A6
    42.5,   42.5,   15; % A7
    40,     40,     20; % A8
    % Fila B (B1 a B8)
    100, 0,   0;   % B1 (Novilla pura)
    95,  0,   5;   % B2
    90,  0,   10;  % B3
    85,  0,   15;  % B4
    80,  0,   20;  % B5
    75,  0,   25;  % B6
    50,  0,   50;  % B7
    25,  0,   75;  % B8
    % Fila C (C1 a C8)
    0,   100, 0;   % C1 (Cerdo puro)
    0,   95,  5;   % C2
    0,   90,  10;  % C3
    0,   85,  15;  % C4
    0,   80,  20;  % C5
    0,   75,  25;  % C6
    0,   50,  50;  % C7
    0,   25,  75;  % C8
];
 
% Verificar que los porcentajes suman ~100 en cada muestra
sumas = sum(Y_train, 2);
if any(abs(sumas - 100) > 1)
    fprintf('  AVISO: Algunas filas de Y_train no suman exactamente 100%%:\n');
    for i = find(abs(sumas - 100) > 1)'
        fprintf('    Fila %d: suma = %.1f\n', i, sumas(i));
    end
end
 
% ---- 9a: Normalización de espectros (centrado y escalado por SNV) ----
% Standard Normal Variate (SNV): resta media y divide por desviación estándar de cada espectro
% Elimina variaciones de escattering y de escala de intensidad
fprintf('\n--- Paso 9a: Normalizando espectros de entrenamiento (SNV) ---\n');
mu_sp    = mean(spectra_all, 2);           % media de cada espectro (24x1)
sigma_sp = std(spectra_all, 0, 2);         % std de cada espectro (24x1)
sigma_sp(sigma_sp < eps) = 1;              % evitar división por cero
X_train_norm = (spectra_all - mu_sp) ./ sigma_sp;   % (24 x nBands)
 
% ---- 9b: Selección óptima de componentes PLS por validación cruzada LOO ----
fprintf('--- Paso 9b: Seleccionando nComp óptimo por validación cruzada (LOO) ---\n');
nSamples  = size(X_train_norm, 1);
nComp_max = min(10, nSamples - 2);   % no más de n-2 para LOO estable
RMSE_cv   = zeros(nComp_max, 3);     % (nComp, 3 componentes Y)
 
for nc = 1:nComp_max
    Y_pred_loo = zeros(nSamples, 3);
    for i = 1:nSamples
        idx_train_loo = setdiff(1:nSamples, i);
        X_loo = X_train_norm(idx_train_loo, :);
        Y_loo = Y_train(idx_train_loo, :);
        [~,~,~,~, BETA_loo] = plsregress(X_loo, Y_loo, nc);
        x_test = X_train_norm(i, :);
        Y_pred_loo(i, :) = [1, x_test] * BETA_loo;
    end
    Y_pred_loo = max(0, min(100, Y_pred_loo));
    for c = 1:3
        RMSE_cv(nc, c) = sqrt(mean((Y_train(:,c) - Y_pred_loo(:,c)).^2));
    end
end
 
% Seleccionar nComp que minimiza el RMSE medio de las 3 clases
RMSE_cv_mean = mean(RMSE_cv, 2);
[~, nComp_opt] = min(RMSE_cv_mean);
fprintf('  nComp óptimo seleccionado: %d (RMSE_CV medio = %.2f%%)\n', ...
    nComp_opt, RMSE_cv_mean(nComp_opt));
 
% Representar la curva de validación cruzada
figure('Name','Paso 9b – Selección de componentes PLS (LOO-CV)','NumberTitle','off');
plot(1:nComp_max, RMSE_cv(:,1), 'b-o', 'LineWidth', 1.5, 'DisplayName', 'Novilla'); hold on;
plot(1:nComp_max, RMSE_cv(:,2), 'r-s', 'LineWidth', 1.5, 'DisplayName', 'Cerdo');
plot(1:nComp_max, RMSE_cv(:,3), 'g-^', 'LineWidth', 1.5, 'DisplayName', 'Tocino');
plot(1:nComp_max, RMSE_cv_mean,  'k--', 'LineWidth', 2,   'DisplayName', 'Media');
xline(nComp_opt, 'm--', sprintf('nComp=%d', nComp_opt), 'LineWidth', 1.5);
xlabel('Número de componentes PLS'); ylabel('RMSE-CV (%)');
title('Paso 9b – Validación cruzada LOO: selección de componentes', 'FontSize', 12);
legend('Location','best'); grid on;
 
% ---- 9c: Entrenamiento final con nComp óptimo ----
fprintf('--- Paso 9c: Entrenando modelo final con nComp=%d ---\n', nComp_opt);
[XL, YL, XS, YS, BETA] = plsregress(X_train_norm, Y_train, nComp_opt);
 
% Guardar parámetros de normalización SNV para aplicar sobre nuevas muestras
SNV_mu    = mu_sp;
SNV_sigma = sigma_sp;
 
% ---- 9d: Métricas de calidad sobre el conjunto de entrenamiento ----
Y_pred_train = max(0, min(100, [ones(nSamples,1), X_train_norm] * BETA));
nombres_comp = {'Novilla', 'Cerdo', 'Tocino'};
fprintf('\n  --- Métricas sobre el conjunto de entrenamiento ---\n');
fprintf('  %-10s  %6s  %6s\n', 'Componente', 'R²', 'RMSE(%%)');
R2_train   = zeros(1,3);
RMSE_train = zeros(1,3);
for c = 1:3
    ss_res = sum((Y_train(:,c) - Y_pred_train(:,c)).^2);
    ss_tot = sum((Y_train(:,c) - mean(Y_train(:,c))).^2);
    R2_train(c)   = 1 - ss_res / (ss_tot + eps);
    RMSE_train(c) = sqrt(mean((Y_train(:,c) - Y_pred_train(:,c)).^2));
    fprintf('  %-10s  %6.4f  %6.2f\n', nombres_comp{c}, R2_train(c), RMSE_train(c));
end
 
% Figura de paridad (predicho vs real) para las 3 clases
figure('Name','Paso 9d – Paridad entrenamiento (predicho vs real)','NumberTitle','off');
colores = {'b','r','g'};
for c = 1:3
    subplot(1,3,c);
    scatter(Y_train(:,c), Y_pred_train(:,c), 60, colores{c}, 'filled');
    hold on; plot([0 100],[0 100],'k--');
    xlabel('Real (%)'); ylabel('Predicho (%)');
    title(sprintf('%s\nR²=%.3f  RMSE=%.1f%%', nombres_comp{c}, R2_train(c), RMSE_train(c)));
    xlim([0 110]); ylim([0 110]); grid on; axis square;
end
sgtitle('Paso 9d – Ajuste del modelo PLS sobre datos de entrenamiento', 'FontSize', 12);
 
fprintf('\nModelo entrenado con éxito. BETA guardado.\n');
 
%% =========================================================
%  PASO 10: PREDICCIÓN DE LA COMPOSICIÓN (Verificacion sobre las muestras)
% =========================================================
[Nx, Ny, NL] = size(R_carne);
X_img_flat = reshape(R_carne, Nx*Ny, NL);
 
% Aplicar el modelo BETA entrenado
pred_flat = [ones(size(X_img_flat,1),1) X_img_flat] * BETA;
 
% Limpiar valores imposibles
pred_flat = max(0, min(100, pred_flat)); 
 
% Visualización de la "Muestra Desconocida" ya analizada
figure('Name','Resultado: Identificación de Composición','NumberTitle','off');
nombres = {'Mapa Novilla (%)', 'Mapa Cerdo (%)', 'Mapa Tocino (%)'};
for i = 1:3
    subplot(1,3,i);
    img_res = reshape(pred_flat(:,i), Nx, Ny);
    imagesc(img_res); axis image; colorbar; colormap(jet);
    title(nombres{i});
end
 
%% =========================================================
%  PASO 11: ANÁLISIS DE MUESTRA DESCONOCIDA – COMPOSICIÓN GLOBAL (%)
%  Mejoras: (1) alineación espectral en nm, (2) máscara de fondo,
%           (3) filtrado de píxeles anómalos
% =========================================================
fprintf('\n=== PASO 11: Analizando la Hamburguesa ===\n');
 
% ---- 11a: Cargar y corregir en reflectancia ----
data_hamb  = load('hamburguesa_p1_luz.mat');
nombres_h  = fieldnames(data_hamb);
H_raw      = double(data_hamb.(nombres_h{1}));
 
data_carne_b_h = load('carne_b.mat');
nombres_b      = fieldnames(data_carne_b_h);
W_original     = double(data_carne_b_h.(nombres_b{1}));
 
[h_rows, h_cols, h_bands] = size(H_raw);
[~,      ~,      w_bands] = size(W_original);
 
n_bands_comun = min(h_bands, w_bands);
fprintf('  Bandas hamburguesa: %d  |  Bandas blanco: %d  |  Usando: %d\n', ...
    h_bands, w_bands, n_bands_comun);
 
% Ajustar blanco espacialmente banda a banda
W_adj = zeros(h_rows, h_cols, n_bands_comun);
for b = 1:n_bands_comun
    W_adj(:,:,b) = imresize(W_original(:,:,b), [h_rows, h_cols]);
end
H_adj  = H_raw(:,:,1:n_bands_comun);
R_hamb = H_adj ./ (W_adj + eps);
R_hamb = max(0, min(1, R_hamb));
 
% =========================================================
%  MEJORA 1: Alineación espectral por interpolación en nm
% =========================================================
% El modelo se entrenó con el eje lambda_cal_carne (nm).
% La hamburguesa puede tener distinto número de bandas o distinto rango.
% Interpolamos cada píxel al eje nm del entrenamiento para garantizar
% que banda i del modelo ↔ misma longitud de onda en la hamburguesa.
fprintf('--- Mejora 1: Alineando espectros al eje nm del modelo ---\n');
 
n_bands_modelo = size(BETA, 1) - 1;
lambda_modelo  = lambda_cal_carne(1:n_bands_modelo);   % eje nm entrenamiento
lambda_hamb    = polyval(p, 1:n_bands_comun);           % eje nm hamburguesa
 
% Rango solapante entre ambos ejes
lambda_min_comun = max(lambda_modelo(1),   lambda_hamb(1));
lambda_max_comun = min(lambda_modelo(end), lambda_hamb(end));
fprintf('  Rango solapante: %.1f – %.1f nm\n', lambda_min_comun, lambda_max_comun);
 
% Índices del eje del modelo que caen dentro del rango solapante
idx_modelo_ok = lambda_modelo >= lambda_min_comun & lambda_modelo <= lambda_max_comun;
n_bands_ok    = sum(idx_modelo_ok);
fprintf('  Bandas del modelo con cobertura espectral real: %d / %d\n', ...
    n_bands_ok, n_bands_modelo);
 
if n_bands_ok < round(0.8 * n_bands_modelo)
    warning(['Solo %.0f%% de las bandas del modelo tienen cobertura en la hamburguesa. ' ...
        'Revisa la calibración del eje espectral.'], 100*n_bands_ok/n_bands_modelo);
end
 
% Interpolación píxel a píxel al eje nm del modelo
X_hamb_flat_raw = reshape(R_hamb, h_rows * h_cols, n_bands_comun);
X_hamb_interp   = zeros(h_rows * h_cols, n_bands_modelo);
for px = 1:(h_rows * h_cols)
    X_hamb_interp(px, :) = interp1(lambda_hamb, X_hamb_flat_raw(px,:), ...
        lambda_modelo, 'linear', 'extrap');
end
% Recortar a [0,1] por si la extrapolación produce valores fuera de rango
X_hamb_interp = max(0, min(1, X_hamb_interp));
fprintf('  Interpolación completada.\n');
 
% =========================================================
%  MEJORA 2: Máscara de fondo
% =========================================================
% Excluir píxeles que no son carne: fondo (muy oscuro) y saturados (muy brillantes).
% Se calcula sobre la reflectancia media espectral de cada píxel.
fprintf('--- Mejora 2: Aplicando máscara de fondo ---\n');
 
R_hamb_mean = mean(X_hamb_interp, 2);   % reflectancia media por píxel (npix x 1)
mascara_carne = R_hamb_mean > 0.05 & R_hamb_mean < 0.90;
 
n_total   = h_rows * h_cols;
n_mascara = sum(mascara_carne);
fprintf('  Píxeles totales: %d  |  Píxeles de carne (máscara): %d  (%.1f%%)\n', ...
    n_total, n_mascara, 100 * n_mascara / n_total);
 
% Mostrar imagen de la máscara para verificación visual
figure('Name','Paso 11 – Máscara de fondo','NumberTitle','off');
subplot(1,2,1);
imagesc(reshape(R_hamb_mean, h_rows, h_cols));
colormap(gray); colorbar; axis image;
title('Reflectancia media (hamburguesa)', 'FontSize', 11);
subplot(1,2,2);
imagesc(reshape(mascara_carne, h_rows, h_cols));
colormap(gray); axis image;
title(sprintf('Máscara de carne (%d píxeles)', n_mascara), 'FontSize', 11);
sgtitle('Paso 11 – Mejora 2: Máscara de fondo', 'FontSize', 12);
 
% Aplicar máscara: trabajar solo con píxeles de carne
X_hamb_masked = X_hamb_interp(mascara_carne, :);
 
% ---- Normalización SNV píxel a píxel ----
mu_h    = mean(X_hamb_masked, 2);
sigma_h = std(X_hamb_masked, 0, 2);
sigma_h(sigma_h < eps) = 1;
X_hamb_norm = (X_hamb_masked - mu_h) ./ sigma_h;
 
% ---- Predicción con el modelo PLS ----
pred_hamb_masked = [ones(size(X_hamb_norm,1),1), X_hamb_norm] * BETA;
pred_hamb_masked = max(0, min(100, pred_hamb_masked));
 
% =========================================================
%  MEJORA 3: Filtrado de píxeles anómalos
% =========================================================
% Un píxel es anómalo si la suma de sus predicciones se aleja mucho de 100%,
% lo que indica que el modelo está extrapolando (espectro fuera del espacio
% de entrenamiento: reflejos especulares, bordes, contaminación).
fprintf('--- Mejora 3: Filtrando píxeles anómalos ---\n');
 
suma_pred = sum(pred_hamb_masked, 2);   % debería ser ~100 en píxeles válidos
umbral_inf = 60;   % mínimo aceptable de suma (%)
umbral_sup = 140;  % máximo aceptable de suma (%)
pixeles_validos = suma_pred >= umbral_inf & suma_pred <= umbral_sup;
 
n_validos   = sum(pixeles_validos);
n_anomalos  = sum(~pixeles_validos);
fprintf('  Píxeles válidos:  %d  (%.1f%% de los píxeles de carne)\n', ...
    n_validos, 100 * n_validos / n_mascara);
fprintf('  Píxeles anómalos: %d  (suma predicción fuera de [%d, %d]%%)\n', ...
    n_anomalos, umbral_inf, umbral_sup);
 
% Histograma de sumas para verificación (ayuda a ajustar umbrales si fuera necesario)
figure('Name','Paso 11 – Distribución de sumas de predicción','NumberTitle','off');
histogram(suma_pred, 50, 'FaceColor', [0.3 0.6 0.9], 'EdgeColor', 'none');
hold on;
xline(umbral_inf, 'r--', 'LineWidth', 1.5, 'Label', sprintf('Umbral inf. %d%%', umbral_inf));
xline(umbral_sup, 'r--', 'LineWidth', 1.5, 'Label', sprintf('Umbral sup. %d%%', umbral_sup));
xline(100, 'k-',  'LineWidth', 2,   'Label', '100% ideal');
xlabel('Suma predicciones Novilla+Cerdo+Tocino (%)');
ylabel('Número de píxeles');
title('Paso 11 – Mejora 3: Distribución de sumas (ideal ≈ 100%)', 'FontSize', 12);
grid on;
 
% Quedarse solo con los píxeles válidos para el cálculo final
pred_final = pred_hamb_masked(pixeles_validos, :);
 
% ---- 11e: Cálculo de porcentajes globales ----
pct_mediana = median(pred_final, 1);
pct_media   = mean(pred_final,   1);
pct_std     = std(pred_final,    0, 1);
 
% Normalizar a 100%
pct_mediana_norm = 100 * pct_mediana / sum(pct_mediana);
pct_media_norm   = 100 * pct_media   / sum(pct_media);
 
% ---- 11f: Mostrar resultados en consola ----
fprintf('\n=========================================================\n');
fprintf('  COMPOSICIÓN ESTIMADA DE LA HAMBURGUESA\n');
fprintf('  (sobre %d píxeles válidos de %d totales)\n', n_validos, n_total);
fprintf('=========================================================\n');
fprintf('  %-14s  %8s  %8s  %8s\n', '', 'Novilla', 'Cerdo', 'Tocino');
fprintf('  %-14s  %7.1f%%  %7.1f%%  %7.1f%%\n', ...
    'Mediana norm.', pct_mediana_norm(1), pct_mediana_norm(2), pct_mediana_norm(3));
fprintf('  %-14s  %7.1f%%  %7.1f%%  %7.1f%%\n', ...
    'Media norm.',   pct_media_norm(1),   pct_media_norm(2),   pct_media_norm(3));
fprintf('  %-14s  ±%6.1f%%  ±%6.1f%%  ±%6.1f%%\n', ...
    'Desv. típica', pct_std(1), pct_std(2), pct_std(3));
fprintf('=========================================================\n');
