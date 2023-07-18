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
    
# Busqueda de color

Una vez suavizada nuestra imagen ahora podemos llevar a cabo nuestra busqueda de color, para hacer ello debemos considerar que si nosotros tenemos un objeto de un color rojo, para la camara no sera el mismo color rojo, para contrarestrar esto hacemos uso de la funcion roipoly, la cual al usarse nos dejara seleccionar una parte de nuestra imagen, una seccion de interes por lo que ese valor nos entregara una tupla o una lista de los valores de RGB que nos interesa.

Una vez que tenemos nuestra seleccion pasamos a usar el siguinete script

    umbral=30/255;

    %realizamos la busqueda
 
    b_r= frame(:,:,1)>ref_r-umbral & frame(:,:,1)<ref_r+umbral;
    b_g= frame(:,:,2)>ref_g-umbral & frame(:,:,2)<ref_g+umbral;
    b_b= frame(:,:,3)>ref_b-umbral & frame(:,:,3)<ref_b+umbral;
    busqueda = b_r.*b_g.*b_b;
    busqueda = medfilt2(busqueda):
    for i = 1:3
        frame_encontrado(:,:,i) = frame(:,:,i).*busqueda;
    end


El codigo anterior es uan busqueda por cada capa de color, para ello debemos revisar en un umbral de 30 pixeles tanto arriba como abajo, una por cada capa, el resultado de ella es una mascara de unos y ceros donde se tiene el objeto encontrado. La funcion medfil2 nos sirve para rellar con unos la vencidad, es decir, si tenemos un 0 rodeado de 1 este tomara el valor de 1. Lo restante es pasar la imagen por neustra mascara, esto por cada capa.

# Centroide de la imagen

Para este partado, se trabaja sobre la imgane binaria obtenida, es decir, sobre la busqueda, para entender este concepto de los centroides recomiendo ver el siguiente video:

https://youtu.be/sPGfnYuj0-Y

Una vez visto el video, se presentan las formulas, nuestro trabajo es poner esa formula de lo cual obtenemos el siguiente script:

    function momento = momentos(im,i,j)
        im = im2double(im);
        im_size=size(im);
        %im = ~im;
        momento=0;
        for x=1:im_size(2)
            for y=1:im_size(1)
                momento = momento + sum(x.^i * y.^j * im(y,x));
            end
        end
    end

# movimiento de servos
Para los servos requerimos de instalar una toolbox la cual viene siendo arduino con matlab, en esta parte se debe tener cuidado para no poner arduino con Simulink.

Para mover los sevos lo haremos por medio de un controlador PID y el cual se basa en el pasado, presente y futuro del error.

## PID

Como ya se sabe el PID es un controlador que se basa en el presente, pasado y furuto de la grafica del error, es decir, consta de tres partes, una ganancia proporcional al error actual, una ganancia que la de fuerza a una parte integral del error y por ultimo pero no menos importante una ganancia que le permite tener fuerza o no a una parte derivativa del error.

La manera en la que este controlador funciona es obtener cada una de las partes necesaria, es decir, la medida del error actual, la sumatoria de todos los errores para alimentar la integral, y por ultimo conocemos la pendiente de nuestra curva para poder obtener la derivada una vez que tenemos esto es momento de sintonizar las ganancias, para ello es necesario conocer el comportamiento de cada una de las partes de nuestro controlador, lo primero es encontrar la ganancia optima de nuestra parte proporcioanl, en base a ello ahora buscams una ganancia optima para un controlador PD reduciiendo a un 90% la ganancia proporcioanl encontrada, y finalmente una ganancia integral, cerramos el sistema, probamos y modificamos segun el comprtamiento de nuestra planta, un poco a prueba y error.

De lo anterior se obteniene el siguiente fragmento de codigo.


