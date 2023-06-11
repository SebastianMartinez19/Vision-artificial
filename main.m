clear all
close all
clc
error_y = []
error_x = []
a = arduino('COM7', 'Mega2560', 'Libraries', 'Servo');  % creamos el objeto arduino
servo_x = servo(a,'D7'); % creamos el servo x que estara en el puerto digital 7
servo_y = servo(a,'D8'); % creamos el servo y que estara en el puerto digital 8
angulo_x = 90;
angulo_y = 90;

vx_error=[];
vy_error =[];

v_iteracio = [];
iteracion = 1;

% creacion de los objetos
cam = webcam(); % damos un objeto camara
cam.Resolution='720x480';
foto_objeto = snapshot(cam); %tomamos un imagen inicial
frame_size = size(foto_objeto); %obtenemos sus medidas
videoPlayer = vision.VideoPlayer('Position',[10 30 [frame_size(2),frame_size(1)]]); %creamos un visualizador de video

% capturamos la imagen de nuestro objeto a seguir
runloop=true; %creamos un control para el primer video en la capturadel objeto
while runloop
    foto_objeto=snapshot(cam); %tomamos la foto de nuestro objeto
    step(videoPlayer,foto_objeto); % al mostramos en nuestro video
    runloop = isOpen(videoPlayer);
end

% procesamos la imagen de nuesro obejto para obtener los colores
foto_objeto = im2double(foto_objeto); % convertimos a double para poder reliazar las sumas
seleccion = roipoly(foto_objeto); % seleccionamos el color del objeto


% obtenemos las referencias en rgb
ref_r= sum(sum(foto_objeto(:,:,1).*seleccion))/sum(seleccion(:));  %obtenemos la referencia en red
ref_g= sum(sum(foto_objeto(:,:,2).*seleccion))/sum(seleccion(:)); % obtemos la referencia en green
ref_b= sum(sum(foto_objeto(:,:,3).*seleccion))/sum(seleccion(:)); % obtenemos la referencia en blue 
close all % cerramos todo
clear cam

% %% creacion de filtro pasa bajas
m = frame_size(1); %esto es y
n=frame_size(2); %esto es x
% %creamos el filtro pasa bajas para suavizar
filtro=zeros(m,n);
sigma=0.04;
for y=1:m
        dy=(y-m/2)/(m/2);
        for x=1:n
            dx=(x-n/2)/(n/2);
            dxy=sqrt(dx^2+dy^2);
            filtro(y,x)=exp(-(dxy^2)/(2*sigma^2));
        end
end

% busqueda de color
% creacion nueva de los objetos
cam2 = webcam();
cam2.Resolution = '720x480';
frame = snapshot(cam2);
frame = im2double(frame);

frame_size = size(frame);
videoPlayer = vision.VideoPlayer('Position',[10 30 [frame_size(2),frame_size(1)]]); %creamos un visualizador de video
runloop=true; %creamos un control para el primer video en la capturadel objeto

umbral=30/255;
writePosition(servo_x,angulo_x/180);
writePosition(servo_y,angulo_y/180);


% Declaramos nuestras ganancias de control
set_x = frame_size(2)/2;
set_y = frame_size(1)/2;
profundidad = frame_size(3);


kp_x = 0.33; % 0.33
kd_x = 0.0019; % 0.15
ki_x = 0.00085;  % 0.11
x_derivada = 0;
cx_anterior = set_x;
x_integral = 0;

% inicializacion de las ganancias en y
kp_y = 0.19; %0.19
ki_y = 0.00065; % 0.0006
kd_y = 0.0016;% 0.0012
y_derivada = 0;
y_integral = 0;
cy_anterior = set_y;


while runloop
    frame=snapshot(cam2); %tomamos la foto de nuestro objeto
    frame = im2double(frame); % cambiamos el frame a double para realizar los calculos
    frame=frame+.20*randn(m,n,3);
    frame2=frame;

    for z=1:profundidad
        %pasamos la imagen a la frecuencia
        frame_f(:,:,z) = fftshift(fft2(frame(:,:,z)));
        %filtramos
        frame_ff(:,:,z) = filtro.*frame_f(:,:,z);
        %regresamos al espacio
        frame(:,:,z) = ifft2(ifftshift(frame_ff(:,:,z)));
    end
    
    %realizamos la busqueda
    b_r= frame(:,:,1)>ref_r-umbral & frame(:,:,1)<ref_r+umbral;
    b_g= frame(:,:,2)>ref_g-umbral & frame(:,:,2)<ref_g+umbral;
    b_b= frame(:,:,3)>ref_b-umbral & frame(:,:,3)<ref_b+umbral;
    busqueda = b_r.*b_g.*b_b;
    busqueda = medfilt2(busqueda);

    for i = 1:3
        frame_encontrado(:,:,i) = frame(:,:,i).*busqueda;
    end

    %calculos de los momento sobre la busqueda para encontrar el centroide
    m_00 = momentos(busqueda,0,0);
    m_01 = momentos(busqueda,0,1);
    m_10 = momentos(busqueda,1,0);
    c_x=m_10/m_00;
    c_y=m_01/m_00;

    x_error = set_x - c_x;
    y_error= set_y - c_y;

    if (isnan(x_error))
        angulo_x=90;
        cx_anterior = set_x;
    else
        if (x_error <= -20) || (x_error >= 20)
            if x_error < 0 
                paso_x = -(abs(x_error)*10)/(124);
            else
                paso_x = (abs(x_error)*10)/(124);
            end
            x_integral = x_integral + paso_x;  %actualizamos la integral del error en grados 
            x_derivada = c_x - cx_anterior;  %calculamos la derivada del error
            x_derivada = x_derivada*10/124; %convertimos o normalizamos
            angulo_x = angulo_x + kp_x*paso_x + kd_x*x_derivada + ki_x*x_integral;  %calculamos la señal de control
            cx_anterior = c_x;  %actualizamos la varible
            vx_error(iteracion-1) = x_error;
        end
    end
    writePosition(servo_x,angulo_x/180); %escribimos el nuevo angulo calculado



    if (isnan(y_error))
        angulo_y =90;
        cy_anterior = set_y;
    else
        if (y_error <= -14) || (y_error >= 14 )
            if y_error < 0  
                paso_y = -((10*abs(y_error))/89);
            else
                paso_y = ((10*abs(y_error))/89);
            end
            y_integral = y_integral+paso_y;
            y_derivada = c_y - cy_anterior;  %calculamos la derivada del error
            y_derivada = y_derivada*10/89; %convertimos o normalizamos
            angulo_y = angulo_y + kp_y*paso_y + kd_y*y_derivada+ki_y*y_integral; %calculamos la señal de control
            cy_anterior = c_y;  %actualizamos la varible
            vy_error(iteracion-1) = y_error;
        end
    end
    writePosition(servo_y,angulo_y/180);
    
    v_iteracio(iteracion) = iteracion;
    iteracion = iteracion+1;
         

    step(videoPlayer,real(frame_encontrado)) % al mostramos en nuestro video
    runloop = isOpen(videoPlayer);
    if runloop == false
        clear cam2 a
    end
end
v_iteracio = 0:1:size(length(vy_error))
figure
hold on
plot(vx_error);

figure
hold on
plot(vy_error);