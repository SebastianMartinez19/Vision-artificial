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
Una vez obtenida la imagen es necesario tratarla, en este caso nos enfocaremos en un objeto dado el color del mismo, por lo que haremos una busqueda por color, no obstante esta viene con ruido, por lo que haremos uso de la transformada de Fourirer para llevar la imagen a la frecuencia y de esta manera hacer una multiplicacion con un filtro pasa altas para suavizar la imagen, y regreserla al espacio temporal lo que es equivalente a la convolucion en el tiempo.
