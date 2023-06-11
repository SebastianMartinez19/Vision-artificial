# Vision-artificial

Se plantea realizar un poryecto de vision artificial que mantenga el objeto en cuestion en el centro de la imagen.

# Obtencion de la imagen
Este proyeo sera llevado a cabo en matlab.

Al tratarse de vision artifical lo primero que debemos obtener es la imagen, o el como obtener imagenes en matlab, por lo que haremos uso del siguiente codigo base.

cam = webcam(); % damos un objeto camara

cam.Resolution='720x480';

foto_objeto = snapshot(cam); %tomamos un imagen inicial

De este modo obtenemos la imagen, para mostrarla podemos hacer uso de una de los manera

Forma 1:
While true
  imshow(cam)
end

Forma 2: (usada en este proyecto)
Consiste en crear un videoplayer, propio de matlab

frame_size = size(foto_objeto); %obtenemos sus medidas
videoPlayer = vision.VideoPlayer('Position',[10 30 [frame_size(2),frame_size(1)]]); %creamos un visualizador de video

% capturamos la imagen de nuestro objeto a seguir
runloop=true; %creamos un control para el primer video en la capturadel objeto
while runloop
    foto_objeto=snapshot(cam); %tomamos la foto de nuestro objeto
    step(videoPlayer,foto_objeto); % al mostramos en nuestro video
    runloop = isOpen(videoPlayer);
end

## Tratado de imagen
Una vez obtenida la imagen es necesario tratarla, en este caso nos enfocaremos en un objeto dado el color del mismo, por lo que haremos una busqueda por color, no obstante esta viene con ruido, por lo que haremos uso de la transformada de Fourirer para llevar la imagen a la frecuencia y de esta manera hacer una multiplicacion con un filtro pasa bajas para suavizar la imagen, y regreserla al espacio temporal lo que es equivalente a la convolucion en el tiempo.

Para poder realizar lo anterior nos guiaremos en el el siguiente script, primero generaremos el filtro pasa bajas pero no de la forma ideal, sino en forma de campana de gauss dadas las siguientes formulas

![image](https://github.com/SebastianMartinez19/Vision-artificial/assets/106949729/7d8c3973-6905-4d61-b5e5-06124b84698a)

De lo que obtenemos el siguiente script

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

Una vez que tenemos nuestro filtro, ahora si podemos proceder a suavizar nuestra imagen.

Al tratarse de una imagen en rgb, es decir, con profundidad n,m,o donde n, es el eje horizontal; m, el eje vertical; y o, los planos de cada escalar de color, r g b, por lo que nuestro filtro al tratarse de una imagen bidimensional, tenemos que aplicarlo pr medio de un ciclo for por cada una de las capas.

Para poder llevar nuestra imagen a la frecuencia pasamos por la funcion de matlab de la tranformada rapida de Fourier para imegenes de dos dimensiones en una sola capa de nuestra imagen (fft2), no obstante esta funsion nos da los armonicos desordenados, por lo que pasamos a usar la funcion de organizar la transformada rapida de Fourier (fftshift) que recibe de argumento la imagen en frecuencia, una vez ahi multiplicamos elemento a elemento la imagen obtenida en la frecuencia con nuestro filtro, una vez filtrada la capa, regresamos son fftshift y a eso aplicamos la transformada inversa rapida de Fourier para dos dimensiones (ifft2), dicho de otro modo tenemos lo siguinete.

profundidad = frame_size(3);

for z=1:profundidad

        %pasamos la imagen a la frecuencia
        
        frame_f(:,:,z) = fftshift(fft2(frame(:,:,z)));
        
        %filtramos
        
        frame_ff(:,:,z) = filtro.*frame_f(:,:,z);
        
        %regresamos al espacio
        
        frame(:,:,z) = ifft2(ifftshift(frame_ff(:,:,z)));
        
end
    
